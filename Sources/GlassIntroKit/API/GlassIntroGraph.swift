//===--- GlassIntroGraph.swift - GlassIntroKit ------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

/// The nodes a `graph` page grows, and the wires between them.
///
/// A wire shoots out of a glass point into the first node; every other
/// node grows where its wires arrive, column after column. Nodes are laid
/// out left to right by how many wires lead to them, and scaled to fit the
/// window.
///
/// ```swift
/// .graph("Connected", message: "…",
///        graph: .chain(["tray.and.arrow.down.fill", "gearshape.fill", "paperplane.fill"]))
///
/// .graph("Connected", message: "…", graph: GlassIntroGraph(
///     nodes: ["a.circle.fill", "b.circle.fill", "c.circle.fill", "d.circle.fill"],
///     links: [.init(0, 1), .init(0, 2), .init(1, 3), .init(2, 3)]
/// ))
/// ```
nonisolated public struct GlassIntroGraph: Hashable, Sendable {
    /// A wire from one node's output to a later node's input, by index.
    public struct Link: Hashable, Sendable {
        /// The node the wire leaves, and the node it arrives at.
        public let from: Int
        public let to: Int

        public init(_ from: Int, _ to: Int) {
            self.from = from
            self.to = to
        }
    }

    /// The most nodes a graph shows; any past it are left out.
    public static let maximumNodeCount = 8

    /// Each node's SF Symbol, in order.
    public let nodes: [String]
    /// The wires that are kept: each runs forward, from an earlier node to
    /// a later one, between nodes that exist, once.
    public let links: [Link]

    /// A graph of `nodes` joined by `links`. A link that runs backward or
    /// to itself, names a node that does not exist, or repeats another is
    /// left out, so that every graph can be laid out left to right.
    public init(nodes: [String], links: [Link]) {
        let nodes = Array(nodes.prefix(Self.maximumNodeCount))
        self.nodes = nodes
        var seen = Set<Link>()
        self.links = links.filter { link in
            link.from >= 0 && link.from < link.to && link.to < nodes.count && seen.insert(link).inserted
        }
    }

    /// One node whose wires branch out to all the others.
    public static func branch(_ root: String, into branches: [String]) -> GlassIntroGraph {
        GlassIntroGraph(
            nodes: [root] + branches,
            links: branches.indices.map { Link(0, $0 + 1) }
        )
    }

    /// Every node wired to the next, in a row.
    public static func chain(_ nodes: [String]) -> GlassIntroGraph {
        GlassIntroGraph(nodes: nodes, links: nodes.indices.dropFirst().map { Link($0 - 1, $0) })
    }

    /// One node whose wires fan out to `middle`, which all wire into
    /// `last`.
    public static func diamond(_ first: String, through middle: [String], into last: String) -> GlassIntroGraph {
        let lastIndex = middle.count + 1
        return GlassIntroGraph(
            nodes: [first] + middle + [last],
            links: middle.indices.flatMap { [Link(0, $0 + 1), Link($0 + 1, lastIndex)] }
        )
    }

    /// The graph the page grows when it names only its nodes: the first
    /// branching out to the rest.
    public static func branching(_ nodes: [String]) -> GlassIntroGraph {
        guard let root = nodes.first else {
            return GlassIntroGraph(nodes: [], links: [])
        }
        return .branch(root, into: Array(nodes.dropFirst()))
    }
}
