//===--- GraphFrame.swift - GlassIntroKit -----------------------------------===//
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

/// One node of the graph page in one frame.
nonisolated struct GraphNodeFrame: Identifiable, Sendable {
    let id: Int
    let symbol: String
    /// The node's shape as it grows out of its port: a bead at first,
    /// swelling to the right into a rounded tile.
    let rect: CGRect
    let cornerRadius: CGFloat
    /// The symbol comes in once the tile has mostly grown.
    let symbolOpacity: Double
    let symbolScale: CGFloat
    /// The symbol's size on the finished tile, so it does not grow with it.
    let symbolSize: CGFloat
}

/// The graph page in one frame.
nonisolated struct GraphFrame: Sendable {
    /// The lens closing over the scene, and the scene still seen through it.
    var orbDiameter: CGFloat = 0
    var lensDiameter: CGFloat?
    /// How much of the scene shows through the lens: it clears away just
    /// before the lens is a point, so the last of it does not vanish at once.
    var sceneOpacity: Double = 1
    /// The wires' centerlines, drawn as far as they have come.
    var wires: [Path] = []
    /// Glass beads: the point the wire is drawn from, and the ports.
    var beads: [CGPoint] = []
    /// Each bead's diameter, where it is still swelling; a bead past the
    /// end of this list is full size.
    var beadDiameters: [CGFloat] = []
    var nodes: [GraphNodeFrame] = []
}
