//===--- GlassFrame.swift - GlassIntroKit -----------------------------------===//
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

/// The glass the first pictures share, as one outline: a stretch of the
/// word, the mark growing from a point and melting into its center symbol,
/// the lens, and the graph's wires, beads, and nodes. Drawn as one piece so
/// whatever overlaps reads as a single piece of glass.
nonisolated struct GlassFrame {
    /// The stretch of the word still shown, as progress through the writing.
    var from: Double = 0
    var through: Double = 0
    /// How far the view has travelled after the word.
    var travel: CGSize = .zero
    /// The mark's outline: where it is, how far it has grown from the pen's
    /// point to the full body, and how far its detail has opened.
    var markCenter: CGPoint?
    var markGrowth: Double = 0
    var apertureOpening: Double = 0
    /// How far the mark has melted into its center symbol, and that
    /// symbol's size.
    var morph: Double = 0
    var centerScale: CGFloat = 1
    /// The lens that opens over the scene, centered where the mark is, or
    /// at `orbCenter` once the symbol has gone.
    var orbDiameter: CGFloat = 0
    var orbCenter: CGPoint?
    /// The graph page's wires and the beads on them.
    var wires: [Path] = []
    var beads: [CGPoint] = []
    /// Each bead's diameter; a bead past the end of this list is full size.
    var beadDiameters: [CGFloat] = []
    /// The graph page's nodes, in the same glass as the wires and beads so
    /// a bead swells into its node as one piece.
    var nodes: [(rect: CGRect, cornerRadius: CGFloat)] = []

    static func written(through progress: Double) -> GlassFrame {
        GlassFrame(through: progress)
    }
}

nonisolated extension GlassFrame {
    /// The outline, with the word laid out by `layout` and the mark in a
    /// square of `markDimension`.
    func path(layout: HelloLayout, markDimension: CGFloat, context: IntroContext) -> Path {
        let frame = self
        let markOutline = context.markOutline
        let markSymbolOutline = context.markSymbolOutline
        let centerGlyph = context.centerGlyph
        var path = Path()
        if frame.through > frame.from {
            path = layout.centerline(from: frame.from, through: frame.through)
                .strokedPath(StrokeStyle(
                    lineWidth: layout.lineWidth(at: frame.through),
                    lineCap: .round,
                    lineJoin: .round
                ))
                .applying(CGAffineTransform(translationX: frame.travel.width, y: frame.travel.height))
        }
        if let center = frame.markCenter {
            let full = markDimension * markOutline.bodyDiameterRatio
            let point = layout.lineWidth(at: 1)
            let diameter = point + (full - point) * frame.markGrowth
            let scale = max(diameter / full, 0.001)
            let side = markDimension
            // The mark draws in and its detail closes as the center symbol
            // swells out of it; both are one piece of glass while they
            // overlap.
            let morph = centerGlyph == nil ? 0 : frame.morph
            let shrink = Ease.smoother(morph / 0.75)
            let grow = Ease.smoother((morph - 0.2) / 0.8)
            var outline = Path()
            if morph < 1 {
                let markScale = centerGlyph == nil
                    ? scale * frame.centerScale
                    : scale * (1 - 0.6 * shrink)
                outline = markOutline
                    .path(
                        in: CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side),
                        apertureOpening: frame.apertureOpening * (1 - shrink),
                        symbolOutline: markSymbolOutline
                    )
                    .applying(
                        CGAffineTransform(translationX: center.x, y: center.y)
                            .scaledBy(x: markScale, y: markScale)
                            .translatedBy(x: -center.x, y: -center.y)
                    )
            }
            if morph > 0.2, let centerGlyph {
                let glyph = centerGlyph.path(
                    centeredAt: center,
                    side: full * 0.92 * frame.centerScale * (0.35 + 0.65 * grow)
                )
                outline = outline.isEmpty ? glyph : outline.union(glyph)
            }
            path = path.isEmpty ? outline : path.union(outline)
        }
        if frame.orbDiameter > 0.5, let center = frame.markCenter ?? frame.orbCenter {
            let radius = frame.orbDiameter / 2
            let orb = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: frame.orbDiameter,
                height: frame.orbDiameter
            ))
            path = path.isEmpty ? orb : path.union(orb)
        }
        for wire in frame.wires {
            let stroke = wire.strokedPath(StrokeStyle(lineWidth: GraphReveal.wireWidth, lineCap: .round))
            path = path.isEmpty ? stroke : path.union(stroke)
        }
        for (index, bead) in frame.beads.enumerated() {
            let diameter = index < frame.beadDiameters.count ? frame.beadDiameters[index] : GraphReveal.beadDiameter
            guard diameter > 0.1 else {
                continue
            }
            let radius = diameter / 2
            let dot = Path(ellipseIn: CGRect(
                x: bead.x - radius,
                y: bead.y - radius,
                width: diameter,
                height: diameter
            ))
            path = path.isEmpty ? dot : path.union(dot)
        }
        for node in frame.nodes {
            let tile = Path(roundedRect: node.rect, cornerRadius: node.cornerRadius, style: .continuous)
            path = path.isEmpty ? tile : path.union(tile)
        }
        return path.normalized(eoFill: false)
    }

}
