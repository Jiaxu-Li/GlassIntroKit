//===--- SceneLook.swift - GlassIntroKit ------------------------------------===//
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

/// What a scene page shows, resolved for drawing: the object and its
/// motion, or the page's own view.
nonisolated struct SceneLook: Equatable, Sendable {
    /// The page whose view is shown, when it shows one.
    var customPage: Int?
    /// The shader's shape index: cube, sphere, ring, capsule, cylinder.
    var shape: Int = 0
    /// The object's colour, linear.
    var albedo = SIMD3<Float>(0.80, 0.78, 0.74)
    var motion = GlassIntroScene.Motion.turntable
    var revealsRendering = true
    var isDraggable = true

    static let standard = SceneLook()

    /// The look of `scene`, on page `page` when it shows a view of its own.
    init(_ scene: GlassIntroScene, customPage: Int?) {
        self.customPage = customPage
        shape = GlassIntroScene.Shape.allCases.firstIndex(of: scene.shape) ?? 0
        let colour = scene.color.resolve(in: EnvironmentValues())
        albedo = SIMD3(colour.linearRed, colour.linearGreen, colour.linearBlue)
        motion = scene.motion
        // A view of its own has no levels of rendering to sweep through.
        revealsRendering = scene.revealsRendering && customPage == nil
        isDraggable = scene.isDraggable && customPage == nil
    }

    init() {}

    /// The object `time` seconds after the scene began, turned a further
    /// `yawOffset` by dragging; held at its first pose when it does not
    /// move.
    func pose(at time: Double, yawOffset: Double, moves: Bool) -> ScenePose {
        let t = moves && time.isFinite ? time : 0
        let yaw = Float(0.6 + t * motion.speed + (isDraggable ? yawOffset : 0))
        switch motion.kind {
        case .turntable, .still:
            return ScenePose(yaw: yaw, pitch: 0, lift: 0)
        case .tumble:
            // High enough that a tipped corner never reaches the floor.
            return ScenePose(
                yaw: yaw,
                pitch: Float(0.38 * sin(t * 0.7)),
                lift: Float(0.55 + 0.08 * sin(t * 1.3))
            )
        case .float:
            return ScenePose(yaw: yaw, pitch: 0, lift: Float(0.32 + 0.14 * sin(t * 1.5)))
        }
    }
}

/// Where the object is: its turn about the vertical, its tip toward the
/// camera, and how far it floats, in half-sizes, above the floor.
nonisolated struct ScenePose: Equatable, Sendable {
    var yaw: Float
    var pitch: Float = 0
    var lift: Float = 0
}
