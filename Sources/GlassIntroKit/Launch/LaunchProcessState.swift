//===--- LaunchProcessState.swift - GlassIntroKit ---------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

/// Whether this process has played its launch. Only the first window that
/// asks plays it; every later window opens as the launch left the first.
@MainActor
final class LaunchProcessState {
    static let shared = LaunchProcessState()

    private enum Status {
        case ready
        case presenting
        case completed
    }

    private var status = Status.ready

    func claimSequence(isAnimationEnabled: Bool = true) -> LaunchSequenceMode {
        guard status == .ready else {
            return .immediate
        }
        guard isAnimationEnabled else {
            status = .completed
            return .immediate
        }
        status = .presenting
        return .full
    }

    /// Whether `claimSequence(isAnimationEnabled:)` would present the full
    /// sequence, without claiming it.
    func wouldPresentSequence(isAnimationEnabled: Bool) -> Bool {
        status == .ready && isAnimationEnabled
    }

    func completeSequence() {
        status = .completed
    }

    /// Gives up a sequence that was claimed but never finished, as when its
    /// window closes mid-intro, so the next window to ask plays it from the
    /// start.
    func abandonSequence() {
        guard status == .presenting else {
            return
        }
        status = .ready
    }
}

/// How a window presents the launch: played in full, or settled at once.
nonisolated enum LaunchSequenceMode: Int, Equatable, Sendable {
    case full
    case immediate
}
