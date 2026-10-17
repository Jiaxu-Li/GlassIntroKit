//===--- FrameRaster.swift - GlassIntroKit ----------------------------------===//
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
import Synchronization
import SwiftUI
@testable import GlassIntroKit

/// A frame drawn as coverage in a small 16-bit grey image (fine enough that
/// a large area fading evenly never steps all at once): every piece of glass,
/// symbol, line, lens, card, and mark, weighted by its opacity. Comparing
/// two rasters says how much of the picture changed, whatever the pieces
/// are called.
nonisolated struct FrameRaster: Sendable {
    static let width = 160

    let values: [UInt16]


    init(_ frame: IntroFrame, canvas: IntroCanvas) {
        let width = Self.width
        let height = max(Int((CGFloat(width) * canvas.size.height / canvas.size.width).rounded()), 1)
        let scale = CGFloat(width) / canvas.size.width
        var pixels = [UInt16](repeating: 0, count: width * height)
        // CoreGraphics draws wrongly now and then when many bitmaps are drawn
        // at once on different threads, so frames are drawn one at a time;
        // frames themselves are still computed in parallel.
        rasterLock.withLock { _ in pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 16,
                bytesPerRow: width * 2,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
            ) else {
                return
            }
            // Canvas coordinates, y down.
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: scale, y: -scale)
            context.setBlendMode(.lighten)
            func fill(_ path: Path, _ opacity: Double) {
                // Even the faintest coverage counts: a whole canvas at a
                // thousandth of its opacity is a visible share of a frame.
                guard opacity > 0, !path.isEmpty else {
                    return
                }
                context.setFillColor(gray: CGFloat(min(max(opacity, 0), 1)), alpha: 1)
                context.addPath(path.cgPath)
                context.fillPath()
            }
            if let scene = frame.scene {
                if let lens = scene.lensDiameter {
                    fill(Path(ellipseIn: CGRect(
                        x: scene.lensCenter.x - lens / 2,
                        y: scene.lensCenter.y - lens / 2,
                        width: lens,
                        height: lens
                    )), scene.opacity)
                } else {
                    // Past every edge, as a covering lens would be.
                    fill(Path(CGRect(origin: .zero, size: canvas.size).insetBy(dx: -40, dy: -40)), scene.opacity)
                }
            }
            for piece in frame.glass {
                fill(piece.path, piece.opacity * frame.glassOpacity)
            }
            for piece in frame.looseGlass {
                fill(piece.path, piece.opacity)
            }
            for line in frame.lines {
                fill(Path(CGRect(
                    x: line.center.x - line.width / 2,
                    y: line.center.y - 2,
                    width: max(line.width, 0),
                    height: 4
                )), line.opacity)
            }
            for symbol in frame.symbols {
                let side = symbol.size * symbol.scale
                fill(Path(CGRect(x: symbol.center.x - side / 2, y: symbol.center.y - side / 2, width: side, height: side)), symbol.opacity)
            }
            if let card = frame.card {
                fill(Path(card.rect), card.contentOpacity)
            }
            if let mark = frame.mark {
                let opacity = mark.colour.map { $0 > 0 ? mark.opacity : 0 } ?? mark.opacity
                let side = canvas.bodyDiameter * mark.scale
                fill(Path(ellipseIn: CGRect(x: mark.center.x - side / 2, y: mark.center.y - side / 2, width: side, height: side)), opacity)
            }
        } }
        values = pixels
    }

    /// The share of the picture that differs from `other`.
    func difference(from other: FrameRaster) -> Double {
        var total = 0
        values.withUnsafeBufferPointer { mine in
            other.values.withUnsafeBufferPointer { theirs in
                for index in 0..<min(mine.count, theirs.count) {
                    total += abs(Int(mine[index]) - Int(theirs[index]))
                }
            }
        }
        return Double(total) / Double(values.count * 65535)
    }
}

/// Something wrong with a frame: a value that is not a number, or a jump.
nonisolated struct FrameFault: CustomStringConvertible, Sendable {
    let time: Double
    let detail: String

    var description: String {
        String(format: "%.4fs: %@", time, detail)
    }
}

/// Finds jumps: moments where the picture changes all at once rather than
/// over time. Over a short enough interval, a smooth movement changes the
/// picture by about as much in each half; a jump adds a change to one half
/// that no shortening of the interval removes.
nonisolated struct ContinuityCheck: Sendable {
    /// The smallest jump worth reporting, as a share of the picture: about
    /// a 30-point symbol appearing at once on a wide canvas.
    var floor = 0.0004
    /// How many times an interval is halved in search of a jump.
    var depth = 12

    let canvas: IntroCanvas
    let frame: @Sendable (Double) -> IntroFrame

    func raster(at time: Double) -> FrameRaster {
        FrameRaster(frame(time), canvas: canvas)
    }

    /// Every jump between `start` and `end`, looked for in steps of `step`.
    func jumps(from start: Double, to end: Double, step: Double = 1.0 / 120) -> [FrameFault] {
        var faults: [FrameFault] = []
        var time = start
        var previous = raster(at: time)
        while time < end {
            let next = min(time + step, end)
            let last = raster(at: next)
            if let jump = locate(from: time, to: next, startRaster: previous, endRaster: last, depth: depth) {
                faults.append(jump)
            }
            previous = last
            time = next
        }
        return faults
    }

    /// Every frame between `start` and `end` whose outlines are not finite.
    func invalidFrames(from start: Double, to end: Double, step: Double = 1.0 / 60) -> [FrameFault] {
        var faults: [FrameFault] = []
        var time = start
        while time <= end {
            let frame = frame(time)
            let rects = (frame.glass + frame.looseGlass).map(\.path.boundingRect)
                + frame.symbols.map { CGRect(origin: $0.center, size: CGSize(width: $0.size, height: $0.size)) }
            for rect in rects where !rect.isNull && !(rect.minX.isFinite && rect.minY.isFinite && rect.width.isFinite && rect.height.isFinite) {
                faults.append(FrameFault(time: time, detail: "an outline is not finite"))
            }
            if let mark = frame.mark, !(mark.center.x.isFinite && mark.center.y.isFinite && mark.scale.isFinite) {
                faults.append(FrameFault(time: time, detail: "the mark is not finite"))
            }
            time += step
        }
        return faults
    }

    /// Halves the interval toward the half that changes more than the
    /// other, for as long as the difference stays above the floor.
    private func locate(
        from start: Double,
        to end: Double,
        startRaster: FrameRaster,
        endRaster: FrameRaster,
        depth: Int
    ) -> FrameFault? {
        let middle = (start + end) / 2
        let middleRaster = raster(at: middle)
        let first = startRaster.difference(from: middleRaster)
        let second = middleRaster.difference(from: endRaster)
        let excess = abs(first - second)
        guard excess > floor else {
            return nil
        }
        guard depth > 0 else {
            return FrameFault(time: start, detail: String(format: "%.2f%% of the picture changes at once", excess * 100))
        }
        return first > second
            ? locate(from: start, to: middle, startRaster: startRaster, endRaster: middleRaster, depth: depth - 1)
            : locate(from: middle, to: end, startRaster: middleRaster, endRaster: endRaster, depth: depth - 1)
    }

    /// Every fault between `start` and `end`, looked for off the main actor
    /// so that many checks run at once.
    @concurrent
    func faults(from start: Double, to end: Double) async -> [FrameFault] {
        invalidFrames(from: start, to: end) + jumps(from: start, to: end)
    }
}

/// Draws one frame at a time.
nonisolated private let rasterLock = Mutex(0)
