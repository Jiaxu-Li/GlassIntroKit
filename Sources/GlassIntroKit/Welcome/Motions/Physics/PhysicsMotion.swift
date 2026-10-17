//===--- PhysicsMotion.swift - GlassIntroKit --------------------------------===//
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

/// Nodes fall onto a line under real physics.
///
/// After the graph, the graph's own nodes let go: its wires draw back and
/// the nodes fall. From anywhere else the page makes its own three nodes,
/// which swell out of the seed to where the graph would have put them and
/// then fall. The fall is simulated once, when the picture is built.
nonisolated struct PhysicsMotion: PageMotion {
    let context: IntroContext
    let reveal: PhysicsReveal
    /// How the nodes leave the seed; nil when they are the graph's.
    let growth: PhysicsGrowth?

    static func continues(from handoff: IntroHandoff) -> Bool {
        if case .graph = handoff {
            return true
        }
        return false
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
        let canvas = context.canvas
        let platformY = context.textTop - (canvas.isCompact ? Self.compactPlatformGap : Self.platformGap)
        if case .handoff(.graph(let graph)) = entry {
            reveal = PhysicsReveal(canvasSize: canvas.size, logic: graph, platformY: platformY)
            growth = nil
            return
        }
        // The nodes in a row, ready to fall.
        let resting = Self.row(
            Array(context.symbols.prefix(GlassIntroGraph.maximumNodeCount)),
            canvasSize: canvas.size,
            center: canvas.graphicCenter
        )
        var logic = GraphFrame()
        logic.nodes = resting
        reveal = PhysicsReveal(canvasSize: canvas.size, logic: logic, platformY: platformY)
        growth = PhysicsGrowth(seed: canvas.seed, resting: resting)
    }

    /// `symbols` as nodes in a row centered on `center`, every other one a
    /// little higher so they do not land all at once, scaled down to fit.
    static func row(_ symbols: [String], canvasSize: CGSize, center: CGPoint) -> [GraphNodeFrame] {
        let symbols = symbols.isEmpty ? GlassIntroPage.defaultNodeSymbols : symbols
        let compact = canvasSize.width < 640
        let base = compact ? CGSize(width: 72, height: 46) : CGSize(width: 92, height: 56)
        let baseGap: CGFloat = compact ? 22 : 40
        let count = CGFloat(symbols.count)
        let width = count * base.width + (count - 1) * baseGap
        let scale = min(1, (canvasSize.width - 80) / max(width, 1))
        let size = CGSize(width: base.width * scale, height: base.height * scale)
        let gap = baseGap * scale
        let left = center.x - (width * scale) / 2
        return symbols.enumerated().map { index, symbol in
            let rise = index.isMultiple(of: 2) ? 0 : size.height * 0.8
            return GraphNodeFrame(
                id: index,
                symbol: symbol,
                rect: CGRect(
                    x: left + CGFloat(index) * (size.width + gap),
                    y: center.y - size.height / 2 - rise,
                    width: size.width,
                    height: size.height
                ),
                cornerRadius: size.height * 0.36,
                symbolOpacity: 1,
                symbolScale: 1,
                symbolSize: size.height * 0.42
            )
        }
    }

    /// How far above the page's text the line sits.
    static let platformGap: CGFloat = 28
    /// On a phone, where the text is closer, the line keeps a little more
    /// room from it.
    static let compactPlatformGap: CGFloat = 44

    /// How long the nodes take to leave the seed, if they do.
    var growthDuration: Double {
        growth == nil ? 0 : PhysicsGrowth.duration
    }

    var settleTime: Double {
        growthDuration + PhysicsReveal.end
    }

    var textTime: Double {
        growthDuration + PhysicsReveal.textStart
    }

    var absorbsSeed: Bool {
        true
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        let fall = time - growthDuration
        if let growth, fall < 0 {
            return grownFrame(growth, at: max(time, 0))
        }
        return fallingFrame(reveal.frame(at: max(fall, 0)))
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .fallen(reveal.frame(at: max(time - growthDuration, 0)))
    }
}
