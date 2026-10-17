//===--- OpeningStage.swift - GlassIntroKit ---------------------------------===//
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

/// The opening stage. A tinted circle grows to fill the canvas, four points
/// spread and settle onto orbit rings that trace from where they land, grid
/// and diagonal guides draw in. White then spreads from the center as the
/// drawing clears, and the stage closes as a circle to the size of the mark's
/// body as the mark comes into focus. At the end the mark dissolves where it
/// is, over the app.
struct OpeningStage: View {
    let properties: OpeningStageProperties
    let canvasSize: CGSize
    let mark: GlassIntroMark
    var tint = Color.accentColor

    private let foregroundColor = Color.white

    var body: some View {
        let isLogo = properties.convertToLogo

        // The stage and the mark share one frame, scale, and position, so they
        // travel as a single object and can never drift apart.
        ZStack {
            // A circle, never a rounded rectangle, at every size: the mask
            // starts wide enough to reach the window's corners.
            stage
                .frame(width: canvasSize.width, height: canvasSize.height)
                .mask {
                    Circle()
                        .frame(width: stageDiameter, height: stageDiameter)
                }

            // The mark sits outside the stage's clip so its light can extend
            // past its body. It comes into focus a beat after the stage
            // starts to close, and over a little longer.
            GlassIntroMarkView(mark)
                .frame(width: markDimension, height: markDimension)
                .compositingGroup()
                .animation(.easeOut(duration: 0.70).delay(0.30)) {
                    $0
                        .blur(radius: isLogo ? 0 : 24)
                        .scaleEffect(isLogo ? 1 : 0.92)
                        .opacity(isLogo ? 1 : 0)
                }
        }
        .frame(
            width: isLogo ? markDimension : canvasSize.width,
            height: isLogo ? markDimension : canvasSize.height
        )
        .position(canvasCenter)
        // At the end the mark dissolves where it is.
        .opacity(properties.dissolvesMark ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var stage: some View {
        ZStack {
            ZStack {
                Circle()
                    .fill(tint.gradient)
                // Spreads from the center rather than fading in place.
                Circle()
                    .fill(Color.white)
                    .scaleEffect(properties.whitensStage ? 1 : 0)
            }
            .scaleEffect(properties.animateMainCircle ? coveringScale : 0)
            .opacity(properties.dissolvesMark ? 0 : 1)

            gridLines

            circlesView

            circleStrokesView

            diagonalLines
        }
    }

    // MARK: Geometry

    private var canvasCenter: CGPoint {
        CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
    }

    private var shortSide: CGFloat {
        max(min(canvasSize.width, canvasSize.height), 1)
    }

    /// Converts design points, drawn for a stage about 400 points across,
    /// to this window.
    private var designScale: CGFloat {
        max(shortSide / 400, 1)
    }

    /// The circle, sized to the short side, grows until it covers every
    /// corner.
    private var coveringScale: CGFloat {
        hypot(canvasSize.width, canvasSize.height) / shortSide * 1.04
    }

    private var markDimension: CGFloat {
        Self.markDimension(in: canvasSize)
    }

    /// The mark's size once the stage has closed.
    nonisolated static func markDimension(in canvasSize: CGSize) -> CGFloat {
        min(200, max(min(canvasSize.width, canvasSize.height), 1) * 0.45)
    }

    /// The closed stage sits just inside the mark's body, so no tinted rim shows
    /// around it once the mark is in focus.
    private var logoDiameter: CGFloat {
        markDimension * mark.bodyDiameterRatio - 2
    }

    private var stageDiameter: CGFloat {
        properties.convertToLogo
            ? logoDiameter
            : hypot(canvasSize.width, canvasSize.height) + 2
    }

    // MARK: Points and orbits

    private var circlesView: some View {
        let scale = designScale

        return ZStack {
            ForEach(1...4, id: \.self) { index in
                let rotation = Double(index) / 4 * 360
                let extraRotation: Double = properties.positionCircles ? 20 : 0
                let extraOffset: CGFloat = index % 2 != 0 ? 40 : -20

                Circle()
                    .fill(foregroundColor)
                    .frame(
                        width: properties.circleSize * scale,
                        height: properties.circleSize * scale
                    )
                    // Hands over to its ring's tip the moment it lands, once
                    // its final turn below has finished.
                    .animation(.easeOut(duration: 0.06).delay(0.60)) {
                        $0.opacity(properties.positionCircles ? 0 : 1)
                    }
                    .offset(
                        x: (properties.positionCircles
                            ? 120 + extraOffset
                            : properties.circleOffset) * scale
                    )
                    .rotationEffect(.degrees(rotation + extraRotation))
                    // Picks up speed into the landing, so the ring's tip
                    // carries the motion on instead of starting from rest.
                    .animation(.easeIn(duration: 0.30).delay(0.30)) {
                        $0.rotationEffect(.degrees(properties.positionCircles ? 12 : 0))
                    }
            }
        }
        .compositingGroup()
        .scaleEffect(properties.circleScale)
    }

    private var ringStroke: StrokeStyle {
        StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
    }

    private var circleStrokesView: some View {
        let scale = designScale
        let isClearing = properties.whitensStage

        return ZStack {
            Circle()
                .trim(from: 0, to: properties.animateStrokes ? 1 : 0)
                .stroke(foregroundColor, style: ringStroke)
                .frame(width: 70 * scale, height: 70 * scale)
                .scaleEffect(isClearing ? 2 : 1)

            ForEach(1...4, id: \.self) { index in
                let rotation = Double(index) / 4 * 360
                // The points' final 12 degree turn is included, so each ring
                // starts exactly where its point lands.
                let extraRotation = 20.0 + 12.0
                let extraOffset: CGFloat = index % 2 != 0 ? 120 : 0
                let isFaded = index == 3 || index == 4

                let progress: Double = properties.animateStrokes ? 1 : 0

                // The point that landed here rides the ring's tip as it
                // draws, and rests on the ring once it closes.
                ZStack {
                    OpeningRingArc(progress: progress)
                        .stroke(foregroundColor.opacity(isFaded ? 0.3 : 1), style: ringStroke)
                    OpeningRingTip(progress: progress, diameter: 5 * scale)
                        .fill(foregroundColor)
                }
                .frame(
                    width: (200 + extraOffset) * scale,
                    height: (200 + extraOffset) * scale
                )
                .rotationEffect(.degrees(rotation + extraRotation))
            }
        }
        .compositingGroup()
        // The rings ease outward with the spreading white rather than
        // racing ahead of it.
        .scaleEffect(isClearing ? 1.3 : 1)
        .animation(constructionExit) {
            $0.opacity(isClearing ? 0 : 1)
        }
    }

    // MARK: Guides

    private var gridLines: some View {
        ZStack {
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { index in
                    Rectangle()
                        .fill(foregroundColor.tertiary)
                        .frame(width: 1, height: properties.animateGridLines ? nil : 0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .scaleEffect(y: index == 2 || index == 4 ? -1 : 1)
                        .animation(guideAnimation(index: index), value: properties.animateGridLines)
                }
            }

            VStack(spacing: 0) {
                ForEach(1...5, id: \.self) { index in
                    Rectangle()
                        .fill(foregroundColor.tertiary)
                        .frame(width: properties.animateGridLines ? nil : 0, height: 1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .scaleEffect(x: index == 2 || index == 4 ? -1 : 1)
                        .animation(guideAnimation(index: index), value: properties.animateGridLines)
                }
            }
        }
        .compositingGroup()
        .animation(constructionExit) {
            $0.opacity(properties.whitensStage ? 0 : 1)
        }
    }

    /// Guides draw one after another rather than all at once.
    private func guideAnimation(index: Int) -> Animation {
        .openingDrawing(duration: 0.80).delay(Double(index - 1) * 0.06)
    }

    private var diagonalLines: some View {
        // Rotated by this angle, a vertical line runs corner to corner.
        let cornerDegrees = atan2(canvasSize.width, canvasSize.height) * 180 / .pi
        let overhang = (hypot(canvasSize.width, canvasSize.height) - canvasSize.height) / 2 + 20

        return ZStack {
            // The second diagonal follows the first, as the grid lines do.
            ForEach(Array([-cornerDegrees, cornerDegrees].enumerated()), id: \.offset) { index, degrees in
                Rectangle()
                    .fill(foregroundColor.tertiary)
                    .frame(width: 1, height: properties.animateDiagonalLines ? nil : 0)
                    .animation(
                        .openingDrawing(duration: 0.55).delay(Double(index) * 0.08),
                        value: properties.animateDiagonalLines
                    )
                    .padding(.vertical, -overhang)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .rotationEffect(.degrees(degrees))
            }
        }
        .compositingGroup()
        .animation(constructionExit) {
            $0.opacity(properties.whitensStage ? 0 : 1)
        }
    }

    /// The drawing leaves while the tint turns white, before the stage
    /// closes.
    private var constructionExit: Animation {
        .easeOut(duration: 0.30)
    }
}
