//===--- SceneMotion+Glass.swift - GlassIntroKit ----------------------------===//
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

/// The scene page's glass: the symbols gathering into the center symbol and
/// melting into the lens, then the sweep line.
nonisolated extension SceneMotion {
    /// The width of the sweep line's glass.
    static let sweepWidth: CGFloat = 10

    /// Every piece of glass at `time` on the reveal's own timeline, with the
    /// sweep line at `sweep` of the canvas's width.
    func glass(at time: Double, sweep: Float) -> [GlassPiece] {
        var pieces: [GlassPiece] = []
        let main = lensGlass(at: time)
        if !main.isEmpty {
            pieces.append(GlassPiece(id: "main", path: main))
        }
        if let gathering, time < SceneReveal.orbStart {
            pieces.append(contentsOf: bubbles(of: gathering, at: time))
        }
        if sweep < 1.5 {
            pieces.append(sweepGlass(at: sweep))
        }
        return pieces
    }

    /// The center symbol that is left, and the lens swelling out of it or,
    /// from the seed, out of the drop.
    private func lensGlass(at time: Double) -> Path {
        let canvas = context.canvas
        var glass = GlassFrame()
        glass.orbCenter = reveal.center
        glass.orbDiameter = reveal.orbDiameter(at: time, from: gathering == nil ? canvas.seed.diameter : 0)
        var pageContext = context
        if let gathering {
            pageContext = gathering.context
            let native = reveal.nativeTime(at: time)
            let remaining = reveal.centerRemaining(at: time)
            if remaining >= 0.01 {
                glass.markCenter = canvas.graphicCenter
                glass.markGrowth = 1
                glass.apertureOpening = 1
                glass.morph = gathering.scatter.morph(at: native)
                glass.centerScale = gathering.scatter.centerScale(at: native) * remaining
            }
        }
        // Nothing left to draw once the lens has opened past the canvas.
        guard glass.markCenter != nil || glass.orbDiameter > 0.5 else {
            return Path()
        }
        return glass.path(layout: layout, markDimension: canvas.markDimension, context: pageContext)
    }

    /// The symbols, still gathering until the lens takes the center
    /// symbol's place; they shrink away into it just before.
    private func bubbles(of gathering: Gathering, at time: Double) -> [GlassPiece] {
        let native = reveal.nativeTime(at: time)
        let shrink = 1 - Ease.smoother((time - (SceneReveal.orbStart - 0.15)) / 0.15)
        return gathering.scatter.bubbles(at: native).compactMap { bubble in
            var bubble = bubble
            bubble.diameter *= CGFloat(shrink)
            guard bubble.diameter > 0.5 else {
                return nil
            }
            return bubble.glassPiece(outline: context.outlines[bubble.symbol])
        }
    }

    /// The line that raises the scene a level as it passes.
    private func sweepGlass(at sweep: Float) -> GlassPiece {
        let size = context.canvas.size
        let x = CGFloat(sweep) * size.width
        let rect = CGRect(
            x: x - Self.sweepWidth / 2,
            y: -20,
            width: Self.sweepWidth,
            height: size.height + 40
        )
        return GlassPiece(id: "sweep", path: Capsule().path(in: rect))
    }
}
