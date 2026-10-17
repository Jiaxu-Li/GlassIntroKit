//===--- MarkTurn.swift - GlassIntroKit -------------------------------------===//
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

/// The word turning into the mark: the word is taken back from its start
/// while the view travels after it, so the word's last point arrives where
/// the mark will sit; the point then grows into the mark with a little
/// life, and the mark's detail opens after it.
nonisolated struct MarkTurn: Sendable {
    static let eraseDuration = 1.0
    static let travelStart = 0.1
    static let travelDuration = 1.05
    static let growthStart = 1.1
    static let apertureStart = 1.3
    static let apertureDuration = 0.45
    static let textStart = 1.5
    static let end = 2.0

    /// The word is taken back with the pen's own unhurried pace.
    private static let eraseCurve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.4, y: 0),
        endControlPoint: UnitPoint(x: 0.35, y: 1)
    )

    /// The view sets off after the word, gathers pace, and comes to rest
    /// with the last point where the mark will form.
    private static let travelCurve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.5, y: 0),
        endControlPoint: UnitPoint(x: 0.3, y: 1)
    )

    let layout: HelloLayout
    /// Where the mark comes to rest.
    let destination: CGPoint

    init(canvas: IntroCanvas) {
        layout = HelloLayout.resting(in: canvas)
        destination = canvas.graphicCenter
    }

    /// The glass's state `time` seconds into the turn.
    func glassFrame(at time: Double) -> GlassFrame {
        let erased = Self.eraseCurve.value(at: Ease.clamp(time / Self.eraseDuration))
        let travel = Self.travelCurve.value(at: Ease.clamp((time - Self.travelStart) / Self.travelDuration))
        let end = layout.penPoint(at: 1)
        let offset = CGSize(
            width: (destination.x - end.x) * travel,
            height: (destination.y - end.y) * travel
        )
        var frame = GlassFrame(from: erased, through: 1, travel: offset)
        // The last point stays as the word runs out, then grows into the
        // mark with a little life, and the aperture opens after it.
        if time >= Self.eraseDuration - 0.05 {
            frame.markCenter = CGPoint(x: end.x + offset.width, y: end.y + offset.height)
            frame.markGrowth = Self.growth(at: time)
            frame.apertureOpening = Ease.smoothstep((time - Self.apertureStart) / Self.apertureDuration)
        }
        return frame
    }

    /// How far the point has grown into the mark: a lightly underdamped
    /// spring, whose last tremor is eased out so the mark is exactly full
    /// when the turn ends.
    static func growth(at time: Double) -> Double {
        let elapsed = time - growthStart
        guard elapsed > 0 else {
            return 0
        }
        let spring = Ease.spring(elapsed, period: 0.75, damping: 0.7)
        let span = end - growthStart
        let settling = Ease.smoother((elapsed - span * 0.35) / (span * 0.65))
        return spring + (1 - spring) * settling
    }
}
