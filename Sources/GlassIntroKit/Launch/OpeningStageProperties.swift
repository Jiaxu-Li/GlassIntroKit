//===--- OpeningStageProperties.swift - GlassIntroKit -----------------------===//
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

/// Every animated value of the opening stage. The sequence changes one group
/// at a time inside its own animation, so each step keeps its own curve.
/// Lengths are in the stage's design points and scale with the canvas.
nonisolated struct OpeningStageProperties: Equatable, Sendable {
    var animateMainCircle = false
    var circleSize: CGFloat = 50
    var circleOffset: CGFloat = 0
    var circleScale: CGFloat = 0
    var positionCircles = false
    var animateStrokes = false
    var animateGridLines = false
    var animateDiagonalLines = false
    var whitensStage = false
    var convertToLogo = false
    var dissolvesMark = false

    /// The values once the stage has closed onto the mark.
    static var closed: Self {
        var properties = Self()
        properties.animateMainCircle = true
        properties.circleScale = 1
        properties.circleOffset = 50
        properties.circleSize = 5
        properties.positionCircles = true
        properties.animateStrokes = true
        properties.animateGridLines = true
        properties.animateDiagonalLines = true
        properties.whitensStage = true
        properties.convertToLogo = true
        return properties
    }
}

/// The opening's construction, from the empty canvas to the closed mark,
/// played step by step, each after its delay and inside its own animation.
nonisolated enum OpeningTimeline {
    struct Step: Sendable {
        let delay: Double
        let animation: Animation
        let change: @Sendable (inout OpeningStageProperties) -> Void
    }

    static let construction: [Step] = [
        // The canvas rests empty for a moment before anything moves. The
        // stage then opens on the same family of curve it later closes on:
        // a quick start and a long, quiet settle.
        Step(delay: 1.0, animation: .timingCurve(0.2, 0, 0, 1, duration: 0.80)) {
            $0.animateMainCircle = true
        },
        Step(delay: 0.20, animation: .bouncy(duration: 0.45, extraBounce: 0.15)) {
            $0.circleScale = 1
        },
        Step(delay: 0.28, animation: .bouncy(duration: 0.56)) {
            $0.circleOffset = 50
        },
        Step(delay: 0.11, animation: .bouncy(duration: 0.50)) {
            $0.circleSize = 5
        },
        Step(delay: 0.25, animation: .smooth(duration: 0.50)) {
            $0.positionCircles = true
        },
        // The rings start drawing the moment the points land, and each point
        // carries on as its ring's tip. The drawing shares one curve, so
        // every line arrives with the same finish.
        Step(delay: 0.60, animation: .openingDrawing(duration: 0.90)) {
            $0.animateStrokes = true
        },
        Step(delay: 0.28, animation: .openingDrawing(duration: 0.60)) {
            $0.animateGridLines = true
        },
        Step(delay: 0.15, animation: .openingDrawing(duration: 0.55)) {
            $0.animateDiagonalLines = true
        },
        // White spreads from the center as the drawing clears, and the white
        // stage then draws back in as a circle onto the mark's body: one
        // breath out and in, with a beat of pure white between. The close
        // starts gently, gathers pace, and lands softly.
        Step(delay: 0.35, animation: .timingCurve(0.3, 0, 0.15, 1, duration: 0.55)) {
            $0.whitensStage = true
        },
        Step(delay: 0.62, animation: .timingCurve(0.6, 0, 0.2, 1, duration: 0.85)) {
            $0.convertToLogo = true
        },
    ]
}
