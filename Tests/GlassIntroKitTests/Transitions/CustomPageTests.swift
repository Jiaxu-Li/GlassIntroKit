//===--- CustomPageTests.swift - GlassIntroKit ------------------------------===//
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

/// Pages made the app's own way: graphs of any shape, any number of falling
/// nodes, and scenes of any look. Every one must play and hand over without
/// a jump, on a wide window and on a phone.
@Suite struct CustomPageTests {
    nonisolated static let wide = CGSize(width: 1200, height: 800)
    nonisolated static let phone = CGSize(width: 390, height: 844)

    nonisolated static let graphs: [(String, GlassIntroGraph)] = [
        ("one node", GlassIntroGraph(nodes: ["star.fill"], links: [])),
        ("chain of five", .chain(["star.fill", "leaf.fill", "bolt.fill", "music.note", "photo.fill"])),
        ("diamond", .diamond("star.fill", through: ["leaf.fill", "bolt.fill", "music.note"], into: "photo.fill")),
        ("branch of six", .branch("star.fill", into: ["leaf.fill", "bolt.fill", "music.note", "photo.fill", "map.fill"])),
        ("two roots", GlassIntroGraph(
            nodes: ["star.fill", "leaf.fill", "bolt.fill", "music.note"],
            links: [.init(0, 2), .init(1, 2), .init(2, 3), .init(0, 3)]
        )),
        ("eight, unwired", GlassIntroGraph(nodes: Array(repeating: "star.fill", count: 8), links: [])),
    ]

    nonisolated static let scenes: [(String, GlassIntroScene)] = [
        ("sphere", GlassIntroScene(shape: .sphere, color: .orange)),
        ("ring, floating", GlassIntroScene(shape: .ring, motion: .float)),
        ("capsule, tumbling", GlassIntroScene(shape: .capsule, motion: .tumble)),
        ("cylinder, still, lit", GlassIntroScene(shape: .cylinder, motion: .still, revealsRendering: false)),
    ]

    @Test(arguments: [wide, phone])
    func everyGraphGrowsAndFallsWithoutAJump(size: CGSize) async {
        let outlines = await TestOutlines.all()
        for (name, graph) in Self.graphs {
            let pages: [GlassIntroPage] = [
                .scene("Scene", message: "m"),
                .graph("Graph", message: "m", graph: graph),
                .physics("Physics", message: "m"),
                .icon("Icon", message: "m"),
            ]
            let run = WelcomeRun(pages: pages, size: size, outlines: outlines, delay: { _ in 0.4 })
            let faults = await run.continuity.faults(from: 0, to: run.readyEnd)
            #expect(faults.isEmpty, "\(name) on \(size): \(faults.prefix(4))")
        }
    }

    @Test(arguments: [wide, phone])
    func everySceneOpensAndClosesWithoutAJump(size: CGSize) async {
        let outlines = await TestOutlines.all()
        for (name, scene) in Self.scenes {
            let pages: [GlassIntroPage] = [
                .symbols("Symbols", message: "m"),
                .scene("Scene", message: "m", scene: scene),
                .graph("Graph", message: "m"),
            ]
            let run = WelcomeRun(pages: pages, size: size, outlines: outlines, delay: { _ in 0.4 })
            let faults = await run.continuity.faults(from: 0, to: run.readyEnd)
            #expect(faults.isEmpty, "\(name) on \(size): \(faults.prefix(4))")
        }
    }

    @Test func aSceneOfYourOwnPlaysLikeAnyOther() async {
        let outlines = await TestOutlines.all()
        let pages: [GlassIntroPage] = [
            .greeting("Hello", message: "m"),
            .scene("Yours", message: "m") { Color.purple },
            .card("Card", message: "m") { Text(verbatim: "Card") },
        ]
        let run = WelcomeRun(pages: pages, outlines: outlines, delay: { _ in 0.4 })
        let faults = await run.continuity.faults(from: 0, to: run.readyEnd)
        #expect(faults.isEmpty, "\(faults.prefix(4))")
    }

    @Test(arguments: [1, 2, 5, 8])
    func anyNumberOfNodesFallsWithoutAJump(count: Int) async {
        let outlines = await TestOutlines.all()
        let nodes = Array(GlassIntroPage.defaultScatterSymbols.prefix(count))
        for size in [Self.wide, Self.phone] {
            let pages: [GlassIntroPage] = [
                .greeting("Hello", message: "m"),
                .physics("Physics", message: "m", nodes: nodes),
            ]
            let run = WelcomeRun(pages: pages, size: size, outlines: outlines, delay: { _ in 0.4 })
            let faults = await run.continuity.faults(from: 0, to: run.readyEnd)
            #expect(faults.isEmpty, "\(count) nodes on \(size): \(faults.prefix(4))")
        }
    }
}
