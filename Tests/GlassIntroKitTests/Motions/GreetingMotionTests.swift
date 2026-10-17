//===--- GreetingMotionTests.swift - GlassIntroKit --------------------------===//
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

@Suite struct GreetingMotionTests {
    private let context = IntroContext(
        canvas: IntroCanvas(size: CGSize(width: 1200, height: 800), bodyDiameterRatio: 0.76),
        markOutline: GlassIntroMarkOutline.symbol("star.fill"),
        outlines: [:],
        page: 0,
        symbols: [],
        centerSymbol: nil,
        markSymbol: nil,
        words: [],
        textTop: 560
    )

    private var direct: GreetingMotion {
        GreetingMotion(entry: .handoff(.launch), context: context)
    }

    private var fromSeed: GreetingMotion {
        GreetingMotion(entry: .seed, context: context)
    }

    @Test func continuesOnlyFromTheLaunch() {
        #expect(GreetingMotion.continues(from: .launch))
        #expect(!GreetingMotion.continues(from: .word))
        #expect(!GreetingMotion.continues(from: .mark))
        #expect(!GreetingMotion.continues(from: .other))
    }

    @Test func directEntryStartsAsTheRestingMark() {
        let frame = direct.frame(at: 0, interaction: IntroInteraction())
        #expect(frame.glass.isEmpty)
        #expect(frame.mark?.center == context.canvas.center)
        #expect(frame.mark?.scale == 1)
        #expect(frame.mark?.detail == 1)
        #expect(!direct.absorbsSeed)
    }

    @Test func directEntryKeepsTheOriginalTiming() {
        #expect(abs(direct.settleTime - 6.35) < 1e-9)
        #expect(abs(direct.textTime - (2.65 + 3.2 * 0.72)) < 1e-9)
    }

    @Test func seedEntryStartsAsTheSeed() {
        let canvas = context.canvas
        let frame = fromSeed.frame(at: 0, interaction: IntroInteraction())
        #expect(fromSeed.absorbsSeed)
        #expect(frame.glass.count == 1)
        #expect(frame.glass[0].path.boundingRect == canvas.seed.rect)
        #expect(frame.mark == nil)
        #expect(fromSeed.settleTime < direct.settleTime)
    }

    @Test(arguments: [IntroEntry.handoff(.launch), IntroEntry.seed])
    func settlesAsTheWrittenWord(_ entry: IntroEntry) throws {
        let motion = GreetingMotion(entry: entry, context: context)
        let frame = motion.frame(at: motion.settleTime, interaction: IntroInteraction(reducesMotion: true))
        #expect(frame.mark == nil)
        #expect(frame.glass.count == 1)
        let bounds = try #require(frame.glass.first).path.boundingRect
        #expect(bounds.minX.isFinite && bounds.width.isFinite && bounds.height.isFinite)
        let layout = HelloLayout.resting(in: context.canvas)
        #expect(abs(bounds.midX - layout.restingFrame.midX) < layout.restingFrame.width * 0.1)
        #expect(abs(bounds.midY - layout.restingFrame.midY) < layout.restingFrame.height * 0.2)
        // Later frames, while another picture gathers it, stay the same.
        let later = motion.frame(at: motion.settleTime + 2, interaction: IntroInteraction())
        #expect(later.glass.first?.path.boundingRect == bounds)
        if case .word = motion.handoff(at: motion.settleTime, interaction: IntroInteraction()) {} else {
            Issue.record("expected the word at rest")
        }
    }

    @Test(arguments: [IntroEntry.handoff(.launch), IntroEntry.seed])
    func neverJumps(_ entry: IntroEntry) async {
        let motion = GreetingMotion(entry: entry, context: context)
        let check = ContinuityCheck(canvas: context.canvas) { motion.frame(at: $0, interaction: IntroInteraction()) }
        let faults = await check.faults(from: 0, to: motion.settleTime + 0.5)
        #expect(faults.isEmpty, "\(faults.prefix(4))")
    }
}
