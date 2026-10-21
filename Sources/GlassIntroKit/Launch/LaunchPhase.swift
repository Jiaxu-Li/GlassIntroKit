//===--- LaunchPhase.swift - GlassIntroKit ----------------------------------===//
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

/// The launch sequence: a tinted stage fills the window while its
/// construction drawing plays, the stage shrinks into the round mark over
/// the frosted content, the window toolbar returns while the mark rests,
/// and the mark travels to where the app shows it.
nonisolated enum LaunchPresentationPhase: Int, CaseIterable, Sendable {
    case background
    case construction
    case logo
    case settling
    case handoffApproach
    case handoff
    case complete
}

nonisolated struct LaunchWorkspacePresentation: Equatable, Sendable {
    let phase: LaunchPresentationPhase
    let reducesMotion: Bool
    /// With Reduce Transparency on, nothing behind the window shows
    /// through: the mark rests on a solid surface instead of frosted glass.
    var reducesTransparency = false

    /// The solid surface that hides the workspace until the stage closes.
    var workspaceCoverOpacity: Double {
        phase.rawValue >= LaunchPresentationPhase.logo.rawValue ? 0 : 1
    }

    /// Whether the surface the mark rests on is solid rather than frosted
    /// glass.
    var restsOnSolidSurface: Bool {
        reducesTransparency
    }

    /// The surface the mark rests on, frosted glass or solid: the workspace
    /// is already in place beneath it, and it clears as the mark dissolves.
    var frostedGlassOpacity: Double {
        guard !reducesMotion else {
            return 0
        }
        return phase == .logo || phase == .settling ? 1 : 0
    }

    /// The window's title and toolbar stay out of the way while the intro
    /// plays, and return under the frosted glass, before the app is
    /// revealed, so the app's layout has settled by then.
    var hidesWindowChrome: Bool {
        let returns: LaunchPresentationPhase = reducesMotion ? .handoff : .settling
        return phase.rawValue < returns.rawValue
    }

    var isWorkspaceAvailable: Bool {
        reducesMotion
            ? phase.rawValue >= LaunchPresentationPhase.handoff.rawValue
            : phase == .complete
    }

    var workspaceOpacity: Double {
        if reducesMotion {
            return phase == .background ? 0 : 1
        }
        switch phase {
        case .background, .construction:
            return 0
        case .logo, .settling, .handoffApproach, .handoff, .complete:
            return 1
        }
    }

    var workspaceBlurRadius: CGFloat {
        reducesMotion && phase == .background ? 4 : 0
    }
}

nonisolated extension OpeningStageProperties {
    /// The values the live sequence has reached by the end of `phase`.
    static func settled(at phase: LaunchPresentationPhase) -> Self {
        guard phase != .background else {
            return Self()
        }
        var properties = Self.closed
        let isClosed = phase.rawValue >= LaunchPresentationPhase.logo.rawValue
        properties.whitensStage = isClosed
        properties.convertToLogo = isClosed
        properties.dissolvesMark =
            phase.rawValue >= LaunchPresentationPhase.handoffApproach.rawValue
        return properties
    }
}
