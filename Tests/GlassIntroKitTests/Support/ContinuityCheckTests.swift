//===--- ContinuityCheckTests.swift - GlassIntroKit -------------------------===//
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

/// The jump finder itself: it must catch a jump, also during other motion,
/// and must not mistake fast, smooth motion for one.
@Suite struct ContinuityCheckTests {
    private let canvas = IntroCanvas(size: CGSize(width: 1200, height: 800), bodyDiameterRatio: 0.76)

    nonisolated private static func circle(_ id: String, at center: CGPoint, diameter: CGFloat) -> GlassPiece {
        GlassPiece(id: id, path: Path(ellipseIn: CGRect(
            x: center.x - diameter / 2,
            y: center.y - diameter / 2,
            width: diameter,
            height: diameter
        )))
    }

    @Test func catchesAPieceAppearingAtOnce() {
        let check = ContinuityCheck(canvas: canvas) { time in
            IntroFrame(glass: time < 0.5 ? [] : [Self.circle("a", at: CGPoint(x: 600, y: 300), diameter: 100)])
        }
        let jumps = check.jumps(from: 0, to: 1)
        #expect(jumps.count == 1)
        #expect(abs((jumps.first?.time ?? 0) - 0.5) < 0.001)
    }

    @Test func catchesAJumpDuringFastMotion() {
        let check = ContinuityCheck(canvas: canvas) { time in
            var glass = [Self.circle("moving", at: CGPoint(x: 100 + 1500 * time, y: 400), diameter: 300)]
            if time >= 0.37 {
                glass.append(Self.circle("popped", at: CGPoint(x: 900, y: 150), diameter: 60))
            }
            return IntroFrame(glass: glass)
        }
        #expect(check.jumps(from: 0, to: 0.7).contains { abs($0.time - 0.37) < 0.001 })
    }

    @Test func fastSmoothMotionIsNotAJump() {
        let check = ContinuityCheck(canvas: canvas) { time in
            let growth = Ease.spring(time, period: 0.6, damping: 0.6)
            return IntroFrame(glass: [Self.circle("grow", at: CGPoint(x: 600, y: 400), diameter: 20 + 1800 * growth)])
        }
        #expect(check.jumps(from: 0, to: 2).isEmpty)
    }
}
