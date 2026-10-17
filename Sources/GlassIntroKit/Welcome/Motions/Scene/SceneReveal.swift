//===--- SceneReveal.swift - GlassIntroKit ----------------------------------===//
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

/// The rendered scene in one frame.
nonisolated struct SceneRevealFrame: Sendable {
    /// The circle the scene shows through; once it fills the canvas, one
    /// wide enough to reach past every corner.
    var lensDiameter: CGFloat?
    /// The level left of the sweep line; the right keeps one less.
    var level: Float
    /// The sweep line as a fraction of the width; past 1 when none runs.
    var sweep: Float

    var isSweeping: Bool {
        sweep < 1.5
    }
}

/// The scene page's movement: everything gathers back into the center symbol,
/// which melts into a glass lens with a live Metal scene behind it. The
/// lens opens over the whole canvas, and a sweep line then crosses the
/// scene twice, each time raising it a level: from a cube in direct
/// light to shadows and physically based highlights, then to bounce light
/// and reflections.
nonisolated struct SceneReveal: Sendable {
    /// How much faster than it played the scatter gathers back.
    static let gatherSpeed = 2.4
    static let orbStart = (SymbolScatter.gatherFrom - SymbolScatter.emergeStart) / gatherSpeed
    static let centerOutDuration = 0.5
    static let expandStart = orbStart + 1.16
    static let expandDuration = 0.9
    static let glassFadeStart = orbStart + 1.71
    static let orbEnd = orbStart + 2.16
    /// The lens's glass clears once its rim has left the canvas, and comes
    /// back just after the lens is gone.
    static let glassFadeDuration = 0.4
    static let glassReturnDelay = 0.05
    /// How long the scene takes to come into view in a lens that grows out of
    /// the seed.
    static let seedSceneFade = 0.3
    /// How long the scatter's last playback blends in from its rest.
    static let gatherEase = 0.4
    static let sweepStart = orbStart + 2.46
    static let sweepInterval = 1.6
    static let sweepDuration = 1.1
    static let sweepCount = 2
    /// The level the lens opens on: already a cube in light, so the scene
    /// reads as 3D from its first frame.
    static let firstLevel = 1
    static let textStart = sweepStart
    static let end = sweepStart + Double(sweepCount) * sweepInterval
    /// The level the scene ends on: fully lit.
    static let finalLevel = firstLevel + sweepCount
    /// When the text comes in, and when the scene is at rest, for a scene
    /// that opens fully lit.
    static let litTextStart = glassFadeStart
    static let litEnd = sweepStart

    private static let expandCurve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.55, y: 0),
        endControlPoint: UnitPoint(x: 0.25, y: 1)
    )

    private static let sweepCurve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.45, y: 0),
        endControlPoint: UnitPoint(x: 0.4, y: 1)
    )

    let center: CGPoint
    /// Where the object sits, as a fraction of the canvas.
    let centerFraction: CGPoint
    let lensSize: CGFloat
    let coverSize: CGFloat
    /// Whether the scene is raised level by level by sweeps of glass, or
    /// opens fully lit.
    let revealsRendering: Bool

    init(canvasSize: CGSize, center: CGPoint, revealsRendering: Bool = true) {
        self.center = center
        self.revealsRendering = revealsRendering
        centerFraction = CGPoint(
            x: center.x / max(canvasSize.width, 1),
            y: center.y / max(canvasSize.height, 1)
        )
        // Wide enough to show the object on its floor; a phone's narrow
        // canvas needs a larger share of its width for that.
        lensSize = min(canvasSize.width, canvasSize.height) * (canvasSize.width < 640 ? 0.58 : 0.42)
        // Far enough that the lens's rim has left every corner.
        let reach = max(
            hypot(center.x, center.y),
            hypot(canvasSize.width - center.x, center.y),
            hypot(center.x, canvasSize.height - center.y),
            hypot(canvasSize.width - center.x, canvasSize.height - center.y)
        )
        coverSize = reach * 2 + 80
    }

    /// How many sweeps raise the scene.
    var sweepTotal: Int {
        revealsRendering ? Self.sweepCount : 0
    }

    /// The level the lens opens on.
    var openingLevel: Int {
        Self.finalLevel - sweepTotal
    }

    /// When the page's text comes in, on the reveal's own clock.
    var textStart: Double {
        revealsRendering ? Self.textStart : Self.litTextStart
    }

    /// When the scene is at rest, on the reveal's own clock.
    var end: Double {
        revealsRendering ? Self.end : Self.litEnd
    }

    /// The symbols page played back until every bubble is inside the center
    /// symbol. It begins where the symbols page comes to rest and eases onto
    /// the playback, so the bubbles never jump.
    func nativeTime(at time: Double) -> Double {
        let played = max(SymbolScatter.gatherFrom - time * Self.gatherSpeed, SymbolScatter.emergeStart)
        let rest = SymbolScatter.end - SymbolScatter.gatherFrom
        return played + rest * (1 - Ease.smoother(time / Self.gatherEase))
    }

    /// How much of the shared glass shows: it clears while the lens opens
    /// past the canvas, and returns once the lens is gone.
    func glassOpacity(at time: Double) -> Double {
        guard time >= Self.glassFadeStart, time < Self.orbEnd + Self.glassReturnDelay else {
            return 1
        }
        return 1 - UnitCurve.easeOut.value(at: min((time - Self.glassFadeStart) / Self.glassFadeDuration, 1))
    }

    /// How much of the center symbol is left as the lens takes its place.
    func centerRemaining(at time: Double) -> CGFloat {
        let t = min(max((time - Self.orbStart) / Self.centerOutDuration, 0), 1)
        return 1 - t * t * (3 - 2 * t)
    }

    /// The glass lens: it swells out of the symbol, then opens past the
    /// canvas's edges.
    func orbDiameter(at time: Double) -> CGFloat {
        orbDiameter(at: time, from: 0)
    }

    /// The lens as above, swelling out of a drop `start` wide rather than a
    /// point.
    func orbDiameter(at time: Double, from start: CGFloat) -> CGFloat {
        guard time >= Self.orbStart, time < Self.orbEnd else {
            return 0
        }
        let grown = start + (lensSize - start) * CGFloat(Ease.spring(time - Self.orbStart, period: 0.8, damping: 0.72))
        guard time > Self.expandStart else {
            return grown
        }
        let t = Self.expandCurve.value(at: min((time - Self.expandStart) / Self.expandDuration, 1))
        return grown + (coverSize - grown) * t
    }

    /// The scene `time` into the reveal, its lens swelling from a drop
    /// `orbFrom` wide.
    func scene(at time: Double, orbFrom: CGFloat = 0) -> SceneRevealFrame {
        let orb = orbDiameter(at: time, from: orbFrom)
        // The lens sits just inside its glass until the glass opens, then
        // grows to meet it so no corner is left bare.
        let opened = time > Self.expandStart
            ? Self.expandCurve.value(at: min((time - Self.expandStart) / Self.expandDuration, 1))
            : 0
        // Once the glass is gone the lens stays as wide as it opened, past
        // every corner, so the scene is never cut from a circle to a
        // rectangle at once.
        let lens: CGFloat? = time >= Self.orbEnd ? coverSize : orb * (0.97 + 0.03 * CGFloat(opened))
        for index in 0..<sweepTotal {
            let start = Self.sweepStart + Double(index) * Self.sweepInterval
            if time < start {
                return SceneRevealFrame(lensDiameter: lens, level: Float(openingLevel + index), sweep: 2)
            }
            if time < start + Self.sweepDuration {
                let fraction = Self.sweepCurve.value(at: (time - start) / Self.sweepDuration)
                // The line starts and ends just past the edges.
                return SceneRevealFrame(
                    lensDiameter: lens,
                    level: Float(openingLevel + index + 1),
                    sweep: Float(-0.02 + fraction * 1.04)
                )
            }
        }
        return SceneRevealFrame(lensDiameter: lens, level: Float(Self.finalLevel), sweep: 2)
    }
}
