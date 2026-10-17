//===--- RestMotionTests.swift - GlassIntroKit ------------------------------===//
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
import Testing
@testable import GlassIntroKit

@Suite struct RestMotionTests {
    private let context = IntroContext(
        canvas: IntroCanvas(size: CGSize(width: 1200, height: 800), bodyDiameterRatio: 0.76),
        markOutline: GlassIntroMarkOutline.symbol("star.fill"),
        outlines: [:],
        page: 5,
        symbols: [],
        centerSymbol: nil,
        markSymbol: nil,
        words: [],
        textTop: 560
    )

    @Test func showsNothingAtAnyTime() {
        let motion = RestMotion(entry: .seed, context: context)
        for time in [0, 0.2, motion.settleTime, 5] {
            let frame = motion.frame(at: time, interaction: IntroInteraction())
            #expect(frame.glass.isEmpty && frame.symbols.isEmpty && frame.card == nil && frame.mark == nil)
        }
    }

    @Test func arrivesOnceThePictureBeforeHasDissolved() {
        let motion = RestMotion(entry: .empty, context: context)
        #expect(RestMotion.arrivesEmpty)
        #expect(motion.absorbsSeed)
        #expect(motion.settleTime == 0 && motion.textTime == 0)
    }

    @Test func thePictureBeforeDissolvesWhereItIs() {
        let context = self.context
        let mark = MarkMotion(entry: .seed, context: context)
        var player = WelcomePlayer(resting: mark)
        player.turn(
            at: 10,
            interaction: IntroInteraction(),
            continues: RestMotion.continues(from:),
            arrivesEmpty: true,
            build: { RestMotion(entry: $0, context: context) }
        )
        guard case .empty = player.current.entry else {
            Issue.record("expected the last page to start from nothing")
            return
        }
        // Halfway, the mark is still where it was, not gathered to the seed.
        let rest = mark.frame(at: 100, interaction: IntroInteraction())
        let halfway = player.frame(at: 10 + WelcomePlayer.dissolveDuration / 2, interaction: IntroInteraction())
        let restBounds = rest.glass.map(\.path.boundingRect).reduce(CGRect.null) { $0.union($1) }
        let halfBounds = halfway.glass.map(\.path.boundingRect).reduce(CGRect.null) { $0.union($1) }
        #expect(abs(restBounds.midX - halfBounds.midX) < 0.5 && abs(restBounds.midY - halfBounds.midY) < 0.5)
        #expect(halfBounds.width < restBounds.width)
        let gone = player.frame(at: 10 + WelcomePlayer.dissolveDuration, interaction: IntroInteraction())
        #expect(gone.glass.isEmpty && gone.symbols.isEmpty)
    }

    @Test func alwaysFollowsTheSeed() {
        let handoffs: [IntroHandoff] = [
            .launch, .word, .mark, .symbols(scatter: [], center: nil), .scene(yaw: 0),
            .graph(GraphFrame()), .fallen(PhysicsFrame()), .other,
        ]
        for handoff in handoffs {
            #expect(!RestMotion.continues(from: handoff))
        }
    }
}
