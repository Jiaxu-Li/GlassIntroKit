//===--- TransitionContinuityTests.swift - GlassIntroKit --------------------===//
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

/// Every picture after every other, turned as soon as allowed and long
/// after: the picture never jumps, and every outline stays finite.
@Suite struct TransitionContinuityTests {
    nonisolated static let pairs: [(GlassIntroPage.Visual, GlassIntroPage.Visual)] = GlassIntroPage.Visual.allCases.flatMap { first in
        GlassIntroPage.Visual.allCases.map { (first, $0) }
    }

    @Test(arguments: pairs)
    func pairNeverJumps(_ first: GlassIntroPage.Visual, _ second: GlassIntroPage.Visual) async {
        let outlines = await TestOutlines.all()
        for delay in [0.0, 1.7] {
            let run = WelcomeRun(
                pages: [TestPages.page(first), TestPages.page(second)],
                outlines: outlines,
                delay: { _ in delay }
            )
            let faults = await run.continuity.faults(from: 0, to: run.readyEnd)
            #expect(faults.isEmpty, "\(first) → \(second), turned \(delay)s after the text: \(faults.prefix(4))")
        }
    }

    @Test(arguments: GlassIntroPage.Visual.allCases)
    func pictureNeverJumpsOnAPhone(_ visual: GlassIntroPage.Visual) async {
        let outlines = await TestOutlines.all()
        let run = WelcomeRun(
            pages: [TestPages.page(visual), TestPages.page(visual)],
            size: CGSize(width: 390, height: 844),
            outlines: outlines
        )
        let faults = await run.continuity.faults(from: 0, to: run.readyEnd)
        #expect(faults.isEmpty, "\(visual) twice on a phone: \(faults.prefix(4))")
    }

    @Test(arguments: [[], ["Have a", "good trip"], ["A rather long line of words", "and another", "Orbit", "past three"]])
    func endingOfAnyWordsNeverJumps(words: [String]) async {
        let outlines = await TestOutlines.all()
        for size in [CGSize(width: 1200, height: 800), CGSize(width: 390, height: 844)] {
            let run = WelcomeRun(pages: [TestPages.page(.mark)], finale: words, size: size, outlines: outlines, delay: { _ in 0.5 })
            let faults = await run.continuity.faults(from: run.readyEnd, to: run.end)
            #expect(faults.isEmpty, "\(words) on \(size): \(faults.prefix(4))")
        }
    }

    @Test func endingNeverJumps() async {
        let outlines = await TestOutlines.all()
        let run = WelcomeRun(pages: [TestPages.page(.icon)], outlines: outlines, delay: { _ in 0.5 })
        let faults = await run.continuity.faults(from: run.readyEnd, to: run.end)
        #expect(faults.isEmpty, "the ending: \(faults.prefix(4))")
    }
}
