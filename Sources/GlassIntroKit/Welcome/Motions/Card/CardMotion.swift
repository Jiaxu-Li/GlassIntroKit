//===--- CardMotion.swift - GlassIntroKit -----------------------------------===//
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

/// A page's own view on a card of glass. The card grows out of the seed:
/// a drop that spreads into a rounded rectangle on a soft spring, and only
/// then shows the page's view on it.
nonisolated struct CardMotion: PageMotion {
    static let glassID = "card"
    /// The spring the card spreads on.
    static let springPeriod = 0.8
    static let springDamping = 0.85

    let context: IntroContext
    private let layout: CardLayout

    /// Whatever came before, the card grows out of the seed.
    static func continues(from handoff: IntroHandoff) -> Bool {
        false
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
        layout = CardLayout(canvas: context.canvas, textTop: context.textTop)
    }

    var settleTime: Double {
        1.2
    }

    var textTime: Double {
        0.6
    }

    var absorbsSeed: Bool {
        true
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        let seed = context.canvas.seed
        let spread = Ease.spring(time, period: Self.springPeriod, damping: Self.springDamping)
        let rect = layout.rect(from: seed, progress: spread)
        let radius = layout.cornerRadius(of: rect, from: seed, progress: spread)

        // The seed is a true circle, so the corners are circular, too: a
        // continuous corner of the same radius would already bulge.
        let piece = GlassPiece(
            id: Self.glassID,
            path: Path(roundedRect: rect, cornerRadius: radius, style: .circular)
        )
        // The view waits for the card to have mostly grown.
        let shown = Ease.smoother((time - 0.45) / 0.5)
        let card = CardSprite(
            page: context.page,
            rect: rect,
            contentOpacity: shown,
            contentScale: Ease.lerp(0.96, 1, shown)
        )
        return IntroFrame(glass: [piece], card: card)
    }
}
