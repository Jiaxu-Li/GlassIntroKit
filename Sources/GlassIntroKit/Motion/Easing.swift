//===--- Easing.swift - GlassIntroKit ---------------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import CoreGraphics

/// The curves every picture moves on. Each takes progress, clamps it to
/// 0...1, and returns eased progress.
nonisolated enum Ease {
    static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    /// Starts and ends at rest, with no jolt at either end.
    static func smoother(_ value: Double) -> Double {
        let t = clamp(value)
        return t * t * t * (t * (t * 6 - 15) + 10)
    }

    static func smoothstep(_ value: Double) -> Double {
        let t = clamp(value)
        return t * t * (3 - 2 * t)
    }

    static func easeIn(_ value: Double) -> Double {
        let t = clamp(value)
        return t * t * t
    }

    static func easeOut(_ value: Double) -> Double {
        let t = clamp(value)
        return 1 - pow(1 - t, 3)
    }

    static func easeOutQuint(_ value: Double) -> Double {
        let t = clamp(value)
        return 1 - pow(1 - t, 5)
    }

    /// An underdamped spring from 0 to 1, `time` seconds after release.
    static func spring(_ time: Double, period: Double, damping: Double) -> Double {
        guard time > 0 else {
            return 0
        }
        guard time.isFinite else {
            return 1
        }
        let frequency = 2 * Double.pi / period
        let decay = damping * frequency
        let damped = frequency * (1 - damping * damping).squareRoot()
        return 1 - exp(-decay * time) * (cos(damped * time) + decay / damped * sin(damped * time))
    }

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat {
        a + (b - a) * CGFloat(t)
    }

    static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        CGPoint(x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t))
    }
}
