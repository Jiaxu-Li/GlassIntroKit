//===--- SymbolOutlines.swift - GlassIntroKit -------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

/// SF Symbols as outlines, so glass can take their shape and flow together
/// with the glass around them. SwiftUI draws symbols but does not hand out
/// their paths, so each symbol is drawn once into a coverage mask and the
/// mask's edge is traced.
@MainActor
enum SymbolOutlines {
    /// The traced outlines of `names`, each fitted to a unit square centered
    /// on the origin. Drawing happens here, on the main actor; tracing runs
    /// off it.
    static func outlines(for names: [String]) async -> [String: Path] {
        var masks: [(String, CoverageMask)] = []
        for name in names {
            if let mask = coverage(of: name) {
                masks.append((name, mask))
            }
        }
        return await Task.detached(priority: .userInitiated) {
            var result: [String: Path] = [:]
            for (name, mask) in masks {
                result[name] = SymbolTracer.outline(of: mask)
            }
            return result
        }.value
    }

    private static func coverage(of name: String) -> CoverageMask? {
        let renderer = ImageRenderer(
            content: Image(systemName: name)
                .font(.system(size: 150))
                .foregroundStyle(Color.black)
                .padding(4)
        )
        renderer.scale = 2
        guard let image = renderer.cgImage else {
            return nil
        }
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
            ) else {
                return false
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? CoverageMask(width: width, height: height, values: pixels) : nil
    }
}

/// A symbol's coverage, one byte a pixel, top row first.
nonisolated struct CoverageMask: Sendable {
    let width: Int
    let height: Int
    let values: [UInt8]
}

/// Traces a coverage mask's edge with marching squares, placing each edge
/// point where coverage crosses one half, so the outline keeps the symbol's
/// anti-aliased curves rather than its pixel steps.
nonisolated enum SymbolTracer {
    static func outline(of mask: CoverageMask) -> Path? {
        // A clear border, so every contour closes inside the grid.
        let width = mask.width + 2
        let height = mask.height + 2
        var values = [Float](repeating: 0, count: width * height)
        for y in 0..<mask.height {
            for x in 0..<mask.width {
                values[(y + 1) * width + x + 1] = Float(mask.values[y * mask.width + x]) / 255
            }
        }
        let threshold: Float = 0.5

        func value(_ x: Int, _ y: Int) -> Float {
            values[y * width + x]
        }
        // Edge ids: the horizontal edge from (x, y) to (x + 1, y) is even,
        // the vertical edge from (x, y) to (x, y + 1) is odd.
        func horizontal(_ x: Int, _ y: Int) -> Int { (y * width + x) * 2 }
        func vertical(_ x: Int, _ y: Int) -> Int { (y * width + x) * 2 + 1 }

        func point(of edge: Int) -> CGPoint {
            let cell = edge / 2
            let x = cell % width
            let y = cell / width
            let start = value(x, y)
            let end = edge.isMultiple(of: 2) ? value(x + 1, y) : value(x, y + 1)
            let span = end - start
            let t = abs(span) > 1e-6 ? min(max((threshold - start) / span, 0), 1) : 0.5
            return edge.isMultiple(of: 2)
                ? CGPoint(x: CGFloat(x) + CGFloat(t), y: CGFloat(y))
                : CGPoint(x: CGFloat(x), y: CGFloat(y) + CGFloat(t))
        }

        var neighbours: [Int: [Int]] = [:]
        func link(_ a: Int, _ b: Int) {
            neighbours[a, default: []].append(b)
            neighbours[b, default: []].append(a)
        }

        for y in 0..<(height - 1) {
            for x in 0..<(width - 1) {
                let topLeft = value(x, y) > threshold
                let topRight = value(x + 1, y) > threshold
                let bottomRight = value(x + 1, y + 1) > threshold
                let bottomLeft = value(x, y + 1) > threshold
                let index = (topLeft ? 1 : 0) | (topRight ? 2 : 0) | (bottomRight ? 4 : 0) | (bottomLeft ? 8 : 0)
                let top = horizontal(x, y)
                let bottom = horizontal(x, y + 1)
                let left = vertical(x, y)
                let right = vertical(x + 1, y)
                let centerInside = (value(x, y) + value(x + 1, y) + value(x + 1, y + 1) + value(x, y + 1)) / 4 > threshold
                switch index {
                case 1, 14: link(left, top)
                case 2, 13: link(top, right)
                case 3, 12: link(left, right)
                case 4, 11: link(right, bottom)
                case 6, 9: link(top, bottom)
                case 7, 8: link(left, bottom)
                case 5:
                    if centerInside {
                        link(top, right)
                        link(bottom, left)
                    } else {
                        link(left, top)
                        link(right, bottom)
                    }
                case 10:
                    if centerInside {
                        link(left, top)
                        link(right, bottom)
                    } else {
                        link(top, right)
                        link(bottom, left)
                    }
                default:
                    break
                }
            }
        }

        var path = Path()
        var visited = Set<Int>()
        // In a fixed order: a dictionary's order changes from launch to
        // launch, and the outline must not.
        for start in neighbours.keys.sorted() where !visited.contains(start) {
            var loop: [CGPoint] = []
            var previous = -1
            var current = start
            while !visited.contains(current) {
                visited.insert(current)
                loop.append(point(of: current))
                guard let next = neighbours[current]?.first(where: { $0 != previous && !visited.contains($0) })
                    ?? neighbours[current]?.first(where: { $0 != previous }) else {
                    break
                }
                previous = current
                current = next
            }
            guard loop.count >= 3 else {
                continue
            }
            path.move(to: loop[0])
            for point in loop.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }

        let bounds = path.boundingRect
        let side = max(bounds.width, bounds.height)
        guard side > 0 else {
            return nil
        }
        // Holes are found by the even-odd rule, then resolved so the outline
        // fills correctly by any rule.
        return path
            .applying(
                CGAffineTransform(scaleX: 1 / side, y: 1 / side)
                    .translatedBy(x: -bounds.midX, y: -bounds.midY)
            )
            .normalized(eoFill: true)
    }
}

/// Glass in a traced symbol's shape, fitted to its frame; a small circle
/// until the outline is ready.
nonisolated struct SymbolGlassShape: Shape {
    let outline: Path?

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        guard let outline else {
            let diameter = side * 0.5
            return Path(ellipseIn: CGRect(
                x: rect.midX - diameter / 2,
                y: rect.midY - diameter / 2,
                width: diameter,
                height: diameter
            ))
        }
        return outline.applying(
            CGAffineTransform(translationX: rect.midX, y: rect.midY)
                .scaledBy(x: side, y: side)
        )
    }
}
