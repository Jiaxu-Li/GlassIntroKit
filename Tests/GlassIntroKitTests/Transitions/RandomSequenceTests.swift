//===--- RandomSequenceTests.swift - GlassIntroKit --------------------------===//
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

/// Welcomes of every shape: random pages in random order, each turned at a
/// random time. None may jump or produce an outline that is not a number.
@Suite struct RandomSequenceTests {
    /// A repeatable sequence of random numbers.
    struct Generator: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    @Test(arguments: 1...12)
    func randomWelcomeNeverJumps(seed: Int) async {
        let outlines = await TestOutlines.all()
        var generator = Generator(state: UInt64(seed))
        let count = Int.random(in: 1...6, using: &generator)
        let visuals = (0..<count).map { _ in GlassIntroPage.Visual.allCases.randomElement(using: &generator)! }
        let delays = (0...count + 1).map { _ in Double.random(in: 0...2.5, using: &generator) }
        let compact = Bool.random(using: &generator)
        let run = WelcomeRun(
            pages: visuals.map(TestPages.page),
            size: compact ? CGSize(width: 430, height: 900) : CGSize(width: 1280, height: 820),
            outlines: outlines,
            delay: { delays[min($0, delays.count - 1)] }
        )
        let faults = await run.continuity.faults(from: 0, to: run.end)
        #expect(faults.isEmpty, "\(visuals), delays \(delays): \(faults.prefix(4))")
    }

    @Test func reduceMotionSettlesEveryPageAtOnce() async {
        let outlines = await TestOutlines.all()
        let run = WelcomeRun(
            pages: GlassIntroPage.Visual.allCases.map(TestPages.page),
            reducesMotion: true,
            outlines: outlines
        )
        for turn in run.turnTimes {
            let check = run.continuity
            #expect(check.invalidFrames(from: turn, to: turn + 0.5).isEmpty)
        }
    }
}
