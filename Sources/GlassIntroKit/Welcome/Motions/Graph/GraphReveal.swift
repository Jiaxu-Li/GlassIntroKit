//===--- GraphReveal.swift - GlassIntroKit ----------------------------------===//
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

/// The graph page's movement. The lens the scene opened through closes
/// over it again and keeps shrinking to a glass point. A wire shoots left
/// out of the point and off the canvas; the point draws back a little
/// further left along it, and from then on nothing moves. The graph then
/// comes in from left to right: a node where the wire ends, at the point,
/// and two wires branching out of it at once to two more nodes.
///
/// Coming from the seed instead, there is no scene to close over: the
/// timeline joins at the shrink, with the glass drop shrinking from the
/// seed's size down to the point, and plays on unchanged from there.
nonisolated struct GraphReveal: Sendable {
    static let glassInDuration = 0.25
    static let closeDuration = 0.65
    static let shrinkStart = 0.65
    static let shrinkDuration = 0.45
    static let shootStart = 1.15
    static let shootDuration = 0.4
    static let settleStart = 1.6
    static let settleDuration = 0.55
    /// The point swells into the first node, with any others in the first
    /// column.
    static let firstNodeStart = 2.2
    /// The wires into the second column leave at once, each carrying a bead
    /// to its end.
    static let branchStart = 2.8
    static let branchDuration = 0.45
    /// The beads swell into the second column's nodes.
    static let branchNodeStart = 3.2
    /// Each further column follows this much later.
    static let columnStep = 0.7
    /// How long the last node takes to settle.
    static let nodeSettle = 0.7
    static let textStart = 3.0

    /// How long the last of the scene takes to clear from inside the lens.
    static let sceneClearDuration = 0.1

    static let beadDiameter: CGFloat = 16
    static let wireWidth: CGFloat = 6

    private static let closeCurve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.5, y: 0),
        endControlPoint: UnitPoint(x: 0.3, y: 1)
    )

    let center: CGPoint
    private let coverSize: CGFloat
    private let lensSize: CGFloat
    private let canvasSize: CGSize
    /// The size the lens shrinks from when the graph grows out of the seed;
    /// nil when it closes over the scene first.
    private let seedDiameter: CGFloat?
    let layout: GraphLayout

    /// The graph closing in over the scene it follows.
    init(canvasSize: CGSize, reveal: SceneReveal, graph: GlassIntroGraph) {
        self.init(canvasSize: canvasSize, reveal: reveal, graph: graph, from: nil)
    }

    /// The graph growing out of the glass drop of `seedDiameter`, which
    /// shrinks to the point the wire shoots from. Time zero is the drop at
    /// rest, so the reveal ends `timeOffset` sooner than the other.
    init(canvasSize: CGSize, reveal: SceneReveal, graph: GlassIntroGraph, seedDiameter: CGFloat) {
        self.init(canvasSize: canvasSize, reveal: reveal, graph: graph, from: seedDiameter)
    }

    private init(canvasSize: CGSize, reveal: SceneReveal, graph: GlassIntroGraph, from seedDiameter: CGFloat?) {
        self.seedDiameter = seedDiameter
        center = reveal.center
        coverSize = reveal.coverSize
        lensSize = reveal.lensSize
        self.canvasSize = canvasSize
        layout = GraphLayout(graph: graph, canvasSize: canvasSize, center: reveal.center)
    }

    /// When the nodes of `column` start to grow, on the original timeline.
    static func nodeStart(column: Int) -> Double {
        column == 0 ? firstNodeStart : branchNodeStart + Double(column - 1) * columnStep
    }

    /// When the wires into `column` leave, on the original timeline.
    static func wireStart(column: Int) -> Double {
        branchStart + Double(column - 1) * columnStep
    }

    /// When the last node has settled, on the original timeline.
    private var end: Double {
        Self.nodeStart(column: layout.columnCount - 1) + Self.nodeSettle
    }

    /// How much of the original timeline is skipped when the graph grows
    /// out of the seed: everything before the lens starts to shrink.
    var timeOffset: Double {
        seedDiameter == nil ? 0 : Self.shrinkStart
    }

    /// When the graph is finished, on this reveal's own clock.
    var settleTime: Double {
        end - timeOffset
    }

    /// When the page's text comes in, on this reveal's own clock.
    var textTime: Double {
        min(Self.textStart, end) - timeOffset
    }

    /// Whether the scene still shows through the closing lens.
    func showsScene(at time: Double) -> Bool {
        seedDiameter == nil && time + timeOffset < Self.shrinkStart + Self.shrinkDuration
    }

    func frame(at time: Double) -> GraphFrame {
        let time = time + timeOffset
        var frame = GraphFrame()

        // The lens closes back to the size it opened from, then on down to
        // a point.
        let middle = seedDiameter ?? lensSize * 0.6
        if time < Self.shrinkStart, seedDiameter == nil {
            let t = Self.closeCurve.value(at: Ease.clamp(time / Self.closeDuration))
            frame.orbDiameter = coverSize + (middle - coverSize) * t
        } else {
            let t = Ease.smoother((time - Self.shrinkStart) / Self.shrinkDuration)
            frame.orbDiameter = middle + (Self.beadDiameter - middle) * t
        }
        if seedDiameter == nil, time < Self.shrinkStart + Self.shrinkDuration {
            // The scene shows through a hair inside the glass's rim, which
            // grows from nothing at the start so that the lens, still as
            // wide as the canvas needs, never cuts a corner of it.
            let orb = frame.orbDiameter
            let inset = min(orb * 0.03, 40) * Ease.smoothstep((coverSize - orb) / (coverSize * 0.05))
            frame.lensDiameter = orb - inset
            let end = Self.shrinkStart + Self.shrinkDuration
            frame.sceneOpacity = 1 - Ease.smoother((time - (end - Self.sceneClearDuration)) / Self.sceneClearDuration)
        }
        guard time >= Self.shrinkStart + Self.shrinkDuration else {
            return frame
        }
        frame.orbDiameter = 0

        // Where the point settles: the first node's input.
        let entry = layout.nodes[0]
        let settled = entry.input
        // The wire shoots out of the point and past the canvas's left edge.
        let offCanvas = -GraphReveal.wireWidth * 4
        let shot = CGFloat(Ease.easeOut((time - Self.shootStart) / Self.shootDuration))
        // Then the point draws back along it, the wire ending where the
        // point is, and nothing moves after.
        let settle = CGFloat(Ease.smoother((time - Self.settleStart) / Self.settleDuration))
        let point = Ease.lerp(center, settled, Double(settle))
        let tail = point.x + (offCanvas - point.x) * shot
        if shot > 0 {
            var wire = Path()
            wire.move(to: CGPoint(x: tail, y: point.y))
            wire.addLine(to: point)
            frame.wires.append(wire)
        }
        frame.beads = [point]
        frame.beadDiameters = [Self.beadDiameter]

        // The first node grows out of the point, and any others in its
        // column out of nothing; each later column out of the beads its
        // wires carry.
        for (index, node) in layout.nodes.enumerated() where node.column == 0 {
            frame.nodes.append(contentsOf: grownNode(
                id: index,
                node: node,
                port: node.input,
                elapsed: time - Self.firstNodeStart,
                from: index == 0 ? Self.beadDiameter : 0
            ))
        }
        for column in 1..<max(layout.columnCount, 1) {
            let drawn = CGFloat(Ease.smoother((time - Self.wireStart(column: column)) / Self.branchDuration))
            guard drawn > 0 else {
                break
            }
            let links = layout.links(into: column)
            // The beads swell out of the outputs as the wires leave.
            let bead = Self.beadDiameter * CGFloat(Ease.smoother(Double(drawn) / 0.25))
            // A bead at each output the wires leave, and one carried along
            // each wire.
            var outputs = Set<Int>()
            for link in links where outputs.insert(link.from).inserted {
                frame.beads.append(layout.nodes[link.from].output)
                frame.beadDiameters.append(bead)
            }
            for link in links {
                // A wire drawn only a hair of the way is empty; its bead is
                // still at the output it leaves.
                let output = layout.nodes[link.from].output
                let shown = layout.wire(link).trimmedPath(from: 0, to: drawn)
                if !shown.isEmpty {
                    frame.wires.append(shown)
                }
                frame.beads.append(shown.currentPoint ?? output)
                frame.beadDiameters.append(bead)
            }
            for (index, node) in layout.nodes.enumerated() where node.column == column {
                frame.nodes.append(contentsOf: grownNode(
                    id: index,
                    node: node,
                    port: node.input,
                    elapsed: time - Self.nodeStart(column: column),
                from: Self.beadDiameter
                ))
            }
        }
        frame.nodes.sort { $0.id < $1.id }
        return frame
    }

    /// A node `elapsed` seconds into growing out of the bead at `port`: it
    /// swells rightward on a soft spring, from a bead into its tile, and its
    /// symbol comes in over the last part.
    private func grownNode(
        id: Int,
        node: GraphLayout.Node,
        port: CGPoint,
        elapsed: Double,
        from start: CGFloat
    ) -> [GraphNodeFrame] {
        guard elapsed > 0 else {
            return []
        }
        let symbol = node.symbol
        let final = node.rect
        // The spring's last ripple is eased away, so the node is exactly its
        // tile once the graph has settled.
        let landed = Ease.smoother((elapsed - 0.4) / (Self.nodeSettle - 0.4))
        let growth = CGFloat(Ease.spring(elapsed, period: 0.75, damping: 0.8) * (1 - landed) + landed)
        let bead = start
        let width = bead + (final.width - bead) * growth
        let height = bead + (final.height - bead) * growth
        // The bead, `start` wide, starts centered on the port; the tile ends
        // with its left edge there.
        let minX = port.x - bead / 2 * (1 - growth)
        let radius = bead / 2 + (final.height * 0.36 - bead / 2) * growth
        let settled = CGFloat(Ease.smoother((elapsed - 0.22) / 0.38))
        return [GraphNodeFrame(
            id: id,
            symbol: symbol,
            rect: CGRect(x: minX, y: port.y - height / 2, width: width, height: height),
            cornerRadius: min(max(radius, 0), height / 2),
            symbolOpacity: Double(settled),
            symbolScale: 0.7 + 0.3 * settled,
            symbolSize: final.height * 0.42
        )]
    }
}
