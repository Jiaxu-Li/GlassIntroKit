//===--- FinaleMotionTests.swift - GlassIntroKit ----------------------------===//
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

@Suite struct FinaleMotionTests {
    private func context(words: [String]) -> IntroContext {
        IntroContext(
            canvas: IntroCanvas(size: CGSize(width: 1200, height: 800), bodyDiameterRatio: 0.76),
            markOutline: GlassIntroMarkOutline.symbol("star.fill"),
            outlines: [:],
            page: 0,
            symbols: [],
            centerSymbol: nil,
            markSymbol: nil,
            words: words,
            textTop: 560
        )
    }

    private let interaction = IntroInteraction()

    @Test func startsEmpty() {
        let motion = FinaleMotion(entry: .seed, context: context(words: ["Make", "it", "yours"]))
        let frame = motion.frame(at: 0, interaction: interaction)
        #expect(frame.glass.isEmpty)
        #expect(frame.looseGlass.isEmpty)
        #expect(frame.mark == nil)
    }

    @Test func settlesOnTheColouredMarkAtTheCenter() {
        let context = context(words: ["Make", "it", "yours"])
        let motion = FinaleMotion(entry: .seed, context: context)
        let frame = motion.frame(at: motion.settleTime, interaction: interaction)
        #expect(frame.looseGlass.isEmpty)
        #expect(frame.glassOpacity == 0)
        let mark = frame.mark
        #expect(mark?.colour == 1)
        #expect(mark?.center == context.canvas.center)
        #expect(mark?.swell == 1)
        #expect(abs(mark?.glow ?? 1) < 1e-9)
        #expect(mark?.opacity == 1)
    }

    @Test func wordsAreLooseGlassAndTheMarkIsMain() {
        let motion = FinaleMotion(entry: .seed, context: context(words: ["Make", "it", "yours"]))
        let wordFrame = motion.frame(at: 1.0, interaction: interaction)
        #expect(wordFrame.looseGlass.first?.id == "word.0")
        #expect(wordFrame.glass.isEmpty)
        let markFrame = motion.frame(at: motion.blackTime + 1.4, interaction: interaction)
        #expect(markFrame.glass.map(\.id) == ["main"])
        #expect(markFrame.glassOpacity > 0)
    }

    @Test func blackComesAfterTheLastWord() {
        let motion = FinaleMotion(entry: .seed, context: context(words: ["Make", "it", "yours"]))
        #expect(motion.blackTime > 0)
        #expect(motion.blackTime < motion.settleTime)
        #expect(motion.textTime == 0)
        #expect(!motion.absorbsSeed)
    }

    @Test func withoutWordsTheMarkSimplyForms() {
        let motion = FinaleMotion(entry: .seed, context: context(words: []))
        #expect(motion.frame(at: 0.5, interaction: interaction).looseGlass.isEmpty)
        let frame = motion.frame(at: motion.settleTime, interaction: interaction)
        #expect(frame.mark?.colour == 1)
    }

    @Test func everyFrameIsFinite() {
        let motion = FinaleMotion(entry: .seed, context: context(words: ["Make", "it", "yours"]))
        var time = 0.0
        while time < motion.settleTime + 2 {
            let frame = motion.frame(at: time, interaction: interaction)
            for piece in frame.glass + frame.looseGlass {
                let box = piece.path.boundingRect
                #expect(box.isNull || (box.minX.isFinite && box.maxX.isFinite && box.minY.isFinite && box.maxY.isFinite), "at \(time)")
                #expect(piece.blur.isFinite && piece.opacity.isFinite)
            }
            time += 0.05
        }
    }

    @Test func continuesFromEveryHandoff() {
        let handoffs: [IntroHandoff] = [.launch, .word, .mark, .symbols(scatter: [], center: nil), .scene(yaw: 0), .other]
        for handoff in handoffs {
            #expect(FinaleMotion.continues(from: handoff))
        }
    }

    @Test func handsBackToTheLaunchAtRest() {
        let motion = FinaleMotion(entry: .seed, context: context(words: ["Make"]))
        if case .launch = motion.handoff(at: motion.settleTime, interaction: interaction) {} else {
            Issue.record("expected the launch handoff")
        }
    }
}
