//===--- PhysicsMotion+Frame.swift - GlassIntroKit --------------------------===//
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

/// How the physics page's two movements are drawn.
nonisolated extension PhysicsMotion {
    /// The nodes swelling out of the seed, in the shared glass.
    func grownFrame(_ growth: PhysicsGrowth, at time: Double) -> IntroFrame {
        var frame = IntroFrame()
        let remaining = growth.seedScale(at: time)
        if remaining > 0.002 {
            frame.glass.append(growth.seed.piece(scale: remaining))
        }
        for node in growth.nodes(at: time) where node.isVisible {
            frame.glass.append(GlassPiece(
                id: Self.nodeID(node.id),
                path: Path(roundedRect: node.rect, cornerRadius: node.cornerRadius, style: .continuous)
            ))
            frame.symbols.append(SymbolSprite(
                id: Self.symbolID(node.id),
                name: node.symbol,
                center: CGPoint(x: node.rect.midX, y: node.rect.midY),
                size: node.symbolSize,
                scale: node.symbolScale,
                opacity: node.symbolOpacity
            ))
        }
        return frame
    }

    /// The nodes falling: each its own piece of glass, never merging, and
    /// the wires and beads drawing back in the shared glass.
    func fallingFrame(_ physics: PhysicsFrame) -> IntroFrame {
        var frame = IntroFrame()
        if let wires = wireGlass(physics) {
            frame.glass.append(wires)
        }
        for node in physics.nodes {
            frame.looseGlass.append(GlassPiece(
                id: Self.nodeID(node.id),
                path: TurnedTile.path(
                    size: node.size,
                    cornerRadius: node.cornerRadius,
                    angle: node.angle,
                    center: node.center
                )
            ))
            frame.symbols.append(SymbolSprite(
                id: Self.symbolID(node.id),
                name: node.symbol,
                center: node.center,
                size: node.symbolSize,
                angle: node.angle
            ))
        }
        if physics.platformWidth > 0 {
            frame.lines.append(LineSprite(id: "platform", center: physics.platformCenter, width: physics.platformWidth))
        }
        frame.particles = physics.particles.map {
            ParticleSprite(center: $0.center, diameter: $0.diameter, opacity: $0.opacity)
        }
        return frame
    }

    static func nodeID(_ index: Int) -> String {
        "node.\(index)"
    }

    static func symbolID(_ index: Int) -> String {
        "symbol.\(index)"
    }

    /// The graph's wires and beads, as the glass they were in before.
    private func wireGlass(_ physics: PhysicsFrame) -> GlassPiece? {
        var glass = GlassFrame()
        glass.wires = physics.wires
        let canvas = context.canvas
        var path = Path()
        if !physics.wires.isEmpty {
            path = glass.path(
                layout: HelloLayout.resting(in: canvas),
                markDimension: canvas.markDimension,
                context: context
            )
        }
        let radius = physics.beadDiameter / 2
        if radius > 0.25 {
            for bead in physics.beads {
                let dot = Path(ellipseIn: CGRect(
                    x: bead.x - radius,
                    y: bead.y - radius,
                    width: physics.beadDiameter,
                    height: physics.beadDiameter
                ))
                path = path.isEmpty ? dot : path.union(dot)
            }
        }
        return path.boundingRect.isNull ? nil : GlassPiece(id: "main", path: path)
    }
}
