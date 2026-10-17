//===--- CardMotionTests.swift - GlassIntroKit ------------------------------===//
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

@Suite struct CardMotionTests {
    private func context(size: CGSize = CGSize(width: 1200, height: 800), textTop: CGFloat = 560) -> IntroContext {
        IntroContext(
            canvas: IntroCanvas(size: size, bodyDiameterRatio: 0.76),
            markOutline: GlassIntroMarkOutline.symbol("star.fill"),
            outlines: [:],
            page: 3,
            symbols: [],
            centerSymbol: nil,
            markSymbol: nil,
            words: [],
            textTop: textTop
        )
    }

    private func motion(_ context: IntroContext) -> CardMotion {
        CardMotion(entry: .seed, context: context)
    }

    @Test func startsAsTheSeed() throws {
        let context = context()
        let frame = motion(context).frame(at: 0, interaction: IntroInteraction())
        let piece = try #require(frame.glass.first)
        let seed = context.canvas.seed
        #expect(frame.glass.count == 1)
        let bounds = piece.path.boundingRect
        #expect(abs(bounds.width - seed.diameter) < 0.01)
        #expect(abs(bounds.height - seed.diameter) < 0.01)
        #expect(abs(bounds.midX - seed.center.x) < 0.01)
        #expect(abs(bounds.midY - seed.center.y) < 0.01)
        #expect(frame.card?.contentOpacity == 0)
        #expect(motion(context).absorbsSeed)
    }

    @Test func settlesOnTheCardWithItsViewShown() throws {
        let context = context()
        let motion = motion(context)
        let frame = motion.frame(at: motion.settleTime, interaction: IntroInteraction(reducesMotion: true))
        let card = try #require(frame.card)
        #expect(card.page == 3)
        #expect(card.contentOpacity == 1)
        #expect(abs(card.contentScale - 1) < 0.0001)
        #expect(abs(card.rect.width - 520) < 0.5)
        #expect(abs(card.rect.height - 320) < 0.5)
        #expect(abs(card.rect.midX - 600) < 0.5)
        let piece = try #require(frame.glass.first)
        #expect(piece.id == "card")
        #expect(piece.path.boundingRect.insetBy(dx: -0.5, dy: -0.5).contains(card.rect))
    }

    @Test func everyFrameIsFinite() {
        let context = context()
        let motion = motion(context)
        for step in 0...400 {
            let time = Double(step) * 0.01
            let frame = motion.frame(at: time, interaction: IntroInteraction())
            let rect = frame.card?.rect ?? .null
            #expect(rect.width.isFinite && rect.height.isFinite && rect.width >= 0 && rect.height >= 0)
            #expect(frame.glass.allSatisfy { !$0.path.boundingRect.isNull && $0.path.boundingRect.width.isFinite })
        }
    }

    @Test func keepsClearOfTheTopAndThePageText() {
        for (size, textTop) in [
            (CGSize(width: 1200, height: 800), CGFloat(560)),
            (CGSize(width: 390, height: 600), CGFloat(300)),
            (CGSize(width: 390, height: 300), CGFloat(120)),
        ] {
            let layout = CardLayout(canvas: IntroCanvas(size: size, bodyDiameterRatio: 0.76), textTop: textTop)
            #expect(layout.rect.minY >= 24)
            #expect(layout.rect.height >= 80)
            #expect(layout.rect.maxY <= max(textTop - 24, 24 + 80))
            #expect(layout.rect.width <= 520)
        }
    }

    @Test func carriesOnFromNothing() {
        let handoffs: [IntroHandoff] = [
            .launch, .word, .mark, .symbols(scatter: [], center: nil), .scene(yaw: 0),
            .graph(GraphFrame()), .fallen(PhysicsFrame()), .other,
        ]
        for handoff in handoffs {
            #expect(!CardMotion.continues(from: handoff))
        }
    }

    @Test func leavesNothingToCarryOnFrom() {
        let context = context()
        let motion = motion(context)
        if case .other = motion.handoff(at: motion.settleTime, interaction: IntroInteraction()) {} else {
            Issue.record("expected no handoff")
        }
    }
}
