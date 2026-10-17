//===--- SymbolScatter.swift - GlassIntroKit --------------------------------===//
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

/// The symbol the mark melts into, as an outline glass can take: a traced
/// symbol fitted to a unit square centered on the origin.
nonisolated struct CenterGlyph: Sendable {
    let unitPath: Path

    /// The glyph `side` points tall around `center`.
    func path(centeredAt center: CGPoint, side: CGFloat) -> Path {
        unitPath.applying(
            CGAffineTransform(translationX: center.x, y: center.y)
                .scaledBy(x: side, y: side)
        )
    }
}

/// One glass symbol in one frame.
nonisolated struct ScatterBubbleFrame: Identifiable, Sendable {
    let id: Int
    let symbol: String
    let center: CGPoint
    /// The side of the square the symbol is fitted to.
    var diameter: CGFloat
    /// How soft the symbol's glass is: sharp near the center, softening as it
    /// nears the canvas's edge, like glass falling out of focus.
    let blur: CGFloat
}

/// The symbols page's movement: the glass mark melts into its symbol, the
/// symbol draws in, and the scattered symbols pull free of its glass, a
/// quick wave first and, half a second later, the rest together, each
/// settling softly where it belongs on one of two rings.
nonisolated struct SymbolScatter: Sendable {
    static let morphDuration = 0.9
    static let shrinkStart = 1.0
    static let shrinkDuration = 1.4
    static let shrunkScale: CGFloat = 0.55
    static let emergeStart = 1.2
    /// The first wave leaves in quick succession.
    static let firstWaveCount = 10
    static let firstWaveStagger = 0.07
    /// The rest leave together after a pause.
    static let wavePause = 0.5
    static let secondWaveStagger = 0.05
    static let textStart = 1.9
    static let end = 4.4
    /// Where playing it back begins: the symbols have settled by then.
    static let gatherFrom = 4.2

    private struct Bubble: Sendable {
        let symbol: String
        let degrees: Double
        let reach: CGFloat
        let size: CGFloat
    }

    /// `symbols` on two rings: the first part on the outer ring, the rest
    /// on the inner one, alternating rings so neighbours never leave
    /// together.
    private static func bubbles(for symbols: [String]) -> [Bubble] {
        let outerCount = symbols.count < 4 ? symbols.count : (symbols.count * 9 + 15) / 16
        let outer = symbols.prefix(outerCount)
        let inner = symbols.dropFirst(outerCount)
        var result: [Bubble] = []
        for (index, symbol) in outer.enumerated() {
            result.append(Bubble(
                symbol: symbol,
                degrees: -70 + Double(index) * 360 / Double(max(outer.count, 1)),
                reach: index.isMultiple(of: 2) ? 1 : 0.92,
                size: index.isMultiple(of: 3) ? 64 : 56
            ))
        }
        for (index, symbol) in inner.enumerated() {
            result.append(Bubble(
                symbol: symbol,
                degrees: -65 + Double(index) * 360 / Double(max(inner.count, 1)),
                reach: 0.56,
                size: 46
            ))
        }
        return result.enumerated()
            .sorted { ($0.offset % 2, $0.offset) < ($1.offset % 2, $1.offset) }
            .map(\.element)
    }

    let center: CGPoint
    private let bubbles: [Bubble]
    private let canvasSize: CGSize
    private let radii: CGSize
    private let sizeScale: CGFloat

    /// The blur at the very edge, and how far in from the edge it fades.
    private static let edgeBlur: CGFloat = 9
    private static let edgeFalloff: CGFloat = 0.3

    init(canvasSize: CGSize, center: CGPoint, symbols: [String]) {
        self.center = center
        bubbles = Self.bubbles(for: symbols)
        self.canvasSize = canvasSize
        radii = CGSize(
            width: min(canvasSize.width * 0.40, 460),
            height: min(canvasSize.height * 0.25, 210)
        )
        sizeScale = canvasSize.width < 640 ? 0.8 : 1
    }

    /// How far the mark has melted into its symbol.
    func morph(at time: Double) -> Double {
        Ease.smoother(time / Self.morphDuration)
    }

    /// Where the mark's glass begins to take the center symbol's shape: the
    /// glass outline draws the symbol from here on.
    static let glyphStart = 0.2
    /// How much of the melted mark's body is left once it has shrunk into
    /// the symbol, as it dissolves in the symbol's glass.
    static let bodyDissolveStart = 0.75

    /// How much of its size the center symbol has as it first swells out of
    /// the mark: next to nothing when it is first drawn, so it never appears
    /// all at once.
    func glyphEmergence(at time: Double) -> CGFloat {
        0.02 + 0.98 * CGFloat(Ease.smoother((morph(at: time) - Self.glyphStart) / 0.12))
    }

    /// How much of the mark's body is left as the symbol takes its place: the
    /// body shrinks out of the glass at the end of the melt instead of
    /// being cut away at once.
    func bodyRemaining(at time: Double) -> Double {
        1 - Ease.smoother((morph(at: time) - Self.bodyDissolveStart) / (1 - Self.bodyDissolveStart))
    }

    func centerScale(at time: Double) -> CGFloat {
        let eased = Ease.smoother((time - Self.shrinkStart) / Self.shrinkDuration)
        return 1 - (1 - Self.shrunkScale) * eased
    }

    /// When the symbol at `index` leaves the center.
    private static func departure(of index: Int) -> Double {
        if index < firstWaveCount {
            return emergeStart + Double(index) * firstWaveStagger
        }
        let secondWave = emergeStart + Double(firstWaveCount - 1) * firstWaveStagger + wavePause
        return secondWave + Double(index - firstWaveCount) * secondWaveStagger
    }

    func bubbles(at time: Double) -> [ScatterBubbleFrame] {
        guard time >= Self.emergeStart - 0.05 else {
            return []
        }
        return bubbles.enumerated().map { index, bubble in
            // A long, well-damped spring: the symbol eases out of the
            // glass and settles without a bounce.
            let travel = Ease.spring(time - Self.departure(of: index), period: 1.6, damping: 0.88)
            let angle = bubble.degrees * .pi / 180
            let target = CGPoint(
                x: center.x + radii.width * bubble.reach * cos(angle),
                y: center.y + radii.height * bubble.reach * sin(angle)
            )
            let grown = Ease.smoother(travel / 0.7)
            let position = CGPoint(
                x: center.x + (target.x - center.x) * travel,
                y: center.y + (target.y - center.y) * travel
            )
            return ScatterBubbleFrame(
                id: index,
                symbol: bubble.symbol,
                center: position,
                diameter: bubble.size * sizeScale * (0.3 + 0.7 * grown),
                blur: edgeBlur(at: position)
            )
        }
    }

    private func edgeBlur(at point: CGPoint) -> CGFloat {
        let toEdge = min(point.x, point.y, canvasSize.width - point.x, canvasSize.height - point.y)
        let falloff = max(min(canvasSize.width, canvasSize.height) * Self.edgeFalloff, 1)
        return Self.edgeBlur * (1 - Ease.smoother(toEdge / falloff))
    }
}
