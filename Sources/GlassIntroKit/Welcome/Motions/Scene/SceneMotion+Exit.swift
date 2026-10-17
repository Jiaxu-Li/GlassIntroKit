//===--- SceneMotion+Exit.swift - GlassIntroKit -----------------------------===//
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

nonisolated extension SceneMotion {
    /// How much of its leaving the sweep line fades over.
    static let sweepFadeShare = 0.2
    /// The share of the canvas the closing lens covers when the scene
    /// starts to fade out of it.
    static let fadingLensShare: CGFloat = 0.08

    /// The scene gathering into the seed.
    ///
    /// The sweep line is a thin strip that crosses the whole canvas; gathered
    /// with the rest it would sweep across the picture while it shrinks, so
    /// it stays on its own path and fades as the rest gathers. The scene
    /// stays fully lit while the lens closes over the canvas, and fades only
    /// once the lens is small, so that a wide picture never changes
    /// brightness all at once.
    func exitFrame(from frame: IntroFrame, at time: Double, progress: Double) -> IntroFrame {
        let canvas = context.canvas
        var rest = frame
        let sweep = rest.glass.first { $0.id == "sweep" }
        rest.glass.removeAll { $0.id == "sweep" }
        var result = rest.collapsed(into: canvas.seed, progress: progress, canvas: canvas)
        if var sweep {
            let remaining = 1 - Ease.smoother(progress / Self.sweepFadeShare)
            if remaining > 0.001 {
                sweep.opacity *= remaining
                result.glass.append(sweep)
            }
        }
        if var scene = result.scene, let lens = scene.lensDiameter {
            let end = canvas.seed.diameter * 0.97
            let area = canvas.size.width * canvas.size.height * Self.fadingLensShare
            let start = max((area * 4 / .pi).squareRoot(), end + 1)
            scene.opacity = (frame.scene?.opacity ?? 1) * Ease.smoother(Double((lens - end) / (start - end)))
            result.scene = scene
        }
        return result
    }
}
