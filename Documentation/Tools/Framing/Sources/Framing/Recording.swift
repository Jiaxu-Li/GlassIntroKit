//===--- Recording.swift - GlassIntroKit ------------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Frames from a recording, by time.
final class Recording {
    private let generator: AVAssetImageGenerator
    let duration: Double
    /// The first moment worth showing; earlier moments show this one.
    let start: Double

    init(_ url: URL, start: Double = 0) async throws {
        self.start = start
        let asset = AVURLAsset(url: url)
        generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 60)
        duration = try await asset.load(.duration).seconds
    }

    /// The frame at `time`, held at `start` before it and at the last frame
    /// past the end.
    func frame(at time: Double) async throws -> CGImage {
        let clamped = min(max(time, start), duration - 0.05)
        return try await generator.image(at: CMTime(seconds: clamped, preferredTimescale: 600)).image
    }
}

/// The Mac and the iPhone side by side, at their true relative size, on a
/// soft light canvas.
struct SideBySide {
    let mac: Bezel
    let iPhone: Bezel
    let macScreen: MacScreen
    /// The canvas's width; its height follows from the devices.
    let width: Int

    private var macScale: CGFloat {
        CGFloat(width) * 0.70 / CGFloat(mac.image.width)
    }

    /// The iPhone at the same millimetres per pixel as the Mac.
    private var iPhoneScale: CGFloat {
        macScale * CGFloat(mac.pixelsPerMillimetre / iPhone.pixelsPerMillimetre)
    }

    var height: Int {
        Int((CGFloat(mac.image.height) * macScale + CGFloat(width) * 0.08).rounded() / 2) * 2
    }

    func compose(macWindow: CGImage, iPhoneScreen: CGImage) -> CGImage {
        let context = makeContext(width: width, height: height, opaque: true)
        let colors = [CGColor(srgbRed: 0.96, green: 0.96, blue: 0.97, alpha: 1), CGColor(srgbRed: 0.88, green: 0.89, blue: 0.91, alpha: 1)] as CFArray
        context.drawLinearGradient(CGGradient(colorsSpace: nil, colors: colors, locations: [0, 1])!,
                                   start: CGPoint(x: 0, y: CGFloat(height)), end: .zero, options: [])
        let margin = CGFloat(width) * 0.04
        let macSize = CGSize(width: CGFloat(mac.image.width) * macScale, height: CGFloat(mac.image.height) * macScale)
        let phoneSize = CGSize(width: CGFloat(iPhone.image.width) * iPhoneScale, height: CGFloat(iPhone.image.height) * iPhoneScale)
        let gap = (CGFloat(width) - 2 * margin - macSize.width - phoneSize.width)
        // Both stand on the same line: the bottoms of their devices.
        let baseline = margin
        let macBottomInset = (CGFloat(mac.image.height) - mac.device.maxY) * macScale
        let phoneBottomInset = (CGFloat(iPhone.image.height) - iPhone.device.maxY) * iPhoneScale

        context.saveGState()
        context.translateBy(x: margin, y: baseline - macBottomInset)
        context.scaleBy(x: macScale, y: macScale)
        mac.draw(macScreen.compose(window: macWindow), in: context, at: .zero)
        context.restoreGState()

        context.saveGState()
        context.translateBy(x: margin + macSize.width + gap, y: baseline - phoneBottomInset)
        context.scaleBy(x: iPhoneScale, y: iPhoneScale)
        iPhone.draw(iPhoneScreen, in: context, at: .zero)
        context.restoreGState()
        return context.makeImage()!
    }
}

/// Writes frames into an H.264 movie.
final class MovieWriter {
    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let fps: Int32
    private var count: Int64 = 0

    init(url: URL, width: Int, height: Int, fps: Int32, bitrate: Int) throws {
        try? FileManager.default.removeItem(at: url)
        writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: bitrate],
        ])
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
        ])
        writer.add(input)
        writer.shouldOptimizeForNetworkUse = true
        self.fps = fps
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
    }

    func append(_ image: CGImage) async {
        while !input.isReadyForMoreMediaData {
            try? await Task.sleep(for: .milliseconds(5))
        }
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
        guard let buffer else { return }
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer), width: image.width, height: image.height, bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )!
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        adaptor.append(buffer, withPresentationTime: CMTime(value: count, timescale: fps))
        count += 1
    }

    func finish() async {
        input.markAsFinished()
        await writer.finishWriting()
        print("Wrote \(writer.outputURL.lastPathComponent), \(count) frames, status \(writer.status.rawValue)")
    }
}

/// A looping GIF of `frames`, each shown for `delay` seconds.
func writeGIF(_ frames: [CGImage], delay: Double, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames.count, nil) else {
        throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
    let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay]] as CFDictionary
    for frame in frames {
        CGImageDestinationAddImage(destination, frame, properties)
    }
    guard CGImageDestinationFinalize(destination) else {
        throw CocoaError(.fileWriteUnknown)
    }
    print("Wrote \(url.lastPathComponent), \(frames.count) frames")
}

func scaled(_ image: CGImage, width: Int) -> CGImage {
    let height = Int((Double(image.height) * Double(width) / Double(image.width)).rounded())
    let context = makeContext(width: width, height: height)
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return context.makeImage()!
}
