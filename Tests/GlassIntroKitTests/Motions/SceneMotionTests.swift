//===--- SceneMotionTests.swift - GlassIntroKit -----------------------------===//
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

@Suite struct SceneMotionTests {
    @MainActor
    private static func context(size: CGSize = CGSize(width: 1200, height: 800)) async -> IntroContext {
        let outlines = await TestOutlines.all()
        let mark = GlassIntroMark.symbol("globe.americas.fill")
        let content = WelcomeContent(GlassIntro(
            appName: "Orbit",
            mark: mark,
            pages: [TestPages.page(.symbols), TestPages.page(.scene)]
        ))
        return content.context(
            page: 1,
            canvas: IntroCanvas(size: size, bodyDiameterRatio: mark.bodyDiameterRatio),
            outlines: outlines,
            textTop: nil
        )
    }

    private static let symbolsHandoff = IntroHandoff.symbols(
        scatter: GlassIntroPage.defaultScatterSymbols,
        center: "globe.americas.fill"
    )

    @Test func continuesOnlyFromTheSymbols() {
        #expect(SceneMotion.continues(from: Self.symbolsHandoff))
        #expect(SceneMotion.continues(from: .symbols(scatter: [], center: nil)))
        #expect(!SceneMotion.continues(from: .launch))
        #expect(!SceneMotion.continues(from: .word))
        #expect(!SceneMotion.continues(from: .mark))
        #expect(!SceneMotion.continues(from: .scene(yaw: 0)))
        #expect(!SceneMotion.continues(from: .other))
    }

    @Test func followingTheSymbolsKeepsTheRevealTiming() async {
        let motion = SceneMotion(entry: .handoff(Self.symbolsHandoff), context: await Self.context())
        #expect(motion.settleTime == SceneReveal.end)
        #expect(motion.textTime == SceneReveal.textStart)
        #expect(motion.isLive)
        #expect(motion.isInteractive)
        #expect(motion.absorbsSeed)
    }

    @Test func growingOutOfTheSeedStartsAtTheLens() async {
        let motion = SceneMotion(entry: .seed, context: await Self.context())
        #expect(abs(motion.settleTime - (SceneReveal.end - SceneReveal.orbStart)) < 1e-9)
        #expect(abs(motion.textTime - (SceneReveal.textStart - SceneReveal.orbStart)) < 1e-9)
    }

    @Test func seedEntryBeginsAsTheSeed() async {
        let context = await Self.context()
        let seed = context.canvas.seed
        let frame = SceneMotion(entry: .seed, context: context).frame(at: 0, interaction: IntroInteraction())
        #expect(frame.glass.count == 1)
        let bounds = frame.glass[0].path.boundingRect
        #expect(abs(bounds.midX - seed.center.x) < 0.5)
        #expect(abs(bounds.midY - seed.center.y) < 0.5)
        #expect(abs(bounds.width - seed.diameter) < 0.5)
        // The scene is not yet in view inside the drop.
        #expect((frame.scene?.opacity ?? 0) < 0.001)
    }

    @Test func settleFrameIsTheFinishedScene() async {
        let context = await Self.context()
        for entry in [IntroEntry.handoff(Self.symbolsHandoff), .seed] {
            let motion = SceneMotion(entry: entry, context: context)
            let frame = motion.frame(at: motion.settleTime, interaction: IntroInteraction())
            #expect(frame.glass.isEmpty, "\(frame.glass.map(\.id)) \(frame.glass.map(\.path.boundingRect))")
            #expect(frame.glassOpacity == 1)
            guard let scene = frame.scene else {
                Issue.record("the scene should fill the canvas")
                continue
            }
            #expect((scene.lensDiameter ?? 0) >= context.canvas.coveringDiameter(around: context.canvas.graphicCenter) - 0.001)
            #expect(scene.level == Float(SceneReveal.firstLevel + SceneReveal.sweepCount))
            #expect(scene.sweep >= 1.5)
            #expect(scene.opacity == 1)
        }
    }

    @Test func gathersTheHandedOffSymbolsFirst() async {
        let context = await Self.context()
        let motion = SceneMotion(entry: .handoff(Self.symbolsHandoff), context: context)
        let start = motion.frame(at: 0, interaction: IntroInteraction())
        #expect(start.scene == nil)
        #expect(start.glass.filter { $0.id.hasPrefix("bubble.") }.count == GlassIntroPage.defaultScatterSymbols.count)
        let end = motion.frame(at: SceneReveal.orbStart + 0.05, interaction: IntroInteraction())
        #expect(end.glass.filter { $0.id.hasPrefix("bubble.") }.isEmpty)
        #expect(end.scene != nil)
    }

    @Test func theSweepLineCrossesTwice() async {
        let motion = SceneMotion(entry: .handoff(Self.symbolsHandoff), context: await Self.context())
        var crossings = 0
        var sweeping = false
        var time = 0.0
        while time <= motion.settleTime {
            let frame = motion.frame(at: time, interaction: IntroInteraction())
            let now = frame.glass.contains { $0.id == "sweep" }
            if now && !sweeping {
                crossings += 1
            }
            sweeping = now
            time += 1.0 / 60
        }
        #expect(crossings == SceneReveal.sweepCount)
    }

    @Test func theLensGlassClearsWhileItOpens() async {
        let motion = SceneMotion(entry: .handoff(Self.symbolsHandoff), context: await Self.context())
        let reveal = motion.reveal
        #expect(reveal.glassOpacity(at: SceneReveal.glassFadeStart - 0.01) == 1)
        #expect(reveal.glassOpacity(at: SceneReveal.glassFadeStart + 0.1) < 1)
        #expect(reveal.glassOpacity(at: SceneReveal.glassFadeStart + SceneReveal.glassFadeDuration + 0.01) == 0)
        #expect(reveal.glassOpacity(at: SceneReveal.orbEnd + 0.06) == 1)
    }

    @Test func theCubeKeepsTurningAfterSettlingAndFollowsTheViewer() async {
        let motion = SceneMotion(entry: .handoff(Self.symbolsHandoff), context: await Self.context())
        let still = IntroInteraction()
        let first = motion.frame(at: motion.settleTime, interaction: still).scene?.yaw ?? 0
        let later = motion.frame(at: motion.settleTime + 10, interaction: still).scene?.yaw ?? 0
        #expect(later > first)
        let dragged = motion.frame(at: motion.settleTime, interaction: IntroInteraction(yawOffset: 1)).scene?.yaw ?? 0
        #expect(abs(dragged - first - 1) < 1e-4)
        let reduced = motion.frame(at: motion.settleTime + 10, interaction: IntroInteraction(reducesMotion: true)).scene?.yaw ?? 0
        #expect(abs(reduced - 0.6) < 1e-4)
    }

    @Test func handsTheCubesTurnOnToTheNextPicture() async {
        let motion = SceneMotion(entry: .handoff(Self.symbolsHandoff), context: await Self.context())
        let interaction = IntroInteraction(yawOffset: 0.5)
        let time = motion.settleTime + 2
        guard case .scene(let yaw, _, _, _) = motion.handoff(at: time, interaction: interaction) else {
            Issue.record("expected the scene handoff")
            return
        }
        #expect(yaw == motion.frame(at: time, interaction: interaction).scene?.yaw)
    }
}
