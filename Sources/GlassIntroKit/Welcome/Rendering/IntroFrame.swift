//===--- IntroFrame.swift - GlassIntroKit -----------------------------------===//
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

/// Everything the welcome draws in one frame, in canvas coordinates.
///
/// Pictures describe themselves as frames and never draw; one renderer
/// draws every frame. Because a frame is plain data, a picture can be
/// collapsed into the seed, compared with the frame before it, and tested
/// without a window.
nonisolated struct IntroFrame: Sendable {
    /// Glass in one shared container: pieces close together flow into one.
    var glass: [GlassPiece] = []
    /// Glass that never flows into anything, such as falling tiles.
    var looseGlass: [GlassPiece] = []
    /// How much of the shared glass shows.
    var glassOpacity: Double = 1
    var symbols: [SymbolSprite] = []
    var lines: [LineSprite] = []
    var particles: [ParticleSprite] = []
    var sheens: [SheenSprite] = []
    /// The live Metal scene, seen through a lens or across the canvas.
    var scene: SceneSprite?
    /// The mark in colour.
    var mark: MarkSprite?
    /// A page's own view, shown on glass.
    var card: CardSprite?

    /// Only the seed, at full size.
    static func seed(_ seed: GlassSeed) -> IntroFrame {
        IntroFrame(glass: [seed.piece()])
    }
}

/// A piece of glass, its outline already placed on the canvas.
nonisolated struct GlassPiece: Identifiable, Sendable {
    /// Stable from frame to frame, so the same glass keeps its identity.
    let id: String
    var path: Path
    var blur: CGFloat = 0
    var opacity: Double = 1
    /// How much white the glass is tinted with, so that glass that must be
    /// read, such as words, shows against a plain backdrop.
    var tint: Double = 0
}

/// An SF Symbol drawn in white, centered on `center`.
nonisolated struct SymbolSprite: Identifiable, Sendable {
    let id: String
    var name: String
    var center: CGPoint
    /// The symbol's point size.
    var size: CGFloat
    var weight: Font.Weight = .medium
    /// Its turn, in radians.
    var angle: Double = 0
    var scale: CGFloat = 1
    var opacity: Double = 1
}

/// A thin, bright line, such as the one the falling tiles land on.
nonisolated struct LineSprite: Identifiable, Sendable {
    let id: String
    var center: CGPoint
    var width: CGFloat
    var thickness: CGFloat = 1.5
    var opacity: Double = 0.55
}

/// A grain of dust.
nonisolated struct ParticleSprite: Sendable {
    var center: CGPoint
    var diameter: CGFloat
    var opacity: Double
}

/// A soft diagonal band of light crossing a rounded square once.
nonisolated struct SheenSprite: Identifiable, Sendable {
    let id: String
    var rect: CGRect
    var cornerRadius: CGFloat
    /// How far across the band has travelled.
    var progress: Double
}

/// The live Metal scene.
nonisolated struct SceneSprite: Sendable {
    /// The circle the scene shows through, or nil across the whole canvas.
    var lensDiameter: CGFloat?
    var lensCenter: CGPoint
    /// Where the object sits, as a fraction of the canvas.
    var cubeCenter: CGPoint
    /// The level left of the sweep line; the right keeps one less.
    var level: Float
    /// The sweep line as a fraction of the width; past 1 when none runs.
    var sweep: Float
    var yaw: Float
    var opacity: Double = 1
    /// The object's tip toward the camera, and how far it floats.
    var pitch: Float = 0
    var lift: Float = 0
    /// The object and its colour, or the page's own view.
    var look = SceneLook.standard

    var pose: ScenePose {
        get { ScenePose(yaw: yaw, pitch: pitch, lift: lift) }
        set {
            yaw = newValue.yaw
            pitch = newValue.pitch
            lift = newValue.lift
        }
    }
}

/// The mark in colour: its body, and its detail coming into focus.
nonisolated struct MarkSprite: Sendable {
    var center: CGPoint
    var scale: CGFloat
    /// How much of the mark's detail shows over its body.
    var detail: Double
    var opacity: Double
    /// For the welcome's ending: how far colour has spread from the mark's
    /// light, the glow around it, and the swell that comes with it. Nil
    /// draws the mark plainly.
    var colour: Double?
    var glow: Double = 0
    var swell: CGFloat = 1
}

/// A page's own view, on a glass card. The card's glass is one of the
/// frame's glass pieces; this places the view on it.
nonisolated struct CardSprite: Sendable {
    /// The page whose view is shown.
    var page: Int
    var rect: CGRect
    var contentOpacity: Double
    var contentScale: CGFloat
}
