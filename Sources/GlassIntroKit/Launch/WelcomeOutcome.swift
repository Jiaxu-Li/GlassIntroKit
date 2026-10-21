//===--- WelcomeOutcome.swift - GlassIntroKit -------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

/// How a welcome that started playing came to an end, and so whether it
/// counts as seen.
///
/// The person's own choices count: playing it through, or skipping it. An
/// interruption doesn't: if the app is quit or its window closed before
/// either, the welcome plays again the next time it would.
nonisolated enum WelcomeOutcome: Equatable, Sendable {
    /// The last page's button was pressed and the ending played.
    case finished
    /// The Skip button, Escape on a Mac, or the VoiceOver escape gesture.
    case skipped
    /// The intro's view went away before the welcome ended: its window
    /// closed, or the view was removed.
    case interrupted

    /// Whether the welcome is recorded as seen.
    var recordsWelcome: Bool {
        switch self {
        case .finished, .skipped:
            true
        case .interrupted:
            false
        }
    }
}

extension GlassIntro {
    /// Records how the welcome ended in the intro's storage.
    func record(_ outcome: WelcomeOutcome) {
        if outcome.recordsWelcome {
            storage.hasSeenWelcome = true
        }
    }
}
