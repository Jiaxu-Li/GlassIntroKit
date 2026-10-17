//===--- ResizeLayoutTests.swift - GlassIntroKit ----------------------------===//
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

/// A window resized while the welcome plays: every page, laid out again at
/// rest for the new size, keeps all of its picture inside the window and
/// still carries on from the page before.
@Suite struct ResizeLayoutTests {
    nonisolated static let sizes = [
        CGSize(width: 1200, height: 800),
        CGSize(width: 700, height: 480),
        CGSize(width: 390, height: 844),
        CGSize(width: 1600, height: 1000),
    ]

    @MainActor
    private static func content() -> WelcomeContent {
        WelcomeContent(GlassIntro(
            appName: "Orbit",
            mark: .symbol("globe.americas.fill"),
            pages: [
                TestPages.page(.greeting),
                TestPages.page(.mark),
                TestPages.page(.symbols),
                TestPages.page(.scene),
                TestPages.page(.graph),
                // Its own node is not the graph's: after the graph, the
                // graph's nodes fall instead.
                .physics("Physics", message: "m", nodes: ["star.fill"]),
                TestPages.page(.icon),
                TestPages.page(.card),
            ]
        ))
    }

    @Test(arguments: sizes)
    func everyPageLaidOutAgainStaysInsideTheWindow(size: CGSize) async {
        let outlines = await TestOutlines.all()
        let content = Self.content()
        let canvas = IntroCanvas(size: size, bodyDiameterRatio: 0.76)
        let bounds = CGRect(origin: .zero, size: size)
        for index in 0...content.pageCount - 1 {
            let resting = content.restingMotion(for: index, carriesOn: true, interaction: IntroInteraction()) {
                content.context(page: $0, canvas: canvas, outlines: outlines, textTop: nil)
            }
            #expect(resting.motion.context.canvas == canvas)
            let frame = resting.motion.frame(at: resting.motion.settleTime, interaction: IntroInteraction())
            for symbol in frame.symbols where symbol.opacity > 0.01 {
                #expect(bounds.contains(symbol.center), "page \(index) on \(size): \(symbol.name) at \(symbol.center)")
            }
            // The graph's wire runs in from past the window's left edge, as
            // it was made to; its nodes are checked as symbols above.
            guard content.picture(at: index) != .page(.graph) else {
                continue
            }
            for piece in frame.glass + frame.looseGlass where piece.opacity > 0.01 {
                let box = piece.path.boundingRect
                #expect(box.isNull || bounds.insetBy(dx: -2, dy: -2).contains(box), "page \(index) on \(size): glass \(piece.id) at \(box)")
            }
        }
    }

    @Test(arguments: sizes)
    func aPageThatCarriedOnStillCarriesOn(size: CGSize) async {
        let outlines = await TestOutlines.all()
        let content = Self.content()
        let canvas = IntroCanvas(size: size, bodyDiameterRatio: 0.76)
        let physics = content.restingMotion(for: 5, carriesOn: true, interaction: IntroInteraction()) {
            content.context(page: $0, canvas: canvas, outlines: outlines, textTop: nil)
        }
        guard case .handoff(.graph) = physics.entry else {
            Issue.record("expected the physics page to carry on from the graph")
            return
        }
        let names = physics.motion.frame(at: physics.motion.settleTime, interaction: IntroInteraction()).symbols.map(\.name)
        #expect(names.sorted() == GlassIntroPage.defaultNodeSymbols.sorted())
        // A page that grew out of the seed is laid out out of the seed.
        let seeded = content.restingMotion(for: 5, carriesOn: false, interaction: IntroInteraction()) {
            content.context(page: $0, canvas: canvas, outlines: outlines, textTop: nil)
        }
        guard case .seed = seeded.entry else {
            Issue.record("expected the physics page to grow out of the seed")
            return
        }
        #expect(seeded.motion.frame(at: seeded.motion.settleTime, interaction: IntroInteraction()).symbols.map(\.name) == ["star.fill"])
    }
}
