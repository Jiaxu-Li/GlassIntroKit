//===--- IconMotionTests.swift - GlassIntroKit ------------------------------===//
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

/// The icon picture: how it starts from the fallen nodes and from the seed,
/// and what it leaves at rest.
@Suite struct IconMotionTests {
    private func context(size: CGSize = CGSize(width: 1200, height: 800)) -> IntroContext {
        IntroContext(
            canvas: IntroCanvas(size: size, bodyDiameterRatio: 0.76),
            markOutline: GlassIntroMarkOutline.symbol("star.fill"),
            outlines: [:],
            page: 5,
            symbols: ["shippingbox.fill", "checkmark"],
            centerSymbol: nil,
            markSymbol: nil,
            words: [],
            textTop: 560
        )
    }

    /// Three nodes lying where they fell, one of them tipped.
    private func fallen(on canvas: IntroCanvas) -> PhysicsFrame {
        let center = canvas.graphicCenter
        let symbols = ["arrow.triangle.branch", "rotate.3d.fill", "speaker.wave.2.fill"]
        let angles = [0.0, 0.08, 2 * Double.pi + 0.03]
        let nodes = (0..<3).map { index in
            PhysicsNodeFrame(
                id: index,
                symbol: symbols[index],
                center: CGPoint(x: center.x + CGFloat(index - 1) * 130, y: center.y + 180),
                angle: angles[index],
                size: CGSize(width: 92, height: 56),
                cornerRadius: 16,
                symbolSize: 24
            )
        }
        return PhysicsFrame(
            nodes: nodes,
            platformCenter: CGPoint(x: center.x, y: center.y + 210),
            platformWidth: 600
        )
    }

    private func fromNodes(size: CGSize = CGSize(width: 1200, height: 800)) -> IconMotion {
        let context = context(size: size)
        return IconMotion(entry: .handoff(.fallen(fallen(on: context.canvas))), context: context)
    }

    private func fromSeed(size: CGSize = CGSize(width: 1200, height: 800)) -> IconMotion {
        IconMotion(entry: .seed, context: context(size: size))
    }

    private func isFinite(_ frame: IntroFrame) -> Bool {
        (frame.glass + frame.looseGlass).allSatisfy {
            let bounds = $0.path.boundingRect
            return bounds.isNull || (bounds.minX.isFinite && bounds.minY.isFinite && bounds.width.isFinite && bounds.height.isFinite)
        } && frame.symbols.allSatisfy {
            $0.center.x.isFinite && $0.center.y.isFinite && $0.size.isFinite && $0.opacity.isFinite
        }
    }

    @Test func continuesOnlyFromTheFallenNodes() {
        let canvas = context().canvas
        #expect(IconMotion.continues(from: .fallen(fallen(on: canvas))))
        let others: [IntroHandoff] = [
            .launch, .word, .mark,
            .symbols(scatter: [], center: nil),
            .scene(yaw: 0),
            .graph(GraphFrame()),
            .other,
        ]
        for handoff in others {
            #expect(!IconMotion.continues(from: handoff))
        }
    }

    @Test func fallenNodesStartExactlyWhereTheyLay() {
        let motion = fromNodes()
        let canvas = motion.context.canvas
        let start = fallen(on: canvas)
        let frame = motion.frame(at: 0, interaction: IntroInteraction())
        #expect(!motion.absorbsSeed)
        #expect(frame.glass.count == start.nodes.count)
        for (piece, node) in zip(frame.glass, start.nodes) {
            let bounds = piece.path.boundingRect
            // A turned tile's outline stays centered on the node.
            #expect(abs(bounds.midX - node.center.x) < 0.5 && abs(bounds.midY - node.center.y) < 0.5)
        }
        #expect(frame.symbols.count == start.nodes.count)
        for (sprite, node) in zip(frame.symbols, start.nodes) {
            #expect(sprite.name == node.symbol && sprite.center == node.center)
            #expect(sprite.size == node.symbolSize && sprite.opacity == 1)
        }
        #expect(frame.lines.count == 1)
        #expect(frame.lines[0].center == start.platformCenter && frame.lines[0].width == start.platformWidth)
        #expect(frame.sheens.isEmpty && frame.particles.isEmpty && frame.scene == nil && frame.mark == nil)
    }

    @Test func seedEntryStartsAsTheSeed() {
        let motion = fromSeed()
        let seed = motion.context.canvas.seed
        let frame = motion.frame(at: 0, interaction: IntroInteraction())
        #expect(motion.absorbsSeed)
        #expect(frame.glass.count == 1)
        #expect(frame.looseGlass.isEmpty && frame.symbols.isEmpty && frame.lines.isEmpty)
        let bounds = frame.glass[0].path.boundingRect
        #expect(abs(bounds.minX - seed.rect.minX) < 0.001 && abs(bounds.maxX - seed.rect.maxX) < 0.001)
        #expect(abs(bounds.minY - seed.rect.minY) < 0.001 && abs(bounds.maxY - seed.rect.maxY) < 0.001)
    }

