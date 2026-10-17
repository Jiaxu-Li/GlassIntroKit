//===--- PhysicsFrame.swift - GlassIntroKit ---------------------------------===//
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

/// One falling node in one frame.
nonisolated struct PhysicsNodeFrame: Identifiable, Sendable {
    let id: Int
    let symbol: String
    let center: CGPoint
    /// Its turn, in radians.
    let angle: Double
    let size: CGSize
    let cornerRadius: CGFloat
    let symbolSize: CGFloat
}

/// One grain of dust thrown up by an impact.
nonisolated struct PhysicsParticle: Sendable {
    let center: CGPoint
    let diameter: CGFloat
    let opacity: Double
}

/// The physics page in one frame.
nonisolated struct PhysicsFrame: Sendable {
    /// The graph page's wires as they draw back.
    var wires: [Path] = []
    var nodes: [PhysicsNodeFrame] = []
    /// The thin line the nodes land on.
    var platformCenter: CGPoint = .zero
    var platformWidth: CGFloat = 0
    var particles: [PhysicsParticle] = []
    /// The graph page's beads as they shrink away with its wires, and their
    /// diameter.
    var beads: [CGPoint] = []
    var beadDiameter: CGFloat = 0
}
