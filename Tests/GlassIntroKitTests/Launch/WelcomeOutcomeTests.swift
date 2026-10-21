//===--- WelcomeOutcomeTests.swift - GlassIntroKit --------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import Testing
@testable import GlassIntroKit

/// What counts as having seen the welcome.
@Suite @MainActor struct WelcomeOutcomeTests {
    private func intro(_ defaults: UserDefaults) -> GlassIntro {
        GlassIntro(
            appName: "Orbit",
            pages: [.greeting("A", message: "a")],
            storage: GlassIntroStorage(defaults: defaults)
        )
    }

    private func withDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let suite = "GlassIntroKitTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    @Test func playingItThroughOrSkippingCountsAsSeen() throws {
        for outcome in [WelcomeOutcome.finished, .skipped] {
            try withDefaults { defaults in
                let intro = intro(defaults)
                #expect(intro.isWelcomePending)
                intro.record(outcome)
                #expect(!intro.isWelcomePending, "\(outcome)")
            }
        }
    }

    @Test func anInterruptionPlaysItAgain() throws {
        try withDefaults { defaults in
            let intro = intro(defaults)
            intro.record(.interrupted)
            #expect(intro.isWelcomePending)
        }
    }

    /// The app is quit mid-welcome: nothing was recorded, so the next
    /// process, with a fresh launch state, plays the whole intro again.
    @Test func aQuitMidWelcomePlaysItAllAtTheNextLaunch() throws {
        try withDefaults { defaults in
            let firstProcess = LaunchProcessState()
            #expect(firstProcess.claimSequence(isAnimationEnabled: intro(defaults).isWelcomePending) == .full)
            // Quit here: neither recorded nor completed.

            let nextProcess = LaunchProcessState()
            let intro = intro(defaults)
            #expect(intro.isWelcomePending)
            #expect(nextProcess.claimSequence(isAnimationEnabled: intro.isWelcomePending) == .full)
        }
    }

    /// Once seen, a later launch plays only the short launch, or nothing
    /// when that is turned off.
    @Test func aSeenWelcomeDoesNotReturn() throws {
        try withDefaults { defaults in
            intro(defaults).record(.skipped)
            var intro = intro(defaults)
            intro.playsLaunchAnimation = false
            let process = LaunchProcessState()
            #expect(process.claimSequence(isAnimationEnabled: intro.playsLaunchAnimation || intro.isWelcomePending) == .immediate)
        }
    }
}
