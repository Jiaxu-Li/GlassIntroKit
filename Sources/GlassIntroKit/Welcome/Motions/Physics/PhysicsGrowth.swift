//===--- PhysicsGrowth.swift - GlassIntroKit --------------------------------===//
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

/// One node of the growth: a tile on its way out of the seed.
nonisolated struct PhysicsGrowthNode: Identifiable, Sendable {
    let id: Int
    let symbol: String
    let rect: CGRect
    let cornerRadius: CGFloat
    let symbolSize: CGFloat
    let symbolOpacity: Double
    let symbolScale: CGFloat
    /// Whether the tile has size enough to be drawn at all.
    var isVisible: Bool {
        rect.width > 0.5 && rect.height > 0.5
    }
}

/// The physics page's growth when it follows a page that has no nodes to
/// let go of: the seed swells apart into three tiles, which travel out of
/// it to the places the graph page would have put them, then fall.
nonisolated struct PhysicsGrowth: Sendable {
    /// How long the tiles take to leave the seed, the last one included.
    static let duration = 0.75
    /// How much later each tile starts than the one before.
    static let stagger = 0.05
    /// The seed starts to give way once the first tile has started, and is
    /// gone before the last tile lands.
    private static let seedFadeStart = 0.04
    private static let seedFadeDuration = 0.55

    let seed: GlassSeed
    /// The tiles as they rest, as the graph page leaves them.
    private let resting: [GraphNodeFrame]

    init(seed: GlassSeed, resting: [GraphNodeFrame]) {
        self.seed = seed
        self.resting = resting
    }

    /// How much of the seed is left `time` seconds in.
    func seedScale(at time: Double) -> CGFloat {
        CGFloat(1 - Ease.smoother((time - Self.seedFadeStart) / Self.seedFadeDuration))
    }

    /// The tiles `time` seconds in. The tile that starts last arrives
    /// exactly at `duration`, where it is the tile the graph page leaves.
    func nodes(at time: Double) -> [PhysicsGrowthNode] {
        let span = Self.duration - Self.stagger * Double(max(resting.count - 1, 0))
        return resting.enumerated().map { index, node in
            let progress = (time - Self.stagger * Double(index)) / span
            // The tile moves out quickly and swells a little behind its
            // travel, so it leaves the seed as a drop and ends as a tile.
            let travel = Ease.easeOut(progress)
            let swell = Ease.smoother(progress)
            let target = CGPoint(x: node.rect.midX, y: node.rect.midY)
            let center = Ease.lerp(seed.center, target, travel)
            let size = CGSize(width: node.rect.width * swell, height: node.rect.height * swell)
            let radius = min(node.cornerRadius * swell, min(size.width, size.height) / 2)
            let label = Ease.smoother((progress - 0.45) / 0.5)
            return PhysicsGrowthNode(
                id: node.id,
                symbol: node.symbol,
                rect: CGRect(
                    x: center.x - size.width / 2,
                    y: center.y - size.height / 2,
                    width: size.width,
                    height: size.height
                ),
                cornerRadius: radius,
                symbolSize: node.symbolSize,
                symbolOpacity: label,
                symbolScale: 0.7 + 0.3 * CGFloat(label)
            )
        }
    }
}
