//===--- GraphMotionTests.swift - GlassIntroKit -----------------------------===//
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

/// The live scene at rest, as the page before the graph leaves it: the
/// whole canvas, one level past the last sweep, the cube held at a yaw.
private struct RestingSceneProbe: IntroMotion {
    let context: IntroContext
    let yaw: Float

    var settleTime: Double { 1 }
    var textTime: Double { 0 }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        let canvas = context.canvas
        return IntroFrame(scene: SceneSprite(
            lensDiameter: canvas.coveringDiameter(around: canvas.graphicCenter),
            lensCenter: canvas.graphicCenter,
            cubeCenter: CGPoint(x: 0.5, y: IntroCanvas.graphicHeight),
            level: Float(SceneReveal.firstLevel + SceneReveal.sweepCount),
            sweep: 2,
            yaw: yaw
        ))
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .scene(yaw: yaw)
    }
}

@Suite struct GraphMotionTests {
    nonisolated private static let wide = CGSize(width: 1200, height: 800)
    nonisolated private static let phone = CGSize(width: 390, height: 844)

    private static func context(size: CGSize = wide, symbols: [String] = GlassIntroPage.defaultNodeSymbols) -> IntroContext {
        IntroContext(
            canvas: IntroCanvas(size: size, bodyDiameterRatio: 0.76),
            markOutline: GlassIntroMarkOutline.symbol("star.fill"),
            outlines: [:],
            page: 3,
            symbols: symbols,
            centerSymbol: nil,
            markSymbol: nil,
            words: [],
            textTop: size.height * 0.7
        )
    }

    private static func fromScene(_ context: IntroContext, yaw: Float = 1.25) -> GraphMotion {
        GraphMotion(entry: .handoff(.scene(yaw: yaw)), context: context)
    }

    private static func fromSeed(_ context: IntroContext) -> GraphMotion {
        GraphMotion(entry: .seed, context: context)
    }

    @Test func continuesOnlyFromTheScene() {
        #expect(GraphMotion.continues(from: .scene(yaw: 0.4)))
        #expect(!GraphMotion.continues(from: .launch))
        #expect(!GraphMotion.continues(from: .word))
        #expect(!GraphMotion.continues(from: .mark))
        #expect(!GraphMotion.continues(from: .symbols(scatter: [], center: nil)))
        #expect(!GraphMotion.continues(from: .graph(GraphFrame())))
        #expect(!GraphMotion.continues(from: .fallen(PhysicsFrame())))
        #expect(!GraphMotion.continues(from: .other))
    }

    @Test func timesFollowTheReveal() {
        let context = Self.context()
        let direct = Self.fromScene(context)
        // The default graph has two columns.
        let end = GraphReveal.nodeStart(column: 1) + GraphReveal.nodeSettle
        #expect(direct.settleTime == end)
        #expect(direct.textTime == GraphReveal.textStart)
        // From the seed the scene's closing is skipped.
        let seeded = Self.fromSeed(context)
        #expect(abs(seeded.settleTime - (end - GraphReveal.shrinkStart)) < 1e-9)
        #expect(abs(seeded.textTime - (GraphReveal.textStart - GraphReveal.shrinkStart)) < 1e-9)
        #expect(seeded.textTime < seeded.settleTime)
        #expect(seeded.absorbsSeed)
    }

    @Test func seedEntryStartsAsTheSeed() {
        let context = Self.context()
        let seed = context.canvas.seed
        let frame = Self.fromSeed(context).frame(at: 0, interaction: IntroInteraction())
        #expect(frame.glass.count == 1)
        let bounds = frame.glass[0].path.boundingRect
        #expect(abs(bounds.midX - seed.center.x) < 0.5 && abs(bounds.midY - seed.center.y) < 0.5)
        #expect(abs(bounds.width - seed.diameter) < 0.5 && abs(bounds.height - seed.diameter) < 0.5)
        #expect(frame.scene == nil)
        #expect(frame.symbols.isEmpty && frame.looseGlass.isEmpty && frame.mark == nil)
        #expect(frame.glassOpacity == 1)
    }

    @Test func sceneEntryStartsAsTheSceneAtRest() {
        let context = Self.context()
        let frame = Self.fromScene(context, yaw: 2.5).frame(at: 0, interaction: IntroInteraction())
        guard let scene = frame.scene else {
            Issue.record("expected the scene to be on screen")
            return
        }
        // Exactly what the scene page leaves: the whole canvas, one level
        // past the last sweep, the cube where it was held.
        let covering = context.canvas.coveringDiameter(around: context.canvas.graphicCenter)
        #expect(scene.lensDiameter.map { $0 >= covering } ?? true)
        #expect(scene.level == Float(SceneReveal.firstLevel + SceneReveal.sweepCount))
        #expect(scene.sweep >= 1.5)
        #expect(scene.yaw == 2.5)
        #expect(scene.opacity == 1)
        #expect(scene.lensCenter == context.canvas.graphicCenter)
        #expect(frame.glassOpacity == 0)
        #expect(frame.symbols.isEmpty)
    }

    @Test func theLensClosesOverTheHeldSceneThenItIsGone() {
        let context = Self.context()
        let motion = Self.fromScene(context)
        let interaction = IntroInteraction()
        var previous = CGFloat.infinity
        var time = 0.3
        while time < GraphReveal.shrinkStart + GraphReveal.shrinkDuration - 0.01 {
            let lens = motion.frame(at: time, interaction: interaction).scene?.lensDiameter
            #expect(lens != nil && lens! <= previous, "the lens only closes (\(time)s)")
            previous = lens ?? previous
            time += 0.05
        }
        let after = motion.frame(at: GraphReveal.shootStart, interaction: interaction)
        #expect(after.scene == nil)
        #expect(after.glassOpacity == 1)
    }

