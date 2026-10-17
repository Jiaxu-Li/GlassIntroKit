//===--- Bezel.swift - GlassIntroKit ----------------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// An Apple product bezel: its image, the screen inside it, and the
/// device's real size, so devices shown together keep their true scale.
struct Bezel {
    let image: CGImage
    /// The screen, in the bezel image's pixels, from the top left.
    let screen: CGRect
    /// The radius of each of the screen's corners, in pixels: top left, top
    /// right, bottom right, bottom left.
    let cornerRadii: [CGFloat]
    /// The device's outline inside the image.
    let device: CGRect
    /// Pixels in the image for each millimetre of the real device.
    let pixelsPerMillimetre: Double

    /// iPhone 18 Pro, portrait, about 150 mm tall.
    static func iPhone(in folder: URL) throws -> Bezel {
        try Bezel(file: folder.appendingPathComponent("iPhone 18 Pro - Black - Portrait.png"), heightMillimetres: 150.0)
    }

    /// MacBook Pro (M5), 14-inch, open, seen straight on: 312.6 mm wide.
    static func macBookPro(in folder: URL) throws -> Bezel {
        try Bezel(file: folder.appendingPathComponent("MacBook Pro M5 14-inch Space Black.png"), widthMillimetres: 312.6)
    }

    /// A bezel whose device is `heightMillimetres` tall or
    /// `widthMillimetres` wide in life.
    init(file: URL, heightMillimetres: Double? = nil, widthMillimetres: Double? = nil) throws {
        image = try loadImage(file)
        let pixels = rgbaPixels(image)
        let width = image.width, height = image.height
        func alpha(_ x: Int, _ y: Int) -> UInt8 { pixels[(y * width + x) * 4 + 3] }
        // The screen is the clear hole around the middle: measure it along a
        // line clear of the camera housing at the top.
        let probeY = height * 45 / 100, probeX = width / 4
        var left = width / 2, right = width / 2, top = probeY, bottom = probeY
        while left > 0, alpha(left - 1, probeY) < 10 { left -= 1 }
        while right < width - 1, alpha(right + 1, probeY) < 10 { right += 1 }
        while top > 0, alpha(probeX, top - 1) < 10 { top -= 1 }
        while bottom < height - 1, alpha(probeX, bottom + 1) < 10 { bottom += 1 }
        screen = CGRect(x: left, y: top, width: right - left + 1, height: bottom - top + 1)
        // Each corner's radius. Walk in from the corner of the hole's bounds
        // along the diagonal: past any clear pixels outside the device, then
        // across the bezel to the screen. The content is clipped halfway
        // across the bezel, so the bezel hides its edge and no gap shows. A
        // circular corner of radius r leaves r(1 - 1/√2) on the diagonal.
        let corners = [(left, top, 1, 1), (right, top, -1, 1), (right, bottom, -1, -1), (left, bottom, 1, -1)]
        cornerRadii = corners.map { x, y, dx, dy in
            func clear(_ step: Int) -> Bool { alpha(x + step * dx, y + step * dy) < 10 }
            var step = 0
            while step < 400, clear(step) { step += 1 }
            guard step < 400 else { return 0 }  // Square: the screen reaches the corner.
            let bezelStart = step
            while step < 400, !clear(step) { step += 1 }
            let inset = CGFloat(bezelStart + step) / 2
            return inset / (1 - 1 / 2.0.squareRoot())
        }
        // The device is everything opaque.
        var minX = width, maxX = 0, minY = height, maxY = 0
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) where alpha(x, y) > 200 {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        device = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        if let heightMillimetres {
            pixelsPerMillimetre = device.height / heightMillimetres
        } else {
            pixelsPerMillimetre = device.width / (widthMillimetres ?? device.width)
        }
    }

    /// The bezel with `content` filling its screen, at `scale` of the bezel
    /// image's size. The bezel is drawn as it is, over the content.
    func framing(_ content: CGImage, scale: CGFloat = 1) -> CGImage {
        let width = Int(CGFloat(image.width) * scale), height = Int(CGFloat(image.height) * scale)
        let context = makeContext(width: width, height: height)
        context.scaleBy(x: scale, y: scale)
        draw(content, in: context, at: .zero)
        return context.makeImage()!
    }

    /// Draws the framed device into `context`, its top left at `origin`, in
    /// the context's current units of bezel pixels.
    func draw(_ content: CGImage, in context: CGContext, at origin: CGPoint) {
        let height = CGFloat(image.height)
        let screenRect = CGRect(
            x: origin.x + screen.minX,
            y: origin.y + height - screen.maxY,
            width: screen.width,
            height: screen.height
        )
        context.saveGState()
        context.addPath(screenOutline(in: screenRect))
        context.clip()
        context.interpolationQuality = .high
        context.draw(content, in: screenRect)
        context.restoreGState()
        context.draw(image, in: CGRect(x: origin.x, y: origin.y, width: CGFloat(image.width), height: height))
    }

    /// The screen hole's shape, its corners rounded as the bezel's are, in a
    /// context whose y axis points up.
    private func screenOutline(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        // Radii top left, top right, bottom right, bottom left; y points up.
        let r = cornerRadii.map { min($0, rect.width / 2, rect.height / 2) }
        path.move(to: CGPoint(x: rect.minX + r[0], y: rect.maxY))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY), radius: r[1])
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: r[2])
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: r[3])
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: r[0])
        path.closeSubpath()
        return path
    }
}

func loadImage(_ url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw CocoaError(.fileReadCorruptFile, userInfo: [NSFilePathErrorKey: url.path])
    }
    return image
}

func writeImage(_ image: CGImage, to url: URL, jpeg: Bool = false) throws {
    let type = jpeg ? UTType.jpeg : UTType.png
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil) else {
        throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(destination, image, jpeg ? [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary : nil)
    guard CGImageDestinationFinalize(destination) else {
        throw CocoaError(.fileWriteUnknown)
    }
    print("Wrote \(url.lastPathComponent), \(image.width)×\(image.height)")
}

func makeContext(width: Int, height: Int, opaque: Bool = false) -> CGContext {
    CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: (opaque ? CGImageAlphaInfo.noneSkipFirst : CGImageAlphaInfo.premultipliedFirst).rawValue
            | CGBitmapInfo.byteOrder32Little.rawValue
    )!
}

func rgbaPixels(_ image: CGImage) -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
    let context = CGContext(
        data: &pixels, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    // A bitmap context's memory starts at its top row, so row 0 is the
    // image's top row.
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return pixels
}
