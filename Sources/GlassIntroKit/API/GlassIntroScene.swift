//===--- GlassIntroScene.swift - GlassIntroKit ------------------------------===//
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

/// What a `scene` page renders live behind its glass lens: an object on a
/// studio floor, ray marched with Metal.
///
/// ```swift
/// .scene("Seen in Depth", message: "…",
///        scene: GlassIntroScene(shape: .ring, color: .orange, motion: .float))
/// ```
///
/// To show something of your own instead, such as a `RealityView`, use
/// `GlassIntroPage.scene(_:message:content:)`.
nonisolated public struct GlassIntroScene: Sendable {
    /// The object on the floor.
    public enum Shape: CaseIterable, Hashable, Sendable {
        /// A cube with softened edges.
        case cube
        case sphere
        /// A ring standing on its edge.
        case ring
        /// An upright capsule.
        case capsule
        /// An upright cylinder with softened rims.
        case cylinder
    }

    /// How the object moves while the page is shown.
    public struct Motion: Hashable, Sendable {
        enum Kind: Hashable, Sendable {
            case turntable
            case tumble
            case float
            case still
        }

        let kind: Kind
        /// Radians a second about the vertical.
        let speed: Double

        /// Turns slowly on the floor, as on a turntable.
        public static let turntable = Motion(kind: .turntable, speed: 0.32)
        /// Turns on the floor at `speed` radians a second.
        public static func turntable(speed: Double) -> Motion {
            Motion(kind: .turntable, speed: speed)
        }
        /// Floats above the floor, turning and tipping as it goes.
        public static let tumble = Motion(kind: .tumble, speed: 0.45)
        /// Floats above the floor, rising and falling as it turns.
        public static let float = Motion(kind: .float, speed: 0.22)
        /// Stays where it is until it is dragged.
        public static let still = Motion(kind: .still, speed: 0)
    }

    /// The object on the floor.
    public var shape: Shape
    /// The object's colour, lit by the studio's lights.
    public var color: Color
    /// How the object moves while the page is shown.
    public var motion: Motion
    /// Whether the scene first shows as a flat shape and is raised level by
    /// level, by a line of glass sweeping across it, to full lighting with
    /// shadows and reflections. Otherwise it opens fully lit.
    public var revealsRendering: Bool
    /// Whether dragging across the page turns the object.
    public var isDraggable: Bool

    public init(
        shape: Shape = .cube,
        color: Color = Color(red: 0.91, green: 0.90, blue: 0.88),
        motion: Motion = .turntable,
        revealsRendering: Bool = true,
        isDraggable: Bool = true
    ) {
        self.shape = shape
        self.color = color
        self.motion = motion
        self.revealsRendering = revealsRendering
        self.isDraggable = isDraggable
    }
}
