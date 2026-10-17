//===--- SceneMotion.swift - GlassIntroKit ----------------------------------===//
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

/// A glass lens opens over a live Metal scene.
///
/// Following the symbols page, the scattered symbols gather back into the
/// center symbol, which melts into the lens. Growing out of the seed, the
/// drop itself swells into the lens. Either way the lens opens over the
/// canvas, and a sweep line crosses the scene twice, raising it a level each
/// time. The cube keeps turning once the picture is at rest.
nonisolated struct SceneMotion: PageMotion {
    let context: IntroContext
    let reveal: SceneReveal
    let layout: HelloLayout
    /// The symbols page being gathered, when the picture follows it.
    let gathering: Gathering?
    /// How far into the reveal's own timeline the picture begins: nothing
    /// when it gathers the symbols, the swelling of the lens when it grows
    /// out of the seed.
    private let skip: Double

    /// The symbols page as it was left: its scatter, and the page context
    /// with the center symbol it melted into.
    struct Gathering: Sendable {
        let scatter: SymbolScatter
        let context: IntroContext
    }

    static func continues(from handoff: IntroHandoff) -> Bool {
        if case .symbols = handoff {
            return true
        }
        return false
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
        let canvas = context.canvas
        reveal = SceneReveal(
            canvasSize: canvas.size,
            center: canvas.graphicCenter,
            revealsRendering: context.scene.revealsRendering
        )
        layout = .resting(in: canvas)
        if case .handoff(.symbols(let symbols, let center)) = entry {
            gathering = Gathering(
                scatter: SymbolScatter(canvasSize: canvas.size, center: canvas.graphicCenter, symbols: symbols),
                context: IntroContext(
                    canvas: canvas,
                    markOutline: context.markOutline,
                    outlines: context.outlines,
                    page: context.page,
                    symbols: context.symbols,
                    centerSymbol: center,
                    scene: context.scene,
                    markSymbol: context.markSymbol,
                    words: context.words,
                    textTop: context.textTop
                )
            )
            skip = 0
        } else {
            gathering = nil
            skip = SceneReveal.orbStart
        }
    }

    var settleTime: Double {
        reveal.end - skip
    }

    var textTime: Double {
        reveal.textStart - skip
    }

    var isLive: Bool {
        true
    }

    var isInteractive: Bool {
        context.scene.isDraggable
    }

    var absorbsSeed: Bool {
        true
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        let time = max(time, 0)
        let revealTime = time + skip
        let scene = reveal.scene(at: revealTime, orbFrom: gathering == nil ? context.canvas.seed.diameter : 0)

        var frame = IntroFrame()
        frame.glassOpacity = reveal.glassOpacity(at: revealTime)
        frame.glass = glass(at: revealTime, sweep: scene.sweep)
        frame.scene = sprite(scene, pose: pose(at: time, interaction: interaction), at: time)
        return frame
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        let pose = pose(at: max(time, 0), interaction: interaction)
        return .scene(yaw: pose.yaw, pitch: pose.pitch, lift: pose.lift, look: context.scene)
    }

    /// The object `time` seconds after the picture began.
    private func pose(at time: Double, interaction: IntroInteraction) -> ScenePose {
        context.scene.pose(at: time, yawOffset: interaction.yawOffset, moves: !interaction.reducesMotion)
    }

    /// The scene through the lens, once the lens has begun to open. Grown
    /// out of the seed it comes into view as the drop swells, so it never
    /// appears all at once inside it.
    private func sprite(_ scene: SceneRevealFrame, pose: ScenePose, at time: Double) -> SceneSprite? {
        guard time + skip >= SceneReveal.orbStart else {
            return nil
        }
        var sprite = SceneSprite(
            lensDiameter: scene.lensDiameter,
            lensCenter: reveal.center,
            cubeCenter: reveal.centerFraction,
            level: scene.level,
            sweep: scene.sweep,
            yaw: pose.yaw,
            opacity: gathering == nil ? Ease.smoother(time / SceneReveal.seedSceneFade) : 1,
            look: context.scene
        )
        sprite.pose = pose
        return sprite
    }
}
