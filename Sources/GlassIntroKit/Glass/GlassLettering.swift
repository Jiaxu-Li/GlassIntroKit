//===--- GlassLettering.swift - GlassIntroKit -------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import CoreText
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Words as outlines, so glass can take their shape.
nonisolated enum GlassLettering {
    /// `string` set in the rounded system font, light, at `size`, centered
    /// on the origin, y down.
    static func path(for string: String, size: CGFloat) -> Path {
        let font = roundedLightFont(size: size)
        let line = CTLineCreateWithAttributedString(NSAttributedString(
            string: string,
            attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
        ))
        let outline = CGMutablePath()
        let runs = CTLineGetGlyphRuns(line) as? [CTRun] ?? []
        for run in runs {
            let attributes = CTRunGetAttributes(run) as NSDictionary
            let runFont = attributes[kCTFontAttributeName as String].map { $0 as! CTFont } ?? font
            let count = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)
            for index in 0..<count {
                guard let glyph = CTFontCreatePathForGlyph(runFont, glyphs[index], nil) else {
                    continue
                }
                outline.addPath(glyph, transform: CGAffineTransform(
                    translationX: positions[index].x,
                    y: positions[index].y
                ))
            }
        }
        let bounds = outline.boundingBoxOfPath
        // Core Text draws with y up.
        return Path(outline).applying(
            CGAffineTransform(scaleX: 1, y: -1)
                .translatedBy(x: -bounds.midX, y: -bounds.midY)
        )
    }
}

nonisolated extension GlassLettering {
    /// SF Pro Rounded at a light weight: thin strokes with soft ends.
    static func roundedLightFont(size: CGFloat) -> CTFont {
        #if canImport(UIKit)
        let base = UIFont.systemFont(ofSize: size, weight: .light)
        let rounded = base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) }
        return (rounded ?? base) as CTFont
        #elseif canImport(AppKit)
        let base = NSFont.systemFont(ofSize: size, weight: .light)
        let rounded = base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: size) }
        return (rounded ?? base) as CTFont
        #else
        return CTFontCreateUIFontForLanguage(.system, size, nil)
            ?? CTFontCreateWithName("Helvetica" as CFString, size, nil)
        #endif
    }

    /// `path`, lying flat in a plane facing the viewer, turned in three
    /// dimensions about its center, pushed back by `depth`, and seen in
    /// perspective from `distance` in front, its center landing on
    /// `position`. Every point, curve controls included, is projected, so
    /// the near side grows and the far side shrinks as a real turn would.
    static func project(
        _ path: Path,
        turnX: Double,
        turnY: Double,
        roll: Double,
        depth: Double,
        distance: Double,
        position: CGPoint
    ) -> Path {
        let (sx, cx) = (sin(turnX), cos(turnX))
        let (sy, cy) = (sin(turnY), cos(turnY))
        let (sz, cz) = (sin(roll), cos(roll))
        func map(_ point: CGPoint) -> CGPoint {
            var x = Double(point.x)
            var y = Double(point.y)
            var z = 0.0
            // In the plane, then about the vertical axis, then about the
            // horizontal.
            (x, y) = (x * cz - y * sz, x * sz + y * cz)
            (x, z) = (x * cy + z * sy, -x * sy + z * cy)
            (y, z) = (y * cx - z * sx, y * sx + z * cx)
            let w = distance / max(distance + z + depth, 1)
            return CGPoint(x: position.x + CGFloat(x * w), y: position.y + CGFloat(y * w))
        }
        var result = Path()
        path.forEach { element in
            switch element {
            case .move(let to):
                result.move(to: map(to))
            case .line(let to):
                result.addLine(to: map(to))
            case .quadCurve(let to, let control):
                result.addQuadCurve(to: map(to), control: map(control))
            case .curve(let to, let control1, let control2):
                result.addCurve(to: map(to), control1: map(control1), control2: map(control2))
            case .closeSubpath:
                result.closeSubpath()
            }
        }
        return result
    }
}
