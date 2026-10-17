//===--- SymbolsMotion.swift - GlassIntroKit --------------------------------===//
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

/// The mark melts into a symbol, and glass symbols scatter out of it.
///
/// Following the mark, the glass mark is already open and the scatter begins
/// at once. Growing out of the seed, the plain drop first opens into the mark,
/// and the scatter follows.
nonisolated struct SymbolsMotion: PageMotion {
    /// How long the drop takes to open into the mark before the scatter
    /// begins, when the picture grows out of the seed.
    static let seedLead = 0.8

    let context: IntroContext
    private let scatter: SymbolScatter
    private let layout: HelloLayout
    /// The time before the scatter begins; zero when the mark is already open.
    private let lead: Double

    static func continues(from handoff: IntroHandoff) -> Bool {
        if case .mark = handoff {
            return true
        }
        return false
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
        let canvas = context.canvas
        scatter = SymbolScatter(canvasSize: canvas.size, center: canvas.graphicCenter, symbols: context.symbols)
        layout = .resting(in: canvas)
        if case .handoff(.mark) = entry {
            lead = 0
        } else {
            lead = Self.seedLead
        }
    }

    var settleTime: Double {
        lead + SymbolScatter.end
    }

    var textTime: Double {
        lead + SymbolScatter.textStart
    }

    var absorbsSeed: Bool {
        true
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        let canvas = context.canvas
        let scatterTime = max(time - lead, 0)

        var glass = GlassFrame()
        glass.markCenter = canvas.graphicCenter
        glass.markGrowth = markGrowth(at: time)
        glass.apertureOpening = apertureOpening(at: time)
        glass.morph = scatter.morph(at: scatterTime)
        glass.centerScale = scatter.centerScale(at: scatterTime)
        if context.centerGlyph != nil {
            // The symbol swells out of the mark and the mark's body gives
            // way to it, both without a step.
            glass.centerScale *= scatter.glyphEmergence(at: scatterTime)
            glass.markGrowth *= scatter.bodyRemaining(at: scatterTime)
        }

        var frame = IntroFrame()
        frame.glass = [GlassPiece(
            id: "main",
            path: glass.path(layout: layout, markDimension: canvas.markDimension, context: context)
        )]
        for bubble in scatter.bubbles(at: scatterTime) {
            frame.glass.append(bubble.glassPiece(outline: context.outlines[bubble.symbol]))
        }
        return frame
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .symbols(scatter: context.symbols, center: context.centerSymbol)
    }

    // MARK: Coming in from the seed

    /// How far the mark has grown at `time`: from the seed's own size to its
    /// full body, like a breath, when it begins as the seed.
    private func markGrowth(at time: Double) -> Double {
        guard lead > 0 else {
            return 1
        }
        let full = context.canvas.markDimension * context.markOutline.bodyDiameterRatio
        let point = layout.lineWidth(at: 1)
        let seed = Ease.clamp((context.canvas.seed.diameter - point) / max(full - point, 1))
        return Ease.lerp(seed, 1, Ease.smoother(time / lead))
    }

    /// How far the mark's detail is open at `time`: closed in the seed, open
    /// by the time the scatter begins.
    private func apertureOpening(at time: Double) -> Double {
        guard lead > 0 else {
            return 1
        }
        return Ease.smoother((time - lead * 0.25) / (lead * 0.75))
    }
}
