//===--- LaunchMotion.swift - GlassIntroKit ---------------------------------===//
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

/// The mark in colour at the canvas's center, as the launch hands it over.
///
/// It is the start of every welcome and never moves on its own. When the
/// first page does not take it up, it rests a moment, then travels to the
/// seed's place as its detail goes out and turns into the seed's glass.
nonisolated struct LaunchMotion: PageMotion {
    let context: IntroContext

    /// How long the mark takes to turn into the seed.
    static let leaveDuration = 1.6
    /// The share of the leaving the mark rests before it sets off.
    static let restShare = 0.35
    /// Where in the leaving the mark turns into glass: the seed comes in
    /// from here to the end.
    static let glassShare = 0.6

    static func continues(from handoff: IntroHandoff) -> Bool {
        false
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
    }

    var settleTime: Double {
        0
    }

    var textTime: Double {
        0
    }

    /// The mark is already on screen when the welcome begins; there is no
    /// seed beneath it to shrink away.
    var absorbsSeed: Bool {
        true
    }

    var exitDuration: Double {
        Self.leaveDuration
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        IntroFrame(mark: MarkSprite(center: context.canvas.center, scale: 1, detail: 1, opacity: 1))
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .launch
    }

    func exitFrame(from frame: IntroFrame, at time: Double, progress: Double) -> IntroFrame {
        let canvas = context.canvas
        let p = Ease.clamp(progress)
        guard p < 1 else {
            return .seed(canvas.seed)
        }
        // The mark rests, then travels to the seed's place; its detail goes
        // out on the way, leaving the plain body, which is the seed's size.
        let leaving = Ease.clamp((p - Self.restShare) / (1 - Self.restShare))
        let travel = Ease.smoother(leaving)
        let detail = 1 - Ease.smoother(leaving / 0.6)
        // The glass seed comes up beneath the body before the body goes
        // out, so the two overlap rather than dip.
        let glass = Ease.smoother((p - Self.glassShare) / 0.3)
        let body = 1 - Ease.smoother((p - (Self.glassShare + 0.1)) / 0.3)

        var result = IntroFrame()
        if glass > 0 {
            var seed = canvas.seed.piece()
            seed.opacity = glass
            result.glass = [seed]
        }
        if body > 0 {
            result.mark = MarkSprite(
                center: Ease.lerp(canvas.center, canvas.seed.center, travel),
                scale: canvas.seed.diameter / max(canvas.bodyDiameter, 1),
                detail: detail,
                opacity: body
            )
        }
        return result
    }
}
