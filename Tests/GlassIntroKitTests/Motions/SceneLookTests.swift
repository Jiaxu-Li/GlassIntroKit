//===--- SceneLookTests.swift - GlassIntroKit -------------------------------===//
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

@Suite struct SceneLookTests {
    /// Every shape fills a half-size this wide; the floor is at its foot.
    private static let half: Float = 0.42

    @Test(arguments: [GlassIntroScene.Motion.tumble, .float])
    func aFloatingObjectNeverReachesTheFloor(motion: GlassIntroScene.Motion) {
        let look = SceneLook(GlassIntroScene(shape: .cube, motion: motion), customPage: nil)
        for step in 0..<2000 {
            let pose = look.pose(at: Double(step) * 0.01, yawOffset: 0, moves: true)
            // A cube tipped by `pitch` reaches this far below its center.
            let reach = Self.half * (cos(abs(pose.pitch)) + sin(abs(pose.pitch)))
            #expect(pose.lift * Self.half - (reach - Self.half) >= 0, "at \(Double(step) * 0.01)s")
        }
    }

    @Test func eachMotionMovesAsNamed() {
        func look(_ motion: GlassIntroScene.Motion) -> SceneLook {
            SceneLook(GlassIntroScene(motion: motion), customPage: nil)
        }
        let still = look(.still)
        #expect(still.pose(at: 0, yawOffset: 0, moves: true) == still.pose(at: 10, yawOffset: 0, moves: true))
        let turning = look(.turntable(speed: 1))
        #expect(abs(turning.pose(at: 2, yawOffset: 0, moves: true).yaw - 2.6) < 1e-5)
        #expect(turning.pose(at: 2, yawOffset: 0, moves: true).lift == 0)
        // Reduce Motion holds every object at its first pose.
        #expect(turning.pose(at: 5, yawOffset: 0, moves: false) == turning.pose(at: 0, yawOffset: 0, moves: false))
    }

    @Test func draggingTurnsOnlyAnObjectThatAllowsIt() {
        let draggable = SceneLook(GlassIntroScene(motion: .still), customPage: nil)
        let fixed = SceneLook(GlassIntroScene(motion: .still, isDraggable: false), customPage: nil)
        #expect(draggable.pose(at: 0, yawOffset: 1, moves: true).yaw == 1.6)
        #expect(fixed.pose(at: 0, yawOffset: 1, moves: true).yaw == 0.6)
    }

    @Test func aViewOfYourOwnIsNotSweptOrDragged() {
        let look = SceneLook(GlassIntroScene(), customPage: 2)
        #expect(look.customPage == 2)
        #expect(!look.revealsRendering)
        #expect(!look.isDraggable)
    }

    @Test func shapesAndColoursReachTheShader() {
        let look = SceneLook(GlassIntroScene(shape: .ring, color: Color(red: 1, green: 0, blue: 0)), customPage: nil)
        #expect(look.shape == 2)
        #expect(abs(look.albedo.x - 1) < 0.01 && look.albedo.y < 0.01 && look.albedo.z < 0.01)
    }

    @Test func aSceneThatOpensLitSettlesSooner() {
        let size = CGSize(width: 1200, height: 800)
        let swept = SceneReveal(canvasSize: size, center: CGPoint(x: 600, y: 290))
        let lit = SceneReveal(canvasSize: size, center: CGPoint(x: 600, y: 290), revealsRendering: false)
        #expect(lit.end < swept.end)
        #expect(lit.scene(at: SceneReveal.orbStart + 0.1).level == Float(SceneReveal.finalLevel))
        #expect(swept.scene(at: SceneReveal.orbStart + 0.1).level == Float(SceneReveal.firstLevel))
    }
}
