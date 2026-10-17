//===--- WelcomePlayer.swift - GlassIntroKit --------------------------------===//
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

/// Which picture plays when, on the welcome's own clock, in seconds.
///
/// The player decides how one picture gives way to the next. A picture that
/// carries straight on from the one before starts the moment that one is at
/// rest. Any other gathers the picture before it into the seed and grows out
/// of the seed. Either way the frame never jumps, whatever order the pages
/// come in and whenever the viewer turns the page.
nonisolated struct WelcomePlayer: Sendable {
    /// A picture and when it began, on the welcome's clock.
    struct Segment: Sendable {
        let motion: any IntroMotion
        let start: Double
        let entry: IntroEntry
        /// When the picture began to leave, for how long, and whether it
        /// gathers into the seed or dissolves where it is.
        var exit: (from: Double, duration: Double, dissolves: Bool)?
    }

    /// The times a turn reaches, on the welcome's clock.
    struct Turn: Equatable, Sendable {
        /// When the new page's text comes in.
        let textTime: Double
        /// When the new picture is at rest.
        let settleTime: Double
    }

    /// How a page is built: from where it starts.
    typealias Builder = @Sendable (IntroEntry) -> any IntroMotion

    /// How long a picture that carries straight on will wait for the one
    /// before it to come to rest.
    static let longestWait = 1.5
    /// How long a picture takes to let go where it is.
    static let dissolveDuration = 0.6

    /// Every picture still on screen or to come, in order; each plays from
    /// its start until the next one's.
    private(set) var segments: [Segment]

    /// Starts with `motion`, at rest, at time zero.
    init(resting motion: any IntroMotion) {
        segments = [Segment(motion: motion, start: -motion.settleTime, entry: .seed)]
    }

    /// The last picture turned to.
    var current: Segment {
        segments[segments.count - 1]
    }

    /// Turns to the picture `build` makes, at `clock`. A turn made before
    /// the last one has begun follows on from it.
    ///
    /// - Parameters:
    ///   - continues: Whether the new picture can carry straight on from
    ///     what the current one offers at rest.
    ///   - arrivesEmpty: Whether the new picture starts from nothing, so the
    ///     current one dissolves where it is instead of gathering into the
    ///     seed.
    @discardableResult
    mutating func turn(
        at clock: Double,
        interaction: IntroInteraction,
        continues: (IntroHandoff) -> Bool,
        arrivesEmpty: Bool = false,
        build: Builder
    ) -> Turn {
        let last = segments.count - 1
        let outgoing = segments[last]
        let settle = outgoing.motion.settleTime
        let turnTime = max(clock, outgoing.start)
        // A picture that grew out of the seed is not at rest until the seed
        // beneath it has gone.
        var restTime = outgoing.start + settle
        if case .seed = outgoing.entry, !outgoing.motion.absorbsSeed {
            restTime = max(restTime, outgoing.start + IntroFrame.seedDecayDuration)
        }
        // What the picture offers where it will be when the next one takes
        // over: at rest, or later still if it kept moving.
        let restHandoff = outgoing.motion.handoff(
            at: max(turnTime - outgoing.start, settle),
            interaction: interaction
        )
        // A picture that carries straight on waits for the one before to be
        // at rest, as long as that is near; otherwise both meet at the seed.
        let carriesOn = continues(restHandoff)
            && (interaction.reducesMotion || restTime - turnTime <= Self.longestWait)
        let entry: IntroEntry = carriesOn ? .handoff(restHandoff) : arrivesEmpty ? .empty : .seed
        let motion = build(entry)

        if interaction.reducesMotion {
            // Straight to the new picture at rest.
            segments = [Segment(motion: motion, start: clock - motion.settleTime, entry: entry)]
            return Turn(textTime: clock, settleTime: clock)
        }

        if carriesOn {
            segments.append(Segment(motion: motion, start: max(turnTime, restTime), entry: entry))
        } else {
            let duration = arrivesEmpty ? Self.dissolveDuration : outgoing.motion.exitDuration
            segments[last].exit = (turnTime, duration, arrivesEmpty)
            segments.append(Segment(motion: motion, start: turnTime + duration, entry: entry))
        }
        trim(before: clock)
        return Turn(
            textTime: current.start + current.motion.textTime,
            settleTime: current.start + current.motion.settleTime
        )
    }

    /// The frame at `clock`.
    func frame(at clock: Double, interaction: IntroInteraction) -> IntroFrame {
        let segment = segments[index(at: clock)]
        let time = max(clock - segment.start, 0)
        var frame = segment.motion.frame(at: time, interaction: interaction)
        if case .seed = segment.entry, !segment.motion.absorbsSeed, !interaction.reducesMotion {
            frame = frame.withDecayingSeed(segment.motion.context.canvas.seed, elapsed: time)
        }
        if let exit = segment.exit, clock >= exit.from {
            let progress = exit.duration > 0 ? (clock - exit.from) / exit.duration : 1
            return exit.dissolves
                ? frame.dissolved(progress: progress)
                : segment.motion.exitFrame(from: frame, at: time, progress: progress)
        }
        return frame
    }

    /// Whether anything moves at `clock`.
    func isMoving(at clock: Double, interaction: IntroInteraction) -> Bool {
        guard !interaction.reducesMotion else {
            return false
        }
        return clock < current.start + current.motion.settleTime || current.motion.isLive
    }

    /// Whether the picture at `clock` can be turned by dragging.
    func isInteractive(at clock: Double) -> Bool {
        clock >= current.start && current.motion.isInteractive
    }

    /// Rebuilds the current picture, at rest, for a canvas that changed
    /// size: pictures are laid out for the canvas they began on.
    mutating func rebuildAtRest(at clock: Double, motion: any IntroMotion, entry: IntroEntry) {
        segments = [Segment(motion: motion, start: clock - motion.settleTime, entry: entry)]
    }

    /// The canvas the picture on screen at `clock` was laid out for.
    func canvas(at clock: Double) -> IntroCanvas {
        segments[index(at: clock)].motion.context.canvas
    }

    /// Whether the last picture turned to has come to rest by `clock`.
    func isAtRest(at clock: Double) -> Bool {
        clock >= current.start + current.motion.settleTime
    }

    /// The segment on screen at `clock`: the last to have started, or the
    /// first if none has.
    private func index(at clock: Double) -> Int {
        segments.lastIndex { $0.start <= clock } ?? 0
    }

    /// Forgets the pictures that have given way for good.
    private mutating func trim(before clock: Double) {
        let first = index(at: clock)
        if first > 0 {
            segments.removeFirst(first)
        }
    }
}

/// The seed alone, at rest: what is on screen once a picture has gathered
/// into it.
nonisolated struct SeedMotion: IntroMotion {
    let context: IntroContext

    var settleTime: Double {
        0
    }

    var textTime: Double {
        0
    }

    var absorbsSeed: Bool {
        true
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        .seed(context.canvas.seed)
    }
}
