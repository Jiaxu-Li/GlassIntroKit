//===--- PhysicsLandingTests.swift - GlassIntroKit --------------------------===//
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

/// However many nodes fall, and from whatever graph, every one comes to
/// rest face up on the line: none bounces off the canvas or lands on its
/// side.
@Suite struct PhysicsLandingTests {
    nonisolated static let canvases = [
        CGSize(width: 1200, height: 800),
        CGSize(width: 390, height: 844),
        CGSize(width: 320, height: 568),
        CGSize(width: 1024, height: 1366),
    ]

    private static func context(_ size: CGSize, symbols: [String], graph: GlassIntroGraph? = nil) -> IntroContext {
        let canvas = IntroCanvas(size: size, bodyDiameterRatio: 0.76)
        return IntroContext(
            canvas: canvas,
            markOutline: GlassIntroMark.symbol("star.fill").outline,
            outlines: [:],
            page: 0,
            symbols: symbols,
            centerSymbol: nil,
            graph: graph,
            markSymbol: nil,
            words: [],
            textTop: size.height * 0.75
        )
    }

    /// The nodes that are not at rest, face up, on the line.
    private static func unsettled(_ motion: PhysicsMotion) -> [Int] {
        let still = IntroInteraction()
        guard case .fallen(let fallen) = motion.handoff(at: motion.settleTime, interaction: still) else {
            return [-1]
        }
        let half = fallen.platformWidth / 2
        return fallen.nodes.filter { node in
            let onLine = abs(node.center.x - fallen.platformCenter.x) < half && node.center.y < fallen.platformCenter.y
            let faceUp = abs(remainder(node.angle, 2 * .pi)) < 0.06
            return !(onLine && faceUp)
        }.map(\.id)
    }

    @Test(arguments: canvases)
    func anyNumberOfNodesLands(size: CGSize) {
        for count in 1...GlassIntroGraph.maximumNodeCount {
            let symbols = Array(GlassIntroPage.defaultScatterSymbols.prefix(count))
            let motion = PhysicsMotion(entry: .seed, context: Self.context(size, symbols: symbols))
            #expect(Self.unsettled(motion).isEmpty, "\(count) nodes on \(size)")
        }
    }

    @Test(arguments: canvases)
    func everyGraphsNodesLand(size: CGSize) {
        let symbols = Array(GlassIntroPage.defaultScatterSymbols.prefix(8))
        let graphs: [GlassIntroGraph] = [
            .branching(GlassIntroPage.defaultNodeSymbols),
            .chain(Array(symbols.prefix(5))),
            .diamond("a", through: Array(symbols.prefix(3)), into: "b"),
            .branch("a", into: Array(symbols.prefix(5))),
            GlassIntroGraph(nodes: symbols, links: []),
        ]
        for graph in graphs {
            let graphContext = Self.context(size, symbols: graph.nodes, graph: graph)
            let graphMotion = GraphMotion(entry: .seed, context: graphContext)
            let handoff = graphMotion.handoff(at: graphMotion.settleTime, interaction: IntroInteraction())
            let motion = PhysicsMotion(entry: .handoff(handoff), context: Self.context(size, symbols: []))
            #expect(Self.unsettled(motion).isEmpty, "\(graph.nodes.count) nodes, \(graph.links.count) wires, on \(size)")
        }
    }
}
