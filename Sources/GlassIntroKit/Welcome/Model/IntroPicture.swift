//===--- IntroPicture.swift - GlassIntroKit ---------------------------------===//
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

/// A picture the welcome can turn to: built from where it starts, and
/// knowing which pictures it carries straight on from.
nonisolated protocol PageMotion: IntroMotion {
    /// Whether the picture carries straight on from what the picture before
    /// offers at rest. When it does not, the two meet at the seed.
    static func continues(from handoff: IntroHandoff) -> Bool
    /// Whether the picture shows nothing of its own at first, so the one
    /// before dissolves where it is rather than gathering into the seed.
    static var arrivesEmpty: Bool { get }
    init(entry: IntroEntry, context: IntroContext)
}

nonisolated extension PageMotion {
    static var arrivesEmpty: Bool {
        false
    }
}

/// Every picture the welcome shows.
nonisolated enum IntroPicture: Equatable, Sendable {
    /// The mark in colour, as the launch hands it over.
    case launch
    case page(GlassIntroPage.Visual)
    /// The last page, which asks to begin: nothing but its light.
    case rest
    /// The ending: the words, and the mark filling with colour.
    case finale

    var motionType: any PageMotion.Type {
        switch self {
        case .launch:
            LaunchMotion.self
        case .page(.greeting):
            GreetingMotion.self
        case .page(.mark):
            MarkMotion.self
        case .page(.symbols):
            SymbolsMotion.self
        case .page(.scene):
            SceneMotion.self
        case .page(.graph):
            GraphMotion.self
        case .page(.physics):
            PhysicsMotion.self
        case .page(.icon):
            IconMotion.self
        case .page(.card):
            CardMotion.self
        case .rest:
            RestMotion.self
        case .finale:
            FinaleMotion.self
        }
    }

    func continues(from handoff: IntroHandoff) -> Bool {
        motionType.continues(from: handoff)
    }

    var arrivesEmpty: Bool {
        motionType.arrivesEmpty
    }

    func motion(entry: IntroEntry, context: IntroContext) -> any IntroMotion {
        motionType.init(entry: entry, context: context)
    }
}