    @Test func glassComesBackInOverTheGlassInDuration() {
        let motion = Self.fromScene(Self.context())
        let interaction = IntroInteraction()
        let half = motion.frame(at: GraphReveal.glassInDuration / 2, interaction: interaction).glassOpacity
        #expect(half > 0.5 && half < 1)
        #expect(motion.frame(at: GraphReveal.glassInDuration, interaction: interaction).glassOpacity == 1)
    }

    @Test(arguments: [CGSize(width: 1200, height: 800), CGSize(width: 390, height: 844)])
    func settleFrameIsTheFinishedGraph(size: CGSize) {
        let context = Self.context(size: size)
        for motion in [Self.fromScene(context), Self.fromSeed(context)] {
            let frame = motion.frame(at: motion.settleTime, interaction: IntroInteraction(reducesMotion: true))
            #expect(frame.scene == nil)
            #expect(frame.glassOpacity == 1)
            #expect(frame.glass.count == 1 && frame.glass[0].id == "main")
            let bounds = frame.glass[0].path.boundingRect
            #expect(bounds.minX.isFinite && bounds.maxX.isFinite && bounds.minY.isFinite && bounds.maxY.isFinite)
            #expect(bounds.width > 100 && bounds.minX < size.width / 2 && bounds.maxX > size.width / 2)
            #expect(frame.symbols.count == 3)
            #expect(Set(frame.symbols.map(\.id)).count == 3)
            #expect(frame.symbols.map(\.name) == context.symbols)
            for symbol in frame.symbols {
                #expect(symbol.opacity > 0.97 && symbol.scale > 0.97)
                #expect(symbol.center.x > 0 && symbol.center.x < size.width)
            }
        }
    }

    @Test func offersTheGraphAtRest() {
        let motion = Self.fromScene(Self.context())
        let interaction = IntroInteraction()
        guard case .graph(let rest) = motion.handoff(at: motion.settleTime, interaction: interaction),
              case .graph(let later) = motion.handoff(at: motion.settleTime + 7, interaction: interaction)
        else {
            Issue.record("expected the graph to be offered at rest")
            return
        }
        #expect(rest.nodes.count == 3 && rest.wires.count == 3 && rest.beads.count == 4)
        #expect(rest.orbDiameter == 0 && rest.lensDiameter == nil)
        // Whenever the page turns, it offers where the graph is by then, which
        // settles on from the spring's last ripple.
        for (node, settled) in zip(rest.nodes, later.nodes) {
            #expect(abs(node.rect.width - settled.rect.width) < 1.5 && abs(node.rect.midX - settled.rect.midX) < 1.5)
        }
        // The picture a turn leaves is the graph that is offered.
        let seeded = Self.fromSeed(Self.context())
        guard case .graph(let seededRest) = seeded.handoff(at: seeded.settleTime, interaction: interaction) else {
            Issue.record("expected the graph to be offered at rest from the seed too")
            return
        }
        #expect(seededRest.nodes.map(\.rect) == rest.nodes.map(\.rect))
    }

    @Test func aSingleSymbolGrowsASingleNode() {
        let motion = Self.fromSeed(Self.context(symbols: ["star.fill"]))
        let frame = motion.frame(at: motion.settleTime, interaction: IntroInteraction())
        #expect(frame.symbols.map(\.name) == ["star.fill"])
    }

    @Test(arguments: [Self.wide, Self.phone])
    func noJumpsFromTheSceneOrTheSeed(size: CGSize) async {
        let context = Self.context(size: size)
        let canvas = context.canvas
        for motion in [Self.fromScene(context), Self.fromSeed(context)] {
            let check = ContinuityCheck(canvas: canvas) { motion.frame(at: $0, interaction: IntroInteraction()) }
            // Past the settle too, as a later picture collapses it.
            let faults = await check.faults(from: 0, to: motion.settleTime + 1.5)
            #expect(faults.isEmpty, "\(size): \(faults.prefix(4))")
        }
    }

    @Test(arguments: [0.4, 1.0, 1.9, 3.3])
    func collapsingAtAnyMomentNeverJumps(turn: Double) async {
        let context = Self.context()
        let canvas = context.canvas
        for motion in [Self.fromScene(context), Self.fromSeed(context)] {
            let interaction = IntroInteraction()
            let check = ContinuityCheck(canvas: canvas) { time in
                let progress = time / motion.exitDuration
                return motion.exitFrame(
                    from: motion.frame(at: turn + time, interaction: interaction),
                    at: turn + time,
                    progress: progress
                )
            }
            let faults = await check.faults(from: 0, to: motion.exitDuration)
            #expect(faults.isEmpty, "turned \(turn)s in: \(faults.prefix(4))")
        }
    }

    @Test(arguments: [Self.wide, Self.phone])
    func carriesStraightOnFromTheSceneAtRest(size: CGSize) async {
        let context = Self.context(size: size)
        var player = WelcomePlayer(resting: RestingSceneProbe(context: context, yaw: 0.9))
        let turn = player.turn(
            at: 0,
            interaction: IntroInteraction(),
            continues: GraphMotion.continues(from:),
            build: { GraphMotion(entry: $0, context: context) }
        )
        if case .handoff(.scene(let yaw, _, _, _)) = player.current.entry {
            #expect(yaw == 0.9)
        } else {
            Issue.record("expected the graph to carry on from the scene")
        }
        let snapshot = player
        let check = ContinuityCheck(canvas: context.canvas) { snapshot.frame(at: $0, interaction: IntroInteraction()) }
        let faults = await check.faults(from: 0, to: turn.settleTime + 1)
        #expect(faults.isEmpty, "\(size): \(faults.prefix(4))")
    }
}
