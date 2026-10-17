//===--- GraphMotion.swift - GlassIntroKit ----------------------------------===//
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

/// A wire shoots out of a glass point and three nodes grow.
///
/// After the live scene, the lens the scene opened through closes over it
/// again, leaving the scene held still where the viewer left it, down to
/// a glass point. After any other picture the glass drop shrinks to the
/// point instead. Either way a wire shoots out of the point and the nodes
/// grow out of beads along it.
nonisolated struct GraphMotion: PageMotion {
    let context: IntroContext
    let reveal: GraphReveal
    /// The scene's object, held where it was, when the scene is still seen
    /// through the closing lens; nil when the graph grows from the seed.
    let heldPose: ScenePose?
    let heldLook: SceneLook
    /// Where the object sits, as a fraction of the canvas.
    let cubeCenter: CGPoint

    static func continues(from handoff: IntroHandoff) -> Bool {
        if case .scene = handoff {
            return true
        }
        return false
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
        let canvas = context.canvas
        let scene = SceneReveal(canvasSize: canvas.size, center: canvas.graphicCenter)
        cubeCenter = scene.centerFraction
        if case .handoff(.scene(let yaw, let pitch, let lift, let look)) = entry {
            heldPose = ScenePose(yaw: yaw, pitch: pitch, lift: lift)
            heldLook = look
            reveal = GraphReveal(canvasSize: canvas.size, reveal: scene, graph: context.nodeGraph)
        } else {
            heldPose = nil
            heldLook = .standard
            reveal = GraphReveal(
                canvasSize: canvas.size,
                reveal: scene,
                graph: context.nodeGraph,
                seedDiameter: canvas.seed.diameter
            )
        }
    }

    var settleTime: Double {
        reveal.settleTime
    }

    var textTime: Double {
        reveal.textTime
    }

    /// The graph grows out of the seed itself when it comes from anything
    /// but the scene.
    var absorbsSeed: Bool {
        true
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .graph(reveal.frame(at: max(time, settleTime)))
    }
}
