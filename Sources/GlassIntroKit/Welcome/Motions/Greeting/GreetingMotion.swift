//===--- GreetingMotion.swift - GlassIntroKit -------------------------------===//
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

/// The mark gathers into the point of a pen and writes "hello" in glass.
///
/// Straight after the launch the mark itself, in colour, rests a moment,
/// gathers and writes. Coming in from the seed instead, the drop of glass is
/// the point: it shrinks into the pen and writes at once.
nonisolated struct GreetingMotion: PageMotion {
    let context: IntroContext
    private let plan: GreetingPlan
    private let growsFromSeed: Bool

    static func continues(from handoff: IntroHandoff) -> Bool {
        if case .launch = handoff {
            return true
        }
        return false
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
        if case .seed = entry {
            growsFromSeed = true
        } else {
            growsFromSeed = false
        }
        plan = GreetingPlan(canvas: context.canvas, start: growsFromSeed ? .seed : .launch)
    }

    var settleTime: Double {
        plan.end
    }

    var textTime: Double {
        plan.textTime
    }

    /// Coming in from the seed, the glass drop is the pen's point from the
    /// first frame on.
    var absorbsSeed: Bool {
        growsFromSeed
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        let pen = plan.pen(at: time)
        var frame = IntroFrame()
        let word = written(through: pen.progress)
        if growsFromSeed {
            // The point is glass: the drop itself, then the word's own
            // round tip.
            let outline = word.isEmpty ? Self.circle(at: pen.center, diameter: pen.diameter) : word
            frame.glass = [GlassPiece(id: Self.glassID, path: outline)]
        } else {
            if !word.isEmpty {
                frame.glass = [GlassPiece(id: Self.glassID, path: word)]
            }
            if pen.opacity > 0 {
                frame.mark = MarkSprite(
                    center: pen.center,
                    scale: pen.diameter / max(context.canvas.bodyDiameter, 1),
                    detail: pen.detail,
                    opacity: pen.opacity
                )
            }
        }
        return frame
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .word
    }

    /// The one piece of glass the greeting draws, from the drop to the word.
    private static let glassID = "main"

    /// The word written through `progress`, as one outline.
    private func written(through progress: Double) -> Path {
        guard progress > 0 else {
            return Path()
        }
        return GlassFrame.written(through: progress).path(
            layout: plan.layout,
            markDimension: context.canvas.markDimension,
            context: context
        )
    }

    private static func circle(at center: CGPoint, diameter: CGFloat) -> Path {
        Path(ellipseIn: CGRect(
            x: center.x - diameter / 2,
            y: center.y - diameter / 2,
            width: diameter,
            height: diameter
        ))
    }
}