    @Test func seedEntryComesToRestSoonerAndCarriesTheTextWithIt() {
        let nodes = fromNodes()
        let seed = fromSeed()
        #expect(nodes.settleTime == IconReveal.end)
        #expect(nodes.textTime == IconReveal.textStart)
        #expect(seed.settleTime < nodes.settleTime && seed.textTime < nodes.textTime)
        #expect(seed.textTime > 0 && seed.textTime < seed.settleTime)
    }

    @Test(arguments: [true, false], [CGSize(width: 1200, height: 800), CGSize(width: 390, height: 844)])
    func restIsTheFinishedIcon(fromSeed seeded: Bool, size: CGSize) {
        let motion = seeded ? fromSeed(size: size) : fromNodes(size: size)
        let frame = motion.frame(at: motion.settleTime, interaction: IntroInteraction(reducesMotion: true))
        let side: CGFloat = size.width < 640 ? 112 : 132
        let center = motion.context.canvas.graphicCenter
        #expect(isFinite(frame))
        #expect(frame.glass.map(\.id) == ["icon", "badge"])
        let icon = frame.glass[0].path.boundingRect
        #expect(abs(icon.width - side) < 1 && abs(icon.midX - center.x) < 0.5 && abs(icon.midY - center.y) < 0.5)
        // The icon is a rounded square, not a circle.
        #expect(!frame.glass[0].path.contains(CGPoint(x: icon.minX + 2, y: icon.minY + 2)))
        #expect(frame.glass[0].path.contains(CGPoint(x: icon.minX + side * 0.3, y: icon.minY + side * 0.3)))
        let badge = frame.glass[1].path.boundingRect
        #expect(abs(badge.width - side * 0.34) < 1 && badge.midX > icon.midX && badge.midY < icon.midY)
        #expect(frame.symbols.map(\.id) == ["icon.symbol", "badge.symbol"])
        #expect(frame.symbols.map(\.name) == ["shippingbox.fill", "checkmark"])
        #expect(frame.symbols.allSatisfy { $0.opacity > 0.99 })
        #expect(frame.lines.isEmpty && frame.sheens.isEmpty)
    }

    @Test func nothingMovesNoticeablyAfterRest() {
        for motion in [fromNodes(), fromSeed()] {
            let rest = motion.frame(at: motion.settleTime, interaction: IntroInteraction())
            let later = motion.frame(at: motion.settleTime + 2, interaction: IntroInteraction())
            #expect(rest.glass.map(\.id) == later.glass.map(\.id))
            for (a, b) in zip(rest.glass, later.glass) {
                #expect(abs(a.path.boundingRect.width - b.path.boundingRect.width) < 0.5)
            }
        }
    }

    @Test func theSheenCrossesTheIconOnce() {
        let motion = fromNodes()
        let during = motion.frame(at: IconReveal.sheenStart + IconReveal.sheenDuration / 2, interaction: IntroInteraction())
        #expect(during.sheens.count == 1)
        #expect(during.sheens[0].rect.width > 100)
        #expect(motion.frame(at: IconReveal.sheenStart - 0.01, interaction: IntroInteraction()).sheens.isEmpty)
        #expect(motion.frame(at: IconReveal.sheenStart + IconReveal.sheenDuration + 0.01, interaction: IntroInteraction()).sheens.isEmpty)
    }

    @Test func theIconOffersNothingToCarryOnFrom() {
        let motion = fromNodes()
        if case .other = motion.handoff(at: motion.settleTime, interaction: IntroInteraction()) {} else {
            Issue.record("expected nothing to carry on from")
        }
    }

    @Test func leavingGathersTheIconAndItsSheenIntoTheSeed() {
        let motion = fromNodes()
        let time = IconReveal.sheenStart + 0.3
        let frame = motion.frame(at: time, interaction: IntroInteraction())
        let seed = motion.context.canvas.seed
        let start = motion.exitFrame(from: frame, at: time, progress: 0)
        #expect(start.sheens.count == 1 && start.sheens[0].rect == frame.sheens[0].rect)
        let end = motion.exitFrame(from: frame, at: time, progress: 1)
        #expect(end.glass.count == 1 && end.glass[0].path.boundingRect == seed.rect)
        #expect(end.sheens.isEmpty)
    }

    @Test(arguments: [true, false], [CGSize(width: 1200, height: 800), CGSize(width: 390, height: 844)])
    func theIconNeverJumpsOnItsOwn(fromSeed seeded: Bool, size: CGSize) async {
        let motion = seeded ? fromSeed(size: size) : fromNodes(size: size)
        let check = ContinuityCheck(canvas: motion.context.canvas) {
            motion.frame(at: $0, interaction: IntroInteraction())
        }
        let faults = await check.faults(from: 0, to: motion.settleTime + 0.5)
        #expect(faults.isEmpty, "\(seeded ? "from the seed" : "from the nodes"): \(faults.prefix(4))")
    }
}
