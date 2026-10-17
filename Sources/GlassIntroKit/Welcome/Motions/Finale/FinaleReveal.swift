//===--- FinaleReveal.swift - GlassIntroKit ---------------------------------===//
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

/// One glass word in one frame, already placed on the canvas.
nonisolated struct FinaleWordFrame: Identifiable, Sendable {
    let id: Int
    let path: Path
    let blur: CGFloat
    let opacity: Double
}

/// The ending in one frame.
nonisolated struct FinaleFrame: Sendable {
    var words: [FinaleWordFrame] = []
    /// The mark in glass, grown from nothing.
    var glassMarkGrowth: Double = 0
    var glassMarkOpacity: Double = 0
    /// How far colour has spread through the mark from its light, its glow,
    /// and the swell that comes with it.
    var colour: Double = 0
    var glow: Double = 0
    var swell: CGFloat = 1
}

/// The welcome's ending, after Get Started. The first word turns in from
/// the top left corner, coming into focus as it settles at the center, then
/// grows, blurs, and fades; the second does the same from the top right;
/// then the last turns up from below. Every word is glass. The picture then
/// goes to black, the mark forms in glass at the center, and colour spreads
/// through it from its light, with a soft glow, leaving the mark exactly
/// where the launch takes it from.
nonisolated struct FinaleReveal: Sendable {
    static let maximumWordCount = 3
    static let wordArrival = 1.4
    static let wordHold = 0.5
    static let wordDeparture = 0.85
    /// Each word sets off while the one before is still leaving.
    static let wordOverlap = 0.3
    /// The last word holds a little longer, as the line's subject.
    static let lastWordHold = 0.9
    static let firstWordStart = 0.3
    static let colourDuration = 1.1

    private struct Word: Sendable {
        let path: Path
        /// Where it comes from on the canvas, how it is turned there
        /// (about the horizontal axis, the vertical, and in the plane, in
        /// radians), and how far back.
        let origin: CGPoint
        let turnX: Double
        let turnY: Double
        let roll: Double
        let depth: Double
        let hold: Double
    }

    /// How far in front of the canvas the viewer stands, in points.
    private static let viewingDistance = 1100.0
    /// How far toward the viewer a word rushes as it leaves.
    private static let departureDepth = -720.0

    private let words: [Word]
    private let center: CGPoint
    let wordStarts: [Double]
    let blackStart: Double
    let glassMarkStart: Double
    let colourStart: Double
    let end: Double

    /// - Parameter lines: the words, one line each; the last is the line's
    ///   subject. At most three are shown.
    init(canvasSize: CGSize, lines: [String]) {
        center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let compact = canvasSize.width < 640
        let size: CGFloat = compact ? 72 : 124
        let w = canvasSize.width
        let h = canvasSize.height
        let degree = Double.pi / 180
        // Where each line comes from, by its place before the last.
        let leading = [
            (origin: CGPoint(x: w * 0.1, y: h * 0.08), turnX: 28 * degree, turnY: -80 * degree, roll: -24 * degree),
            (origin: CGPoint(x: w * 0.9, y: h * 0.08), turnX: 28 * degree, turnY: 80 * degree, roll: 24 * degree),
        ]
        // Each line fits the canvas with a margin.
        let room = canvasSize.width * 0.86
        let shown = Array(lines.prefix(Self.maximumWordCount))
        var words: [Word] = []
        for (index, line) in shown.enumerated() {
            let isLast = index == shown.count - 1
            var path = GlassLettering.path(for: line, size: isLast && shown.count > 1 ? size * 0.7 : size)
            if path.boundingRect.width > room {
                let fit = room / path.boundingRect.width
                path = path.applying(CGAffineTransform(scaleX: fit, y: fit))
            }
            if isLast {
                words.append(Word(path: path, origin: CGPoint(x: w * 0.5, y: h * 0.98),
                                  turnX: -82 * degree, turnY: 0, roll: 0, depth: 1800, hold: Self.lastWordHold))
            } else {
                let from = leading[index % leading.count]
                words.append(Word(path: path, origin: from.origin, turnX: from.turnX, turnY: from.turnY,
                                  roll: from.roll, depth: 2200, hold: Self.wordHold))
            }
        }
        self.words = words
        var starts: [Double] = []
        var start = Self.firstWordStart
        for _ in words {
            starts.append(start)
            start += Self.wordArrival + Self.wordHold + Self.wordOverlap
        }
        wordStarts = starts
        let lastArrival = (starts.last ?? 0) + (words.isEmpty ? 0 : Self.wordArrival + Self.lastWordHold)
        blackStart = lastArrival + 0.15
        glassMarkStart = blackStart + 0.7
        colourStart = glassMarkStart + 1.2
        end = colourStart + Self.colourDuration + 0.25
    }

    func frame(at time: Double) -> FinaleFrame {
        var frame = FinaleFrame()
        for (index, word) in words.enumerated() {
            let local = time - wordStarts[index]
            let departureStart = Self.wordArrival + word.hold
            guard local > 0, local < departureStart + Self.wordDeparture else {
                continue
            }
            // Turning in from far away: a long ease that lands softly, the
            // turn settling a touch after the travel so the word swings in.
            let travel = Ease.easeOutQuint(local / Self.wordArrival)
            let turn = Ease.easeOutQuint(local / (Self.wordArrival * 1.05))
            var depth = word.depth * (1 - travel)
            var turnX = word.turnX * (1 - turn)
            var turnY = word.turnY * (1 - turn)
            let roll = word.roll * (1 - turn)
            var blur = 24 * (1 - Ease.smoother(local / (Self.wordArrival * 0.8)))
            var opacity = Ease.smoother(local / (Self.wordArrival * 0.45))
            // Leaving: it rushes toward the viewer, gathering speed, a
            // little turn carrying on, as it blurs and fades.
            let departure = Ease.easeIn((local - departureStart) / Self.wordDeparture)
            depth += Self.departureDepth * departure
            turnY += (index == 1 ? -1 : 1) * 0.12 * departure
            turnX += 0.06 * departure
            blur += 28 * departure
            opacity *= 1 - Ease.smoother((local - departureStart) / Self.wordDeparture)
            let position = CGPoint(
                x: word.origin.x + (center.x - word.origin.x) * travel,
                y: word.origin.y + (center.y - word.origin.y) * travel
            )
            frame.words.append(FinaleWordFrame(
                id: index,
                path: GlassLettering.project(
                    word.path,
                    turnX: turnX,
                    turnY: turnY,
                    roll: roll,
                    depth: depth,
                    distance: Self.viewingDistance,
                    position: position
                ),
                blur: blur,
                opacity: opacity
            ))
        }

        // The mark forms in glass at the center of the black.
        let glassTime = time - glassMarkStart
        if glassTime > 0 {
            frame.glassMarkGrowth = Ease.spring(glassTime, period: 1.0, damping: 0.8)
            frame.glassMarkOpacity = 1
        }
        // Colour spreads through it from its light; the glass gives way as
        // it does, and a glow blooms and settles with a slight swell.
        let colourTime = time - colourStart
        if colourTime > 0 {
            frame.colour = Ease.smoother(colourTime / Self.colourDuration)
            frame.glassMarkOpacity = 1 - Ease.smoother((colourTime - 0.45) / 0.6)
            let bloom = min(max(colourTime / Self.colourDuration, 0), 1)
            frame.glow = sin(bloom * .pi) * 0.75
            frame.swell = 1 + 0.05 * CGFloat(sin(bloom * .pi))
        }
        return frame
    }
}
