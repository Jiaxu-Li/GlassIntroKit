//===--- MarkBloom.swift - GlassIntroKit ------------------------------------===//
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

/// The seed turning into the mark: the drop swells to the mark's full body,
/// breathing once as its detail opens.
nonisolated struct MarkBloom: Sendable {
    static let swellDuration = 0.45
    static let apertureStart = 0.15
    static let apertureDuration = 0.45
    static let pulseStart = 0.15
    static let pulseDuration = 0.7
    /// How much larger the body gets, at the most, as it breathes.
    static let pulseSize = 0.05
    static let textStart = 0.5
    static let end = 1.0

    let layout: HelloLayout
    let center: CGPoint
    /// The seed's diameter, and the mark's full body.
    let seedDiameter: CGFloat
    let fullDiameter: CGFloat
    /// The diameter the glass frame takes as the pen's point.
    let pointDiameter: CGFloat

    init(canvas: IntroCanvas) {
        layout = HelloLayout.resting(in: canvas)
        center = canvas.graphicCenter
        seedDiameter = canvas.seed.diameter
        fullDiameter = canvas.markDimension * canvas.bodyDiameterRatio
        pointDiameter = layout.lineWidth(at: 1)
    }

    /// The glass's state `time` seconds in.
    func glassFrame(at time: Double) -> GlassFrame {
        let swell = Ease.smoother(time / Self.swellDuration)
        let pulse = Self.pulse(at: time)
        let diameter = (seedDiameter + (fullDiameter - seedDiameter) * CGFloat(swell)) * CGFloat(1 + Self.pulseSize * pulse)
        var frame = GlassFrame()
        frame.markCenter = center
        frame.markGrowth = Double((diameter - pointDiameter) / max(fullDiameter - pointDiameter, 1))
        frame.apertureOpening = Ease.smoothstep((time - Self.apertureStart) / Self.apertureDuration)
        return frame
    }

    /// One breath: a quick swell that settles back, 0 before and after.
    static func pulse(at time: Double) -> Double {
        let progress = (time - pulseStart) / pulseDuration
        guard progress > 0, progress < 1 else {
            return 0
        }
        let swell = sin(Double.pi * progress)
        return swell * swell * (1 - progress) * 1.8
    }
}
