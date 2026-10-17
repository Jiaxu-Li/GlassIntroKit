//===--- MarkMotion.swift - GlassIntroKit -----------------------------------===//
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

/// The mark in glass, its detail opening.
///
/// Carrying on from the word, the word is taken back into a point that
/// grows into the mark. From anywhere else the mark grows out of the seed,
/// which already is its body.
nonisolated struct MarkMotion: PageMotion {
    let context: IntroContext
    private let route: Route

    private enum Route: Sendable {
        case turn(MarkTurn)
        case bloom(MarkBloom)
    }

    static func continues(from handoff: IntroHandoff) -> Bool {
        if case .word = handoff {
            return true
        }
        return false
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
        if case .handoff(.word) = entry {
            route = .turn(MarkTurn(canvas: context.canvas))
        } else {
            route = .bloom(MarkBloom(canvas: context.canvas))
        }
    }

    var settleTime: Double {
        switch route {
        case .turn:
            MarkTurn.end
        case .bloom:
            MarkBloom.end
        }
    }

    var textTime: Double {
        switch route {
        case .turn:
            MarkTurn.textStart
        case .bloom:
            MarkBloom.textStart
        }
    }

    /// The seed is the mark's own body, so the mark grows from it in place.
    var absorbsSeed: Bool {
        if case .bloom = route {
            return true
        }
        return false
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        let glass: GlassFrame
        let layout: HelloLayout
        switch route {
        case .turn(let turn):
            glass = turn.glassFrame(at: time)
            layout = turn.layout
        case .bloom(let bloom):
            glass = bloom.glassFrame(at: time)
            layout = bloom.layout
        }
        let canvas = context.canvas
        let path = glass.path(layout: layout, markDimension: canvas.markDimension, context: context)
        return IntroFrame(glass: [GlassPiece(id: "main", path: path)])
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .mark
    }
}
