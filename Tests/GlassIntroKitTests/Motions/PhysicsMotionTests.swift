//===--- PhysicsMotionTests.swift - GlassIntroKit ---------------------------===//
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

/// The physics picture: where it starts from, what it offers at rest, and
/// that its two ways in meet the pictures around them.
@Suite struct PhysicsMotionTests {
    private let canvas = IntroCanvas(size: CGSize(width: 1200, height: 800), bodyDiameterRatio: 0.76)
    private let textTop: CGFloat = 560

    private func context(symbols: [String] = ["star.fill", "leaf.fill", "bolt.fill"]) -> IntroContext {
        IntroContext(
            canvas: canvas,
            markOutline: GlassIntroMarkOutline.symbol("star.fill"),
            outlines: [:],
            page: 5,
            symbols: symbols,
            centerSymbol: nil,
            markSymbol: nil,
            words: [],
            textTop: textTop
        )
    }

    /// The graph, at rest, as the graph picture leaves it.
    private func restingGraph(_ context: IntroContext) -> GraphFrame {
        GraphReveal(
            canvasSize: canvas.size,
            reveal: SceneReveal(canvasSize: canvas.size, center: canvas.graphicCenter),
            graph: .branching(context.symbols)
        )
        .frame(at: 100)
    }

    /// The graph's picture at rest, drawn as the graph draws it: wires,
    /// beads, and nodes in one piece of glass, and the nodes' symbols.
    private func graphPicture(_ graph: GraphFrame, context: IntroContext) -> IntroFrame {
        var glass = GlassFrame()
        glass.wires = graph.wires
        glass.beads = graph.beads
        glass.nodes = graph.nodes.map { ($0.rect, $0.cornerRadius) }
        let path = glass.path(layout: HelloLayout.resting(in: canvas), markDimension: canvas.markDimension, context: context)
        return IntroFrame(
            glass: [GlassPiece(id: "main", path: path)],
            symbols: graph.nodes.map {
                SymbolSprite(id: "symbol.\($0.id)", name: $0.symbol, center: CGPoint(x: $0.rect.midX, y: $0.rect.midY), size: $0.symbolSize)
            }
        )
    }

    private func fromGraph(_ context: IntroContext) -> PhysicsMotion {
        PhysicsMotion(entry: .handoff(.graph(restingGraph(context))), context: context)
    }

    private func fromSeed(_ context: IntroContext) -> PhysicsMotion {
        PhysicsMotion(entry: .seed, context: context)
    }

    private func isFinite(_ rect: CGRect) -> Bool {
        rect.isNull || (rect.minX.isFinite && rect.minY.isFinite && rect.width.isFinite && rect.height.isFinite)
    }

    @Test func carriesOnOnlyFromTheGraph() {
        let graph = restingGraph(context())
        #expect(PhysicsMotion.continues(from: .graph(graph)))
        let others: [IntroHandoff] = [
            .launch, .word, .mark, .symbols(scatter: [], center: nil), .scene(yaw: 0),
            .fallen(PhysicsFrame()), .other,
        ]
        for handoff in others {
            #expect(!PhysicsMotion.continues(from: handoff), "\(handoff)")
        }
    }

    @Test func timingFollowsTheWayIn() {
        let context = context()
        let direct = fromGraph(context)
        #expect(direct.settleTime == PhysicsReveal.end)
        #expect(direct.textTime == PhysicsReveal.textStart)
        let grown = fromSeed(context)
        #expect(grown.settleTime == PhysicsGrowth.duration + PhysicsReveal.end)
        #expect(grown.textTime == PhysicsGrowth.duration + PhysicsReveal.textStart)
        #expect(grown.absorbsSeed)
    }

    @Test func seedEntryStartsAsTheSeed() {
        let frame = fromSeed(context()).frame(at: 0, interaction: IntroInteraction())
        #expect(frame.glass.count == 1)
        let seed = canvas.seed
        let bounds = frame.glass.first?.path.boundingRect ?? .null
        #expect(abs(bounds.midX - seed.center.x) < 0.01 && abs(bounds.midY - seed.center.y) < 0.01)
        #expect(abs(bounds.width - seed.diameter) < 0.01 && abs(bounds.height - seed.diameter) < 0.01)
        #expect(frame.looseGlass.isEmpty && frame.symbols.isEmpty && frame.lines.isEmpty)
        #expect(frame.particles.isEmpty && frame.scene == nil && frame.mark == nil && frame.card == nil)
        #expect(frame.glassOpacity == 1)
    }

