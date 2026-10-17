//===--- SymbolsMotionTests.swift - GlassIntroKit ---------------------------===//
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

@Suite struct SymbolsMotionTests {
    @MainActor
    private static func context(size: CGSize = CGSize(width: 1200, height: 800)) async -> IntroContext {
        let outlines = await TestOutlines.all()
        let mark = GlassIntroMark.symbol("globe.americas.fill")
        let content = WelcomeContent(GlassIntro(appName: "Orbit", mark: mark, pages: [TestPages.page(.symbols)]))
        return content.context(
            page: 0,
            canvas: IntroCanvas(size: size, bodyDiameterRatio: mark.bodyDiameterRatio),
            outlines: outlines,
            textTop: nil
        )
    }

    private static func isFinite(_ frame: IntroFrame) -> Bool {
        (frame.glass + frame.looseGlass).allSatisfy { piece in
            let rect = piece.path.boundingRect
            return rect.isNull || (rect.minX.isFinite && rect.minY.isFinite && rect.width.isFinite && rect.height.isFinite)
        }
    }

    @Test func continuesOnlyFromTheMark() {
        #expect(SymbolsMotion.continues(from: .mark))
        #expect(!SymbolsMotion.continues(from: .launch))
        #expect(!SymbolsMotion.continues(from: .word))
        #expect(!SymbolsMotion.continues(from: .symbols(scatter: [], center: nil)))
        #expect(!SymbolsMotion.continues(from: .scene(yaw: 0)))
        #expect(!SymbolsMotion.continues(from: .other))
    }

    @Test func followingTheMarkKeepsTheScatterTiming() async {
        let motion = SymbolsMotion(entry: .handoff(.mark), context: await Self.context())
        #expect(motion.settleTime == SymbolScatter.end)
        #expect(motion.textTime == SymbolScatter.textStart)
        #expect(motion.absorbsSeed)
        #expect(!motion.isLive)
    }

    @Test func growingOutOfTheSeedWaitsForTheDropToOpen() async {
        let context = await Self.context()
        let motion = SymbolsMotion(entry: .seed, context: context)
        #expect(motion.settleTime == SymbolsMotion.seedLead + SymbolScatter.end)
        #expect(motion.textTime == SymbolsMotion.seedLead + SymbolScatter.textStart)
    }

    @Test func seedEntryBeginsAsTheSeed() async {
        let context = await Self.context()
        let seed = context.canvas.seed
        let frame = SymbolsMotion(entry: .seed, context: context).frame(at: 0, interaction: IntroInteraction())
        #expect(frame.glass.count == 1)
        #expect(frame.looseGlass.isEmpty)
        let bounds = frame.glass[0].path.boundingRect
        #expect(abs(bounds.midX - seed.center.x) < 0.5)
        #expect(abs(bounds.midY - seed.center.y) < 0.5)
        #expect(abs(bounds.width - seed.diameter) < 0.5)
        #expect(abs(bounds.height - seed.diameter) < 0.5)
    }

    @Test func settleFrameIsTheFinishedScatter() async {
        let context = await Self.context()
        for entry in [IntroEntry.handoff(.mark), .seed] {
            let motion = SymbolsMotion(entry: entry, context: context)
            let frame = motion.frame(at: motion.settleTime, interaction: IntroInteraction())
            #expect(Self.isFinite(frame))
            #expect(frame.glass.first?.id == "main")
            let bubbles = frame.glass.filter { $0.id.hasPrefix("bubble.") }
            #expect(bubbles.count == context.symbols.count)
            let ids = Set(frame.glass.map(\.id))
            #expect(ids.count == frame.glass.count)
            // Every symbol has settled inside the canvas.
            let canvas = CGRect(origin: .zero, size: context.canvas.size)
            for bubble in bubbles {
                #expect(canvas.contains(bubble.path.boundingRect))
            }
        }
    }

    /// The symbols are still easing the last fraction of a point at rest.
    @Test func framesAfterSettlingStayPut() async {
        let motion = SymbolsMotion(entry: .handoff(.mark), context: await Self.context())
        let at = motion.frame(at: motion.settleTime, interaction: IntroInteraction())
        let later = motion.frame(at: motion.settleTime + 30, interaction: IntroInteraction())
        #expect(Self.isFinite(later))
        #expect(at.glass.count == later.glass.count)
        for (first, second) in zip(at.glass, later.glass) {
            #expect(abs(first.path.boundingRect.midX - second.path.boundingRect.midX) < 1.5, "\(first.id) \(first.path.boundingRect) \(second.path.boundingRect)")
        }
    }

    @Test func handsTheSymbolsOnToTheNextPicture() async {
        let context = await Self.context()
        let motion = SymbolsMotion(entry: .seed, context: context)
        guard case .symbols(let scatter, let center) = motion.handoff(at: motion.settleTime, interaction: IntroInteraction()) else {
            Issue.record("expected the symbols handoff")
            return
        }
        #expect(scatter == context.symbols)
        #expect(center == context.centerSymbol)
    }
}
