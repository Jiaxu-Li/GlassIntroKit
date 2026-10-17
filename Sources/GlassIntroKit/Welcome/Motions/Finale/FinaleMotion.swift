//===--- FinaleMotion.swift - GlassIntroKit ---------------------------------===//
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

/// The ending: the words turn in one after another in glass, the picture
/// goes to black, the mark forms in glass at the center of the canvas, and
/// colour spreads through it from its light.
///
/// It follows the last page directly, so it starts from nothing whatever
/// came before; when the seed is under it, the seed shrinks away on its own.
nonisolated struct FinaleMotion: PageMotion {
    let context: IntroContext
    private let reveal: FinaleReveal
    /// How much of the colour's spread the mark fades in over.
    private static let colourFadeIn = 0.2
    /// The words are glass that must be read, over the last page's plain
    /// light.
    static let wordTint = 0.12

    static func continues(from handoff: IntroHandoff) -> Bool {
        true
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
        reveal = FinaleReveal(canvasSize: context.canvas.size, lines: context.words)
    }

    var settleTime: Double {
        reveal.end
    }

    var textTime: Double {
        0
    }

    /// When the picture behind starts to go to black.
    var blackTime: Double {
        reveal.blackStart
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        let canvas = context.canvas
        let finale = reveal.frame(at: time)
        var frame = IntroFrame()
        // The words are glass of their own: they never flow into the mark.
        frame.looseGlass = finale.words.map {
            GlassPiece(id: "word.\($0.id)", path: $0.path, blur: $0.blur, opacity: $0.opacity, tint: Self.wordTint)
        }
        if finale.glassMarkGrowth > 0 {
            // The mark in glass, where the launch draws it.
            let outline = GlassFrame(
                markCenter: canvas.center,
                markGrowth: finale.glassMarkGrowth,
                apertureOpening: 1
            ).path(layout: HelloLayout.resting(in: canvas), markDimension: canvas.markDimension, context: context)
            frame.glass = [GlassPiece(id: "main", path: outline)]
        }
        frame.glassOpacity = finale.glassMarkOpacity
        if finale.colour > 0 {
            // Colour has barely begun to spread when the mark first shows,
            // so it comes in over the first of it rather than at once.
            frame.mark = MarkSprite(
                center: canvas.center,
                scale: 1,
                detail: 1,
                opacity: Ease.smoother(finale.colour / Self.colourFadeIn),
                colour: finale.colour,
                glow: finale.glow,
                swell: finale.swell
            )
        }
        return frame
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .launch
    }
}
