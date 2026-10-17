//===--- GraphLayoutTests.swift - GlassIntroKit -----------------------------===//
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

@Suite struct GraphLayoutTests {
    nonisolated static let canvases = [
        CGSize(width: 1200, height: 800),
        CGSize(width: 390, height: 844),
        CGSize(width: 320, height: 568),
        CGSize(width: 1024, height: 1366),
    ]

    @Test func linksThatCannotBeLaidOutAreLeftOut() {
        let graph = GlassIntroGraph(
            nodes: ["a", "b", "c"],
            links: [.init(0, 1), .init(1, 0), .init(1, 1), .init(0, 5), .init(-1, 2), .init(0, 1), .init(1, 2)]
        )
        #expect(graph.links == [.init(0, 1), .init(1, 2)])
    }

    @Test func noMoreThanTheMostNodesAreKept() {
        let graph = GlassIntroGraph.chain(Array(repeating: "star.fill", count: 12))
        #expect(graph.nodes.count == GlassIntroGraph.maximumNodeCount)
        #expect(graph.links.allSatisfy { $0.to < GlassIntroGraph.maximumNodeCount })
    }

    @Test func presetsAreWiredAsNamed() {
        #expect(GlassIntroGraph.chain(["a", "b", "c"]).links == [.init(0, 1), .init(1, 2)])
        #expect(GlassIntroGraph.branch("a", into: ["b", "c"]).links == [.init(0, 1), .init(0, 2)])
        let diamond = GlassIntroGraph.diamond("a", through: ["b", "c"], into: "d")
        #expect(Set(diamond.links) == [.init(0, 1), .init(0, 2), .init(1, 3), .init(2, 3)])
    }

    @Test func eachNodeSitsOneColumnPastWhatFeedsIt() {
        let layout = GraphLayout(
            graph: .diamond("a", through: ["b", "c"], into: "d"),
            canvasSize: Self.canvases[0],
            center: CGPoint(x: 600, y: 300)
        )
        #expect(layout.nodes.map(\.column) == [0, 1, 1, 2])
        #expect(layout.columnCount == 3)
        // Every wire runs left to right.
        for link in layout.links {
            #expect(layout.nodes[link.from].rect.maxX < layout.nodes[link.to].rect.minX)
        }
    }

    @Test(arguments: canvases)
    func everyGraphFitsTheCanvasWithoutOverlapping(size: CGSize) {
        let symbols = Array(repeating: "star.fill", count: 8)
        let graphs: [GlassIntroGraph] = [
            .chain(symbols),
            .branch("a", into: Array(symbols.prefix(7))),
            .diamond("a", through: Array(symbols.prefix(6)), into: "b"),
            GlassIntroGraph(nodes: symbols, links: []),
            .branching(["a"]),
        ]
        let center = CGPoint(x: size.width / 2, y: size.height * 0.36)
        for graph in graphs {
            let layout = GraphLayout(graph: graph, canvasSize: size, center: center)
            for node in layout.nodes {
                #expect(node.rect.minX >= 0 && node.rect.maxX <= size.width, "\(graph.nodes.count) nodes on \(size)")
                #expect(node.rect.minY >= 0 && node.rect.maxY <= size.height)
            }
            for (i, a) in layout.nodes.enumerated() {
                for b in layout.nodes[(i + 1)...] {
                    #expect(!a.rect.intersects(b.rect), "nodes overlap on \(size)")
                }
            }
        }
    }

    @Test func theGraphEndsWithEveryNodeInPlace() {
        let size = Self.canvases[1]
        let graph = GlassIntroGraph.chain(["a", "b", "c", "d"])
        let scene = SceneReveal(canvasSize: size, center: CGPoint(x: size.width / 2, y: size.height * 0.4))
        let reveal = GraphReveal(canvasSize: size, reveal: scene, graph: graph)
        let rest = reveal.frame(at: reveal.settleTime)
        #expect(rest.nodes.map(\.rect) == reveal.layout.nodes.map(\.rect))
        #expect(rest.nodes.map(\.symbol) == ["a", "b", "c", "d"])
        // Nothing moves after.
        #expect(reveal.frame(at: reveal.settleTime + 5).nodes.map(\.rect) == rest.nodes.map(\.rect))
        // A longer chain takes longer.
        #expect(reveal.settleTime > GraphReveal.nodeStart(column: 1) + GraphReveal.nodeSettle)
    }
}
