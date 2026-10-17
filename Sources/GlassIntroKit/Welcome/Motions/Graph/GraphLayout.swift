//===--- GraphLayout.swift - GlassIntroKit ----------------------------------===//
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

/// Where a graph's nodes sit: in columns left to right, each node one
/// column past the furthest node wired into it, each column centered on
/// the picture's center, and the whole graph scaled down to fit.
nonisolated struct GraphLayout: Sendable {
    struct Node: Sendable {
        let symbol: String
        let column: Int
        let rect: CGRect

        var input: CGPoint {
            CGPoint(x: rect.minX, y: rect.midY)
        }

        var output: CGPoint {
            CGPoint(x: rect.maxX, y: rect.midY)
        }
    }

    /// In the graph's own order; the first is where the wire comes in.
    let nodes: [Node]
    let links: [GlassIntroGraph.Link]
    let columnCount: Int
    let nodeSize: CGSize

    init(graph: GlassIntroGraph, canvasSize: CGSize, center: CGPoint) {
        let graph = graph.nodes.isEmpty ? .branching(GlassIntroPage.defaultNodeSymbols) : graph
        links = graph.links
        let count = graph.nodes.count

        // Each node one column past the furthest node wired into it; links
        // only run forward, so one pass in order settles every column.
        var columns = [Int](repeating: 0, count: count)
        for link in graph.links.sorted(by: { $0.to < $1.to }) {
            columns[link.to] = max(columns[link.to], columns[link.from] + 1)
        }
        columnCount = (columns.max() ?? 0) + 1

        // Within a column, nodes sit in the order of the nodes wired into
        // them, so wires cross as little as they can.
        var rows = [Double](repeating: 0, count: count)
        var members = [[Int]](repeating: [], count: columnCount)
        for column in 0..<columnCount {
            let inColumn = (0..<count).filter { columns[$0] == column }
            let weights = inColumn.map { node -> Double in
                let parents = graph.links.filter { $0.to == node }.map { rows[$0.from] }
                return parents.isEmpty ? Double(node) : parents.reduce(0, +) / Double(parents.count)
            }
            let ordered = zip(inColumn, weights).sorted { ($0.1, $0.0) < ($1.1, $1.0) }.map(\.0)
            for (row, node) in ordered.enumerated() {
                rows[node] = Double(row)
            }
            members[column] = ordered
        }
        let rowCount = members.map(\.count).max() ?? 1

        // Sized as the three-node graph was made, then scaled to fit.
        let compact = canvasSize.width < 640
        let baseNode = compact ? CGSize(width: 72, height: 46) : CGSize(width: 92, height: 56)
        let baseGap: CGFloat = compact ? 64 : 140
        let baseSpacing: CGFloat = compact ? 58 : 68
        let room = CGSize(
            width: canvasSize.width - (compact ? 48 : 160),
            height: canvasSize.height * (compact ? 0.42 : 0.46)
        )
        // The gaps give way first, down to a third, then everything shrinks
        // alike until the graph fits.
        func extent(_ count: Int, _ size: CGFloat, _ gap: CGFloat) -> CGFloat {
            CGFloat(count) * size + CGFloat(count - 1) * gap
        }
        let squeeze = min(max(
            (room.width - extent(columnCount, baseNode.width, 0)) / max(CGFloat(columnCount - 1) * baseGap, 1),
            1.0 / 3
        ), 1)
        let gapBase = baseGap * squeeze
        let width = extent(columnCount, baseNode.width, gapBase)
        let height = extent(rowCount, baseNode.height, baseSpacing)
        let scale = min(1, room.width / max(width, 1), room.height / max(height, 1))
        nodeSize = CGSize(width: baseNode.width * scale, height: baseNode.height * scale)
        let gap = gapBase * scale
        let pitch = nodeSize.height + baseSpacing * scale

        let left = center.x - (width * scale) / 2
        var placed: [Node] = []
        for node in 0..<count {
            let column = columns[node]
            let filled = CGFloat(members[column].count)
            let x = left + CGFloat(column) * (nodeSize.width + gap)
            let y = center.y + (CGFloat(rows[node]) - (filled - 1) / 2) * pitch
            placed.append(Node(
                symbol: graph.nodes[node],
                column: column,
                rect: CGRect(
                    x: x,
                    y: y - nodeSize.height / 2,
                    width: nodeSize.width,
                    height: nodeSize.height
                )
            ))
        }
        nodes = placed
    }

    /// The links that arrive at the nodes of `column`.
    func links(into column: Int) -> [GlassIntroGraph.Link] {
        links.filter { nodes[$0.to].column == column }
    }

    /// The wire from one node's output to another's input, eased out of
    /// the one and into the other.
    func wire(_ link: GlassIntroGraph.Link) -> Path {
        let output = nodes[link.from].output
        let input = nodes[link.to].input
        let reach = (input.x - output.x) * 0.5
        var path = Path()
        path.move(to: output)
        path.addCurve(
            to: input,
            control1: CGPoint(x: output.x + reach, y: output.y),
            control2: CGPoint(x: input.x - reach, y: input.y)
        )
        return path
    }
}
