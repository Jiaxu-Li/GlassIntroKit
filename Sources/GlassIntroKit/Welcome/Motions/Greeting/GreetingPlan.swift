//===--- GreetingPlan.swift - GlassIntroKit ---------------------------------===//
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

/// The greeting's geometry and timing for one canvas: the mark gathers into
/// the pen's point, sweeps into the start of the word and arrives at the
/// pen's own speed and heading, so it writes on without a pause.
nonisolated struct GreetingPlan: Sendable {
    /// Where the greeting begins.
    enum Start: Sendable {
        /// The mark in colour at the canvas's center, resting a moment on
        /// the black before it gathers.
        case launch
        /// The glass seed at the pictures' center, which gathers almost at
        /// once.
        case seed
    }

    static let launchRest = 1.5
    static let seedRest = 0.15
    static let shrinkDuration = 0.95
    /// How long after it starts to gather the point sets off for the word.
    static let approachDelay = 0.35
    static let approachDuration = 0.8
    static let writingDuration = 3.2
    static let tipFadeDuration = 0.5
    /// How much of the writing has been drawn when the text comes in.
    static let textShare = 0.72

    /// The pen's point as the greeting sees it at one moment.
    struct Pen: Sendable {
        var center: CGPoint
        /// The point's diameter on screen.
        var diameter: CGFloat
        /// How much of the mark's detail is still in focus.
        var detail: Double
        /// How far the word is written.
        var progress: Double
        /// How much of the point shows: it goes out once the word is done.
        var opacity: Double
    }

    let canvas: IntroCanvas
    let layout: HelloLayout
    /// Where the point gathers from: the mark's rest, or the seed.
    let origin: CGPoint
    let shrinkStart: Double
    private let approach: (CGPoint, CGPoint, CGPoint, CGPoint)
    private let writingCurve: UnitCurve

    /// The approach eases in and ends at a steady speed rather than braking.
    private static let approachCurve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.45, y: 0),
        endControlPoint: UnitPoint(x: 0.65, y: 0.65)
    )

    private static let shrinkCurve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.45, y: 0),
        endControlPoint: UnitPoint(x: 0.2, y: 1)
    )

    init(canvas: IntroCanvas, start: Start) {
        self.canvas = canvas
        layout = HelloLayout.resting(in: canvas)
        switch start {
        case .launch:
            origin = canvas.center
            shrinkStart = Self.launchRest
        case .seed:
            origin = canvas.seed.center
            shrinkStart = Self.seedRest
        }

        // The pen's heading and speed as it sets off.
        let step = 0.002
        let first = layout.penPoint(at: 0)
        let ahead = layout.penPoint(at: step)
        let travel = max(hypot(ahead.x - first.x, ahead.y - first.y), 0.0001)
        let heading = CGPoint(x: (ahead.x - first.x) / travel, y: (ahead.y - first.y) / travel)

        // The point leaves its place toward the start and curls in along
        // the pen's heading.
        let distance = hypot(first.x - origin.x, first.y - origin.y)
        let lead = max(distance * 0.5, 24)
        let p1 = CGPoint(
            x: origin.x + (first.x - origin.x) * 0.25,
            y: origin.y + (first.y - origin.y) * 0.25
        )
        let p2 = CGPoint(x: first.x - heading.x * lead, y: first.y - heading.y * lead)
        approach = (origin, p1, p2, first)

        // The writing sets off at the speed the point arrives with.
        let arrivalSpeed = 3 * lead / Self.approachDuration
        let penSpeed = travel / step / Self.writingDuration
        let initialSlope = min(max(arrivalSpeed / penSpeed, 0.05), 2)
        writingCurve = UnitCurve.bezier(
            startControlPoint: UnitPoint(x: 0.2, y: 0.2 * initialSlope),
            endControlPoint: UnitPoint(x: 0.4, y: 1)
        )
    }

    var approachStart: Double {
        shrinkStart + Self.approachDelay
    }

    var writingStart: Double {
        approachStart + Self.approachDuration
    }

    /// When the word is written and the point has gone out.
    var end: Double {
        writingStart + Self.writingDuration + Self.tipFadeDuration
    }

    /// When the text comes in, shortly before the last strokes.
    var textTime: Double {
        writingStart + Self.writingDuration * Self.textShare
    }

    /// The point's diameter once gathered: the pen's own thickness.
    var pointDiameter: CGFloat {
        layout.lineWidth(at: 0)
    }

    /// The pen's point `time` seconds into the greeting.
    func pen(at time: Double) -> Pen {
        if time >= writingStart {
            let elapsed = Ease.clamp((time - writingStart) / Self.writingDuration)
            let progress = writingCurve.value(at: elapsed)
            let fade = (time - writingStart - Self.writingDuration) / Self.tipFadeDuration
            return Pen(
                center: layout.penPoint(at: progress),
                diameter: layout.lineWidth(at: progress),
                detail: 0,
                progress: progress,
                opacity: 1 - Ease.clamp(fade)
            )
        }

        // The mark gathers evenly to the eye: its size falls at a steady
        // ratio rather than by steady amounts, and its light goes out first.
        let shrink = Self.shrinkCurve.value(at: Ease.clamp((time - shrinkStart) / Self.shrinkDuration))
        let body = max(canvas.bodyDiameter, 1)
        let pointScale = max(pointDiameter / body, 0.000_001)
        let scale = exp(log(pointScale) * shrink)
        let fading = Ease.clamp((time - shrinkStart) / (Self.shrinkDuration * 0.55))
        let travel = Self.approachCurve.value(at: Ease.clamp((time - approachStart) / Self.approachDuration))
        return Pen(
            center: bezier(travel),
            diameter: canvas.bodyDiameter * scale,
            detail: 1 - Ease.smoothstep(fading),
            progress: 0,
            opacity: 1
        )
    }

    private func bezier(_ t: Double) -> CGPoint {
        let (p0, p1, p2, p3) = approach
        let t = CGFloat(t)
        let u = 1 - t
        let a = u * u * u
        let b = 3 * u * u * t
        let c = 3 * u * t * t
        let d = t * t * t
        return CGPoint(
            x: a * p0.x + b * p1.x + c * p2.x + d * p3.x,
            y: a * p0.y + b * p1.y + c * p2.y + d * p3.y
        )
    }
}
