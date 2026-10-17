//===--- GraphMotion+Frame.swift - GlassIntroKit ----------------------------===//
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

nonisolated extension GraphMotion {
    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        let time = max(time, 0)
        let graph = reveal.frame(at: time)
        var frame = IntroFrame()

        // The lens, wires, beads, and nodes are one piece of glass, so a bead
        // swells into its node and a wire runs out of the point as liquid.
        var glass = GlassFrame()
        glass.orbDiameter = graph.orbDiameter
        glass.orbCenter = reveal.center
        glass.wires = graph.wires
        glass.beads = graph.beads
        glass.beadDiameters = graph.beadDiameters
        glass.nodes = graph.nodes.map { ($0.rect, $0.cornerRadius) }
        let canvas = context.canvas
        let outline = glass.path(
            layout: HelloLayout.resting(in: canvas),
            markDimension: canvas.markDimension,
            context: context
        )
        if !outline.isEmpty {
            frame.glass = [GlassPiece(id: "main", path: outline)]
        }

        // The lens's glass comes back in while its rim is still past the
        // canvas's edges.
        if heldPose != nil {
            frame.glassOpacity = Ease.easeOut(time / GraphReveal.glassInDuration)
        }

        frame.symbols = graph.nodes.map { node in
            SymbolSprite(
                id: "node-\(node.id)",
                name: node.symbol,
                center: CGPoint(x: node.rect.midX, y: node.rect.midY),
                size: node.symbolSize,
                scale: node.symbolScale,
                opacity: node.symbolOpacity
            )
        }
        frame.scene = scene(for: graph)
        return frame
    }

    /// The scene held still behind the closing lens, which at the start is
    /// wide enough to show the whole canvas, as the scene page leaves it.
    private func scene(for graph: GraphFrame) -> SceneSprite? {
        guard let pose = heldPose, let lens = graph.lensDiameter, graph.sceneOpacity > 0 else {
            return nil
        }
        var sprite = SceneSprite(
            lensDiameter: lens,
            lensCenter: reveal.center,
            cubeCenter: cubeCenter,
            level: Float(SceneReveal.finalLevel),
            sweep: 2,
            yaw: pose.yaw,
            opacity: graph.sceneOpacity,
            look: heldLook
        )
        sprite.pose = pose
        return sprite
    }
}
