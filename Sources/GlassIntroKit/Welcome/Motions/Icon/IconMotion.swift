//===--- IconMotion.swift - GlassIntroKit -----------------------------------===//
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

/// Glass gathers into an app icon, polished and badged.
///
/// After the physics page the fallen nodes lift off their platform and flow
/// into the icon. From anywhere else the seed itself swells into the icon.
nonisolated struct IconMotion: PageMotion {
    let context: IntroContext
    let reveal: IconReveal
    /// Whether the icon grows out of the seed rather than the fallen nodes.
    private let growsFromSeed: Bool

    static func continues(from handoff: IntroHandoff) -> Bool {
        if case .fallen = handoff {
            return true
        }
        return false
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
        let canvas = context.canvas
        if case .handoff(.fallen(let fallen)) = entry {
            reveal = IconReveal(canvasSize: canvas.size, start: fallen, center: canvas.graphicCenter)
            growsFromSeed = false
        } else {
            reveal = IconReveal(canvasSize: canvas.size, seed: canvas.seed)
            growsFromSeed = true
        }
    }

    var settleTime: Double {
        reveal.settleTime
    }

    var textTime: Double {
        reveal.textTime
    }

    /// The seed is the icon's first shape when the icon grows from it.
    var absorbsSeed: Bool {
        growsFromSeed
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        IntroFrame(icon: reveal.frame(at: time), symbols: context.symbols)
    }

    /// The icon gathers into the seed as any picture does, and the light
    /// polishing across it goes with it.
    func exitFrame(from frame: IntroFrame, at time: Double, progress: Double) -> IntroFrame {
        let seed = context.canvas.seed
        var result = frame.collapsed(into: seed, progress: progress, canvas: context.canvas)
        guard progress < 1 else {
            return result
        }
        let travel = Ease.smoother(progress)
        let shrink = CGFloat(1 - travel)
        result.sheens = frame.sheens.map { sheen in
            var sheen = sheen
            let center = Ease.lerp(CGPoint(x: sheen.rect.midX, y: sheen.rect.midY), seed.center, travel)
            let size = CGSize(width: sheen.rect.width * shrink, height: sheen.rect.height * shrink)
            sheen.rect = CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            sheen.cornerRadius *= shrink
            return sheen
        }
        return result
    }
}