    @Test func seedEntryGrowsTheGraphsNodesAndLetsThemFall() {
        let context = context()
        let motion = fromSeed(context)
        let resting = PhysicsMotion.row(context.symbols, canvasSize: canvas.size, center: canvas.graphicCenter)
        let interaction = IntroInteraction()
        // Where the growth ends, the nodes hang in their row.
        let released = motion.frame(at: PhysicsGrowth.duration, interaction: interaction)
        #expect(released.looseGlass.count == 3)
        for (piece, node) in zip(released.looseGlass, resting) {
            let bounds = piece.path.boundingRect
            #expect(abs(bounds.minX - node.rect.minX) < 0.01 && abs(bounds.maxY - node.rect.maxY) < 0.01)
            #expect(abs(bounds.width - node.rect.width) < 0.01 && abs(bounds.height - node.rect.height) < 0.01)
        }
        // The release itself is invisible.
        let before = FrameRaster(motion.frame(at: PhysicsGrowth.duration - 0.0001, interaction: interaction), canvas: canvas)
        let after = FrameRaster(released, canvas: canvas)
        #expect(before.difference(from: after) < 0.0001)
        // Mid growth the seed and the tiles share one glass.
        let middle = motion.frame(at: PhysicsGrowth.duration * 0.4, interaction: interaction)
        #expect(middle.glass.contains { $0.id == GlassSeed.pieceID })
        #expect(middle.glass.count > 1 && middle.looseGlass.isEmpty)
    }

    @Test func eachSymbolIsANode() {
        let frame = fromSeed(context(symbols: ["star.fill"])).frame(at: PhysicsGrowth.duration, interaction: IntroInteraction())
        #expect(frame.symbols.map(\.name) == ["star.fill"])
        let none = fromSeed(context(symbols: [])).frame(at: PhysicsGrowth.duration, interaction: IntroInteraction())
        #expect(none.symbols.map(\.name) == GlassIntroPage.defaultNodeSymbols)
    }

    @Test func graphEntryStartsAsTheGraph() {
        let context = context()
        let graph = restingGraph(context)
        let motion = PhysicsMotion(entry: .handoff(.graph(graph)), context: context)
        let start = motion.frame(at: 0, interaction: IntroInteraction())
        #expect(start.glass.map(\.id) == ["main"])
        #expect(start.looseGlass.count == 3 && start.symbols.count == 3)
        let wanted = FrameRaster(graphPicture(graph, context: context), canvas: canvas)
        #expect(FrameRaster(start, canvas: canvas).difference(from: wanted) < 0.0001)
        // The nodes keep their geometry, only their glass changes.
        for (piece, node) in zip(start.looseGlass, graph.nodes) {
            #expect(abs(piece.path.boundingRect.minX - node.rect.minX) < 0.01)
            #expect(abs(piece.path.boundingRect.width - node.rect.width) < 0.01)
        }
    }

    @Test func settledFrameIsTheFinishedPicture() {
        let context = context()
        for motion in [fromGraph(context), fromSeed(context)] {
            let frame = motion.frame(at: motion.settleTime, interaction: IntroInteraction(reducesMotion: true))
            #expect(frame.glass.isEmpty, "\(frame.glass.map { $0.path.boundingRect })")
            #expect(frame.looseGlass.count == 3 && frame.symbols.count == 3)
            let line = frame.lines.first
            #expect(line != nil && (line?.width ?? 0) > 100)
            let lineY = line?.center.y ?? 0
            #expect(abs(lineY - (textTop - PhysicsMotion.platformGap)) < 0.01)
            // The nodes lie on the line, or on one another: none through it,
            // and the lowest on it.
            let bottoms = frame.looseGlass.map(\.path.boundingRect).map(\.maxY)
            #expect(frame.looseGlass.allSatisfy { isFinite($0.path.boundingRect) })
            #expect(bottoms.allSatisfy { $0 < lineY + 3 }, "\(bottoms) on \(lineY)")
            #expect(abs((bottoms.max() ?? 0) - lineY) < 3, "\(bottoms) on \(lineY)")
            #expect(frame.particles.count < 3)
            // Nothing moves any more.
            let later = motion.frame(at: motion.settleTime + 5, interaction: IntroInteraction())
            #expect(later.looseGlass.map(\.path.boundingRect) == frame.looseGlass.map(\.path.boundingRect))
            #expect(later.particles.isEmpty)
        }
    }

    @Test func offersTheFallenNodesAtRest() {
        let context = context()
        for motion in [fromGraph(context), fromSeed(context)] {
            guard case .fallen(let fallen) = motion.handoff(at: motion.settleTime, interaction: IntroInteraction()) else {
                Issue.record("expected the fallen nodes")
                continue
            }
            #expect(fallen.nodes.count == 3 && fallen.platformWidth > 100 && fallen.wires.isEmpty)
        }
    }

    @Test(arguments: [true, false])
    func neverJumpsOnItsOwn(fromGraph direct: Bool) async {
        let context = context()
        let motion = direct ? fromGraph(context) : fromSeed(context)
        let check = ContinuityCheck(canvas: canvas) { motion.frame(at: $0, interaction: IntroInteraction()) }
        let faults = await check.faults(from: 0, to: motion.settleTime + 0.5)
        #expect(faults.isEmpty, "\(faults.prefix(4))")
    }
}
