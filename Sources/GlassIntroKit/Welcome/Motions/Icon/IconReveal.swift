//===--- IconReveal.swift - GlassIntroKit -----------------------------------===//
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

/// One of the fallen nodes as it is drawn back in.
nonisolated struct IconTileFrame: Identifiable, Sendable {
    let id: Int
    let symbol: String
    let center: CGPoint
    let angle: Double
    let size: CGSize
    let cornerRadius: CGFloat
    let symbolSize: CGFloat
    let symbolOpacity: Double
}

/// The icon page in one frame.
nonisolated struct IconFrame: Sendable {
    var tiles: [IconTileFrame] = []
    /// The physics page's platform as it closes.
    var platformCenter: CGPoint = .zero
    var platformWidth: CGFloat = 0
    /// The app icon the nodes are forged into.
    var iconCenter: CGPoint = .zero
    var iconSide: CGFloat = 0
    var iconSymbolOpacity: Double = 0
    var iconSymbolScale: CGFloat = 1
    /// How far the icon has taken its shape: 0 is a circle, as the seed is,
    /// and 1 the app icon's rounded square.
    var iconRoundness: Double = 1
    /// The light polishing across the icon, as a fraction of the way across,
    /// or nil when none is crossing.
    var sheen: Double?
    /// The badge that says the app is ready to ship.
    var badgeCenter: CGPoint = .zero
    var badgeDiameter: CGFloat = 0
    var badgeSymbolOpacity: Double = 0

    /// An app icon's corner radius for its side.
    static func iconCornerRadius(_ side: CGFloat) -> CGFloat {
        side * 0.2237
    }

    /// The icon's corner radius as it is, between a circle and the app
    /// icon's.
    var iconCorner: CGFloat {
        min(Ease.lerp(iconSide / 2, Self.iconCornerRadius(iconSide), iconRoundness), iconSide / 2)
    }
}

/// The icon page's movement. The platform closes, and the fallen nodes
/// lift off it together, levelling as they gather at the center, where
/// their glass flows into one piece again and settles into an app icon.
/// A light polishes across it once, and a bead grows out of its corner into
/// a badge: the app is built and ready to ship.
///
/// Coming from the seed instead, there are no nodes: the seed itself swells
/// into the icon and the rest follows, a little sooner.
nonisolated struct IconReveal: Sendable {
    static let platformDuration = 0.5
    static let gatherStart = 0.15
    static let gatherStagger = 0.08
    static let gatherDuration = 1.0
    static let meltStart = 0.9
    static let meltDuration = 0.5
    static let iconStart = 0.75
    static let iconSymbolStart = 1.4
    static let sheenStart = 1.75
    static let sheenDuration = 0.7
    static let badgeStart = 2.15
    static let textStart = 1.6
    static let end = 3.2

    private let center: CGPoint
    private let iconSide: CGFloat
    private let start: PhysicsFrame
    /// The seed's diameter when the icon swells out of the seed, or nil
    /// when it forms from the gathered nodes.
    private let seedDiameter: CGFloat?

    /// The icon formed from the fallen nodes.
    /// - Parameters:
    ///   - start: the physics page as it came to rest.
    ///   - center: where the icon forms.
    init(canvasSize: CGSize, start: PhysicsFrame, center: CGPoint) {
        self.start = start
        self.center = center
        iconSide = Self.iconSide(for: canvasSize)
        seedDiameter = nil
    }

    /// The icon swelled out of `seed`, which the nodes never touch.
    init(canvasSize: CGSize, seed: GlassSeed) {
        start = PhysicsFrame()
        center = seed.center
        iconSide = Self.iconSide(for: canvasSize)
        seedDiameter = seed.diameter
    }

    /// How far into its own timeline the picture starts: nothing gathers
    /// before the icon swells out of the seed.
    private var lead: Double {
        seedDiameter == nil ? 0 : Self.iconStart
    }

    /// When the picture has come to rest.
    var settleTime: Double {
        Self.end - lead
    }

    /// When the page's text comes in.
    var textTime: Double {
        Self.textStart - lead
    }

    private static func iconSide(for canvasSize: CGSize) -> CGFloat {
        canvasSize.width < 640 ? 112 : 132
    }

    func frame(at elapsed: Double) -> IconFrame {
        let time = elapsed + lead
        var frame = IconFrame()

        let closing = Ease.smoother(time / Self.platformDuration)
        frame.platformCenter = start.platformCenter
        frame.platformWidth = start.platformWidth * CGFloat(1 - closing)

        // The nodes gather, level, and shrink as they go, then melt into
        // the icon.
        let melt = Ease.smoother((time - Self.meltStart) / Self.meltDuration)
        for (index, node) in start.nodes.enumerated() {
            let gather = Ease.smoother(
                (time - Self.gatherStart - Double(index) * Self.gatherStagger) / Self.gatherDuration
            )
            let scale = (1 - 0.4 * gather) * (1 - melt)
            guard scale > 0.01 else {
                continue
            }
            // Level to the nearest whole turn, the short way round.
            let level = (node.angle / (2 * .pi)).rounded() * 2 * .pi
            frame.tiles.append(IconTileFrame(
                id: index,
                symbol: node.symbol,
                center: Ease.lerp(node.center, center, gather),
                angle: Ease.lerp(node.angle, level, gather),
                size: CGSize(width: node.size.width * scale, height: node.size.height * scale),
                cornerRadius: node.cornerRadius * scale,
                symbolSize: node.symbolSize * scale,
                symbolOpacity: 1 - Ease.smoother(gather / 0.5)
            ))
        }

        // The icon swells out of the gathered glass, or out of the seed, on
        // a soft spring.
        frame.iconCenter = center
        let swell = CGFloat(Ease.spring(time - Self.iconStart, period: 1.0, damping: 0.78))
        let from = seedDiameter ?? 0
        frame.iconSide = from + (iconSide - from) * swell
        if seedDiameter != nil {
            frame.iconRoundness = Ease.smoother((time - Self.iconStart) / 0.7)
        }
        let symbol = Ease.smoother((time - Self.iconSymbolStart) / 0.5)
        frame.iconSymbolOpacity = symbol
        frame.iconSymbolScale = 0.75 + 0.25 * CGFloat(symbol)

        let sheen = (time - Self.sheenStart) / Self.sheenDuration
        if sheen > 0, sheen < 1 {
            frame.sheen = Ease.smoother(sheen)
        }

        // The badge grows out of the icon's top-right corner, a bead first,
        // drifting a little outward as it swells.
        let badgeTime = time - Self.badgeStart
        if badgeTime > 0 {
            let growth = CGFloat(Ease.spring(badgeTime, period: 0.9, damping: 0.75))
            let final = iconSide * 0.34
            let bead = GraphReveal.beadDiameter * CGFloat(Ease.smoother(badgeTime / 0.12))
            frame.badgeDiameter = bead + (final - bead) * growth
            let corner = iconSide * 0.32
            let reach = corner + iconSide * 0.08 * growth
            frame.badgeCenter = CGPoint(x: center.x + reach, y: center.y - reach)
            frame.badgeSymbolOpacity = Ease.smoother((badgeTime - 0.3) / 0.4)
        }
        return frame
    }
}
