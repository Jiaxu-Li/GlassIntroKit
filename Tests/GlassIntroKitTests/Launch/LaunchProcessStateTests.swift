//===--- LaunchProcessStateTests.swift - GlassIntroKit ----------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import Testing
@testable import GlassIntroKit

@Suite struct LaunchProcessStateTests {
    @Test func onlyTheFirstClaimPlaysTheLaunch() {
        let state = LaunchProcessState()
        #expect(state.wouldPresentSequence(isAnimationEnabled: true))
        #expect(state.claimSequence() == .full)
        #expect(state.claimSequence() == .immediate)
        state.completeSequence()
        #expect(state.claimSequence() == .immediate)
        #expect(!state.wouldPresentSequence(isAnimationEnabled: true))
    }

    @Test func aClosedWindowGivesTheLaunchToTheNextOne() {
        let state = LaunchProcessState()
        #expect(state.claimSequence() == .full)
        // The window closes mid-intro: the next window plays it from the start.
        state.abandonSequence()
        #expect(state.claimSequence() == .full)
        // Once played through, closing a window gives nothing back.
        state.completeSequence()
        state.abandonSequence()
        #expect(state.claimSequence() == .immediate)
    }

    @Test func abandoningWithoutAClaimChangesNothing() {
        let state = LaunchProcessState()
        state.abandonSequence()
        #expect(state.claimSequence() == .full)
        let turnedOff = LaunchProcessState()
        #expect(turnedOff.claimSequence(isAnimationEnabled: false) == .immediate)
        turnedOff.abandonSequence()
        #expect(turnedOff.claimSequence() == .immediate)
    }

    @Test func turnedOffAnimationSettlesAtOnce() {
        let state = LaunchProcessState()
        #expect(!state.wouldPresentSequence(isAnimationEnabled: false))
        #expect(state.claimSequence(isAnimationEnabled: false) == .immediate)
        #expect(state.claimSequence(isAnimationEnabled: true) == .immediate)
    }
}
