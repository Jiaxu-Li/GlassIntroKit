//===--- MarkMotionTests.swift - GlassIntroKit ------------------------------===//
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

/// The word at rest, standing in for the greeting picture: it offers the
/// word to carry on from.
private struct WordProbe: IntroMotion {
    let context: IntroContext
    var settleTime: Double { 0 }
    var textTime: Double { 0 }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        let path = GlassFrame.written(through: 1).path(
            layout: HelloLayout.resting(in: context.canvas),
            markDimension: context.canvas.markDimension,
            context: context
        )
        return IntroFrame(glass: [GlassPiece(id: "main", path: path)])
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .word
    }
}

/// The mark in glass: how it comes in from the word and from the seed, and
/// that both leave it the same.
@Suite struct MarkMotionTests {
    private let canvas = IntroCanvas(size: CGSize(width: 1200, height: 800), bodyDiameterRatio: 0.76)
    private let interaction = IntroInteraction()

    /// A context whose mark cuts a small square out of its body.
    private var context: IntroContext {
        IntroContext(
            canvas: canvas,
            markOutline: GlassIntroMarkOutline.symbol("star.fill"),
            outlines: ["star.fill": Path(CGRect(x: -0.5, y: -0.5, width: 1, height: 1))],
            page: 1,
            symbols: [],
            centerSymbol: nil,
            markSymbol: "star.fill",
            words: [],
            textTop: 560
        )
    }

    private var fromWord: MarkMotion {
        MarkMotion(entry: .handoff(.word), context: context)
    }

    private var fromSeed: MarkMotion {
        MarkMotion(entry: .seed, context: context)
    }

    private func outline(_ motion: MarkMotion, at time: Double) -> Path {
        motion.frame(at: time, interaction: interaction).glass.first?.path ?? Path()
    }

    @Test func continuesOnlyFromTheWord() {
        #expect(MarkMotion.continues(from: .word))
        #expect(!MarkMotion.continues(from: .launch))
        #expect(!MarkMotion.continues(from: .mark))
        #expect(!MarkMotion.continues(from: .scene(yaw: 0)))
        #expect(!MarkMotion.continues(from: .symbols(scatter: [], center: nil)))
        #expect(!MarkMotion.continues(from: .other))
    }

    @Test func timingFollowsTheEntry() {
        #expect(fromWord.settleTime == 2.0)
        #expect(fromWord.textTime == 1.5)
        #expect(!fromWord.absorbsSeed)
        #expect(fromSeed.settleTime == 1.0)
        #expect(fromSeed.textTime == 0.5)
        #expect(fromSeed.absorbsSeed)
    }

    @Test func seedEntryStartsAsTheSeed() throws {
        let seed = canvas.seed
        let frame = fromSeed.frame(at: 0, interaction: interaction)
        let piece = try #require(frame.glass.first)
        #expect(frame.glass.count == 1)
        let bounds = piece.path.boundingRect
        #expect(abs(bounds.midX - seed.center.x) < 0.01)
        #expect(abs(bounds.midY - seed.center.y) < 0.01)
        #expect(abs(bounds.width - seed.diameter) < 0.01)
        #expect(abs(bounds.height - seed.diameter) < 0.01)
        // A plain round body: nothing cut out of it yet.
        #expect(piece.path.contains(seed.center))
    }

    @Test func wordEntryStartsAsTheWordAtRest() throws {
        let layout = HelloLayout.resting(in: canvas)
        let bounds = try #require(fromWord.frame(at: 0, interaction: interaction).glass.first).path.boundingRect
        let word = GlassFrame.written(through: 1).path(
            layout: layout,
            markDimension: canvas.markDimension,
            context: context
        ).boundingRect
        #expect(bounds == word)
    }

    @Test func bothEntriesComeToTheSameRest() {
        let a = outline(fromWord, at: fromWord.settleTime).boundingRect
        let b = outline(fromSeed, at: fromSeed.settleTime).boundingRect
        let full = canvas.markDimension * canvas.bodyDiameterRatio
        #expect(abs(a.width - full) < 0.001)
        #expect(abs(a.midX - canvas.graphicCenter.x) < 0.001)
        #expect(abs(a.midY - canvas.graphicCenter.y) < 0.001)
        #expect(abs(a.minX - b.minX) < 0.001)
        #expect(abs(a.minY - b.minY) < 0.001)
        #expect(abs(a.width - b.width) < 0.001)
        #expect(abs(a.height - b.height) < 0.001)
    }

