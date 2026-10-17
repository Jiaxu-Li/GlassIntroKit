//===--- WelcomeRun.swift - GlassIntroKit -----------------------------------===//
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
@testable import GlassIntroKit

/// A whole welcome played without a window, as `WelcomeView` plays it: the
/// launch, each page turned some time after its text comes in, the last
/// page, and the ending.
nonisolated struct WelcomeRun: Sendable {
    /// The player after each turn, and when that turn was made.
    private(set) var snapshots: [(clock: Double, player: WelcomePlayer)] = []
    /// When each turn was made.
    var turnTimes: [Double] {
        snapshots.map(\.clock)
    }
    let canvas: IntroCanvas
    let interaction: IntroInteraction
    /// When the last page is at rest, and when the ending is over.
    private(set) var readyEnd: Double = 0
    private(set) var end: Double = 0

    /// Plays `pages`, turning each page `delay(index)` seconds after its text
    /// comes in.
    @MainActor
    init(
        pages: [GlassIntroPage],
        mark: GlassIntroMark = .symbol("globe.americas.fill"),
        finale: [String]? = nil,
        size: CGSize = CGSize(width: 1200, height: 800),
        reducesMotion: Bool = false,
        outlines: [String: Path],
        delay: (Int) -> Double = { _ in 0 }
    ) {
        let content = WelcomeContent(GlassIntro(appName: "Orbit", mark: mark, pages: pages, finale: finale))
        canvas = IntroCanvas(size: size, bodyDiameterRatio: mark.bodyDiameterRatio)
        interaction = IntroInteraction(reducesMotion: reducesMotion)
        let canvas = canvas
        func context(_ index: Int) -> IntroContext {
            content.context(page: index, canvas: canvas, outlines: outlines, textTop: nil)
        }

        var player = WelcomePlayer(resting: LaunchMotion(entry: .seed, context: context(0)))
        var clock = 0.0
        for index in 0...content.pageCount {
            // The pages, the last page, then the ending.
            let picture: IntroPicture = index < content.pageCount ? content.picture(at: index) : .finale
            let pictureContext = context(index)
            let turn = player.turn(
                at: clock,
                interaction: interaction,
                continues: picture.continues(from:),
                arrivesEmpty: picture.arrivesEmpty,
                build: { entry in picture.motion(entry: entry, context: pictureContext) }
            )
            snapshots.append((clock, player))
            if index == content.readyIndex {
                readyEnd = turn.settleTime
            }
            clock = max(turn.textTime, clock) + delay(index)
            end = max(turn.settleTime, clock)
        }
    }

    /// The frame at `clock`, from the player as it was then.
    func frame(at clock: Double) -> IntroFrame {
        let snapshot = snapshots.last { $0.clock <= clock } ?? snapshots[0]
        return snapshot.player.frame(at: clock, interaction: interaction)
    }

    var continuity: ContinuityCheck {
        let run = self
        return ContinuityCheck(canvas: canvas) { run.frame(at: $0) }
    }
}

/// Traced outlines for every symbol the tests use, traced once.
@MainActor
enum TestOutlines {
    private static var cached: [String: Path]?

    static func all() async -> [String: Path] {
        if let cached {
            return cached
        }
        let names = ["globe.americas.fill", "star.fill", "leaf.fill", "bolt.fill"]
            + GlassIntroPage.defaultScatterSymbols
        let outlines = await SymbolOutlines.outlines(for: names)
        cached = outlines
        return outlines
    }
}

/// One page of every picture, for tests.
@MainActor
enum TestPages {
    static func page(_ visual: GlassIntroPage.Visual) -> GlassIntroPage {
        switch visual {
        case .card:
            .card("Card", message: "A view of your own.") {
                Text(verbatim: "Card")
            }
        default:
            GlassIntroPage(visual, title: Text(verbatim: "Title"), message: Text(verbatim: "Message"))
        }
    }
}
