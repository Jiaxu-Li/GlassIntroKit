//===--- LaunchMotionTests.swift - GlassIntroKit ----------------------------===//
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

@Suite struct LaunchMotionTests {
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

    private var motion: LaunchMotion {
        LaunchMotion(entry: .seed, context: context)
    }

    @Test func restsAsTheClosedMark() {
        let frame = motion.frame(at: 0, interaction: IntroInteraction())
        #expect(frame.glass.isEmpty)
        #expect(frame.mark?.center == context.canvas.center)
        #expect(frame.mark?.scale == 1)
        #expect(frame.mark?.detail == 1)
        #expect(frame.mark?.opacity == 1)
        #expect(motion.settleTime == 0 && motion.textTime == 0)
    }

    @Test func offersTheLaunchAndContinuesFromNothing() {
        if case .launch = motion.handoff(at: 0, interaction: IntroInteraction()) {} else {
            Issue.record("expected the launch handoff")
        }
        #expect(!LaunchMotion.continues(from: .launch))
        #expect(!LaunchMotion.continues(from: .word))
    }

    @Test func leavingEndsAsTheSeedAlone() {
        let canvas = context.canvas
        let rest = motion.frame(at: 0, interaction: IntroInteraction())
        let start = motion.exitFrame(from: rest, at: 0, progress: 0)
        #expect(start.glass.isEmpty)
        #expect(start.mark?.center == canvas.center)
        let end = motion.exitFrame(from: rest, at: 0, progress: 1)
        #expect(end.glass.count == 1)
        #expect(end.glass[0].id == GlassSeed.pieceID)
        #expect(end.glass[0].path.boundingRect == canvas.seed.rect)
        #expect(end.mark == nil)
    }

    @Test func leavingRestsThenTravelsAndFadesItsDetail() throws {
        let canvas = context.canvas
        let rest = motion.frame(at: 0, interaction: IntroInteraction())
        let early = motion.exitFrame(from: rest, at: 0, progress: 0.3)
        #expect(early.mark?.center == canvas.center)
        let middle = motion.exitFrame(from: rest, at: 0, progress: 0.6)
        let mark = try #require(middle.mark)
        #expect(mark.center.y < canvas.center.y)
        #expect(mark.detail < 1)
    }

    @Test func leavingNeverJumps() async {
        let canvas = context.canvas
        let motion = motion
        let rest = motion.frame(at: 0, interaction: IntroInteraction())
        let check = ContinuityCheck(canvas: canvas) { time in
            motion.exitFrame(from: rest, at: 0, progress: time / LaunchMotion.leaveDuration)
        }
        let faults = await check.faults(from: 0, to: LaunchMotion.leaveDuration + 0.2)
        #expect(faults.isEmpty, "\(faults.prefix(4))")
    }
}