    @Test func detailIsOpenAtRestAndClosedBefore() {
        for motion in [fromWord, fromSeed] {
            let center = canvas.graphicCenter
            #expect(!outline(motion, at: motion.settleTime).contains(center))
            #expect(!outline(motion, at: motion.settleTime + 3).contains(center))
        }
        #expect(outline(fromSeed, at: 0).contains(canvas.graphicCenter))
        #expect(outline(fromWord, at: MarkTurn.apertureStart).contains(canvas.graphicCenter))
    }

    @Test func framesAfterRestStayAtRest() {
        for motion in [fromWord, fromSeed] {
            let rest = outline(motion, at: motion.settleTime).boundingRect
            for extra in [0.2, 1, 10, 1000] {
                #expect(outline(motion, at: motion.settleTime + extra).boundingRect == rest)
            }
        }
    }

    @Test func everyFrameIsFiniteAndOnePiece() {
        for motion in [fromWord, fromSeed] {
            for step in 0...120 {
                let time = Double(step) * 0.025
                let frame = motion.frame(at: time, interaction: interaction)
                #expect(frame.glass.count == 1)
                #expect(frame.glass.first?.id == "main")
                let bounds = frame.glass.first?.path.boundingRect ?? .null
                #expect(bounds.minX.isFinite && bounds.maxX.isFinite)
                #expect(bounds.minY.isFinite && bounds.maxY.isFinite)
            }
        }
    }

    @Test func handsTheMarkOn() {
        for motion in [fromWord, fromSeed] {
            guard case .mark = motion.handoff(at: motion.settleTime, interaction: interaction) else {
                Issue.record("expected a mark handoff")
                return
            }
        }
    }

    @Test func growthSettlesExactly() {
        #expect(MarkTurn.growth(at: MarkTurn.growthStart) == 0)
        #expect(MarkTurn.growth(at: MarkTurn.end) == 1)
        #expect(MarkTurn.growth(at: 50) == 1)
        #expect(MarkBloom.pulse(at: 0) == 0)
        #expect(MarkBloom.pulse(at: MarkBloom.end) == 0)
    }

    // MARK: Continuity

    /// The player turning from the word to the mark at `turn`, then on to a
    /// picture that shares nothing with it at `leave`, if given.
    private func player(leaving leave: Double?) -> WelcomePlayer {
        let context = context
        var player = WelcomePlayer(resting: WordProbe(context: context))
        player.turn(
            at: 0,
            interaction: interaction,
            continues: MarkMotion.continues(from:),
            build: { MarkMotion(entry: $0, context: context) }
        )
        if let leave {
            player.turn(
                at: leave,
                interaction: interaction,
                continues: { _ in false },
                build: { _ in SeedMotion(context: context) }
            )
        }
        return player
    }

    @Test func turningFromTheWordNeverJumps() async {
        let canvas = canvas
        let player = player(leaving: nil)
        let check = ContinuityCheck(canvas: canvas) { player.frame(at: $0, interaction: IntroInteraction()) }
        let faults = await check.faults(from: 0, to: 3)
        #expect(faults.isEmpty, "the word turning into the mark: \(faults.prefix(4))")
    }

    @Test(arguments: [0.4, 1.0, 1.25, 1.6, 2.0, 2.7])
    func leavingTheMarkNeverJumps(leave: Double) async {
        let canvas = canvas
        let player = player(leaving: leave)
        let check = ContinuityCheck(canvas: canvas) { player.frame(at: $0, interaction: IntroInteraction()) }
        let faults = await check.faults(from: 0, to: leave + 2.5)
        #expect(faults.isEmpty, "the mark left at \(leave)s: \(faults.prefix(4))")
    }

    @Test(arguments: [0.0, 0.2, 0.5, 1.5])
    func leavingTheSeedGrownMarkNeverJumps(leave: Double) async {
        let context = context
        let canvas = canvas
        var player = WelcomePlayer(resting: SeedMotion(context: context))
        player.turn(
            at: 0,
            interaction: interaction,
            continues: { _ in false },
            build: { MarkMotion(entry: $0, context: context) }
        )
        player.turn(
            at: leave,
            interaction: interaction,
            continues: { _ in false },
            build: { _ in SeedMotion(context: context) }
        )
        let snapshot = player
        let check = ContinuityCheck(canvas: canvas) { snapshot.frame(at: $0, interaction: IntroInteraction()) }
        let faults = await check.faults(from: 0, to: leave + 3)
        #expect(faults.isEmpty, "the seed-grown mark left at \(leave)s: \(faults.prefix(4))")
    }
}
