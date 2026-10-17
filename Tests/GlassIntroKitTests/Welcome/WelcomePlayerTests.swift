//===--- WelcomePlayerTests.swift - GlassIntroKit ---------------------------===//
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

/// A picture with fixed timing, which carries on from `accepts`.
private struct ProbeMotion: PageMotion {
    let context: IntroContext
    let entry: IntroEntry
    var settleTime: Double { 2 }
    var textTime: Double { 1 }

    static func continues(from handoff: IntroHandoff) -> Bool {
        if case .mark = handoff {
            return true
        }
        return false
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.entry = entry
        self.context = context
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        IntroFrame(glass: [GlassPiece(id: "probe", path: Path(CGRect(x: 0, y: 0, width: 10 + time, height: 10)))])
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .mark
    }
}

@Suite struct WelcomePlayerTests {
    private let context = IntroContext(
        canvas: IntroCanvas(size: CGSize(width: 1200, height: 800), bodyDiameterRatio: 0.76),
        markOutline: GlassIntroMarkOutline.symbol("star.fill"),
        outlines: [:],
        page: 0,
        symbols: [],
        centerSymbol: nil,
        markSymbol: nil,
        words: [],
        textTop: 560
    )

    private func player() -> WelcomePlayer {
        WelcomePlayer(resting: ProbeMotion(entry: .seed, context: context))
    }

    private func turn(_ player: inout WelcomePlayer, at clock: Double, continues: Bool, reducesMotion: Bool = false) -> WelcomePlayer.Turn {
        let context = context
        return player.turn(
            at: clock,
            interaction: IntroInteraction(reducesMotion: reducesMotion),
            continues: { _ in continues },
            build: { ProbeMotion(entry: $0, context: context) }
        )
    }

    @Test func carriesStraightOnOnceThePictureBeforeIsAtRest() {
        var player = player()
        _ = turn(&player, at: 0, continues: true)
        // Turned before the new picture is at rest: it waits for its rest.
        let turn = turn(&player, at: 1, continues: true)
        #expect(player.current.start == 2)
        #expect(turn.textTime == 3)
        #expect(turn.settleTime == 4)
        if case .handoff(.mark) = player.current.entry {} else {
            Issue.record("expected the picture to carry on from the mark")
        }
    }

    @Test func meetsAtTheSeedOtherwise() {
        var player = player()
        _ = turn(&player, at: 0, continues: true)
        let turn = turn(&player, at: 5, continues: false)
        #expect(player.current.start == 5 + IntroFrame.collapseDuration)
        #expect(turn.settleTime == 5 + IntroFrame.collapseDuration + 2)
        // Halfway, the picture before is gathering into the seed.
        let frame = player.frame(at: 5 + IntroFrame.collapseDuration / 2, interaction: IntroInteraction())
        #expect(frame.glass.contains { $0.id == GlassSeed.pieceID })
        // At the turn's end, the seed is all there is, at full size.
        let joined = player.frame(at: 5 + IntroFrame.collapseDuration - 0.0001, interaction: IntroInteraction())
        #expect(joined.glass.contains { $0.id == GlassSeed.pieceID })
    }

    @Test func waitsNoLongerThanItShould() {
        var player = player()
        _ = turn(&player, at: 0, continues: false)
        // The picture is far from rest; carrying on would mean a long wait.
        _ = turn(&player, at: 0.2, continues: true)
        if case .seed = player.current.entry {} else {
            Issue.record("expected the two to meet at the seed")
        }
    }

    @Test func turnsMadeInQuickSuccessionFollowOn() {
        var player = player()
        _ = turn(&player, at: 3, continues: false)
        let first = player.current.start
        _ = turn(&player, at: 3.1, continues: false)
        #expect(player.current.start > first)
        // The picture on screen between the turns is still the first one
        // gathering into the seed.
        let frame = player.frame(at: 3.5, interaction: IntroInteraction())
        #expect(frame.glass.contains { $0.id == GlassSeed.pieceID })
    }

    @Test func reduceMotionTurnsStraightToRest() {
        var player = player()
        let turn = turn(&player, at: 4, continues: false, reducesMotion: true)
        #expect(turn.textTime == 4)
        #expect(player.current.start == 2)
        #expect(!player.isMoving(at: 4, interaction: IntroInteraction(reducesMotion: true)))
    }

    @Test func collapsingEndsAsTheSeedAlone() {
        let canvas = context.canvas
        let frame = IntroFrame(
            glass: [GlassPiece(id: "word", path: Path(CGRect(x: 100, y: 100, width: 400, height: 80)))],
            symbols: [SymbolSprite(id: "s", name: "star.fill", center: CGPoint(x: 900, y: 100), size: 40)],
            scene: SceneSprite(lensDiameter: nil, lensCenter: canvas.graphicCenter, cubeCenter: CGPoint(x: 0.5, y: 0.36), level: 1, sweep: 2, yaw: 0)
        )
        let end = frame.collapsed(into: canvas.seed, progress: 1, canvas: canvas)
        #expect(end.glass.count == 1)
        #expect(end.glass[0].path.boundingRect == canvas.seed.rect)
        #expect(end.symbols.isEmpty && end.scene == nil)
        let start = frame.collapsed(into: canvas.seed, progress: 0, canvas: canvas)
        #expect(start.glass.first?.path.boundingRect == frame.glass[0].path.boundingRect)
    }
}
