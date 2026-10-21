//===--- WelcomeBackdrop.swift - GlassIntroKit ------------------------------===//
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

/// What one page shows behind its picture: a mesh of light, and perhaps a
/// picture over it.
struct BackdropStyle {
    let points: [SIMD2<Float>]
    let colors: [Color]
    let image: Image?
    /// What shows instead with Reduce Transparency on: one dark, solid
    /// colour from the same light, which white text and buttons read
    /// clearly against.
    let solid: Color

    /// The style for a page with `background`, turned to `picture`.
    init(_ background: GlassIntroBackground, picture: IntroPicture) {
        let palette = WelcomeBackdrop.palette(for: picture)
        switch background {
        case .automatic:
            self.init(points: palette.points, colors: palette.colors, image: nil)
        case .color(let color):
            self.init(
                points: WelcomeBackdrop.nightPoints,
                colors: WelcomeBackdrop.colors(around: color),
                image: nil,
                solid: WelcomeBackdrop.solid(around: color)
            )
        case .image(let image):
            self.init(points: palette.points, colors: palette.colors, image: image)
        }
    }

    init(points: [SIMD2<Float>], colors: [Color], image: Image?, solid: Color? = nil) {
        self.points = points
        self.colors = colors
        self.image = image
        self.solid = solid ?? WelcomeBackdrop.solid(from: colors)
    }
}

/// Each page's light. The mesh moves smoothly from one page's light to the
/// next; a page's own picture fades in over it while the page shows.
struct WelcomeBackdrop: View {
    let styles: [BackdropStyle]
    var page = 0
    var reducesMotion = false
    var reducesTransparency = false

    var body: some View {
        if reducesTransparency {
            solidBackdrop
        } else {
            lightBackdrop
        }
    }

    /// One solid colour per page, crossfading as the pages turn.
    private var solidBackdrop: some View {
        ZStack {
            Rectangle()
                .fill(styles.first?.solid ?? Self.solid(from: Self.oceanColors))
            ForEach(styles.indices, id: \.self) { index in
                Rectangle()
                    .fill(styles[index].solid)
                    .opacity(index == page ? 1 : 0)
            }
        }
        .accessibilityHidden(true)
    }

    private var lightBackdrop: some View {
        let style = styles.isEmpty ? nil : styles[min(max(page, 0), styles.count - 1)]
        return ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: style?.points ?? Self.oceanPoints,
                colors: style?.colors ?? Self.oceanColors
            )

            // Keep each picture mounted so its blur and opacity interpolate
            // together while the next page's light appears beneath it.
            ForEach(styles.indices, id: \.self) { index in
                if let image = styles[index].image {
                    GeometryReader { geometry in
                        image
                            .resizable()
                            .allowedDynamicRange(.high)
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    .blur(radius: index == page || reducesMotion ? 0 : 32)
                    .opacity(index == page ? 1 : 0)
                    .allowsHitTesting(false)
                }
            }
        }
        .accessibilityHidden(true)
    }

    static func palette(for picture: IntroPicture) -> (points: [SIMD2<Float>], colors: [Color]) {
        switch picture {
        case .page(.greeting), .launch:
            (duskPoints, duskColors)
        case .page(.mark), .page(.card):
            (nightPoints, nightColors)
        case .page(.symbols), .page(.scene):
            (stagePoints, stageColors)
        case .page(.graph):
            (circuitPoints, circuitColors)
        case .page(.physics):
            (impactPoints, impactColors)
        case .page(.icon):
            (dawnPoints, dawnColors)
        case .rest, .finale:
            (oceanPoints, oceanColors)
        }
    }

    /// A solid colour from a page's light: its top center, darkened enough
    /// that white text on it keeps a contrast ratio of at least 7:1.
    static func solid(from colors: [Color]) -> Color {
        let base = colors.count > 1 ? colors[1] : (colors.first ?? .black)
        return base.mix(with: .black, by: 0.35)
    }

    /// A solid colour in `color`, dark enough for white text.
    static func solid(around color: Color) -> Color {
        color.mix(with: .black, by: 0.72)
    }

    /// Soft light in `color`: brightest a little above the center, falling
    /// to near black at the corners.
    static func colors(around color: Color) -> [Color] {
        let corner = color.mix(with: .black, by: 0.82)
        let edge = color.mix(with: .black, by: 0.6)
        let light = color.mix(with: .white, by: 0.12)
        return [
            corner, edge, corner,
            edge, light, edge,
            corner, edge.mix(with: .black, by: 0.3), corner,
        ]
    }

    /// The mark and card pages: a cool night, its light high and to the right of
    /// the mark.
    static let nightPoints: [SIMD2<Float>] = [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.5], [0.58, 0.38], [1, 0.5],
        [0, 1], [0.5, 1], [1, 1],
    ]

    static let nightColors: [Color] = [
        Color(red: 0.05, green: 0.07, blue: 0.20),
        Color(red: 0.10, green: 0.18, blue: 0.45),
        Color(red: 0.20, green: 0.12, blue: 0.38),
        Color(red: 0.00, green: 0.30, blue: 0.62),
        Color(red: 0.25, green: 0.48, blue: 0.95),
        Color(red: 0.55, green: 0.30, blue: 0.80),
        Color(red: 0.02, green: 0.10, blue: 0.24),
        Color(red: 0.08, green: 0.36, blue: 0.55),
        Color(red: 0.18, green: 0.10, blue: 0.30),
    ]

    /// The greeting: a quiet, warm dusk, its light behind the word, like
    /// a lamp over a workbench.
    static let duskPoints: [SIMD2<Float>] = [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.5], [0.5, 0.38], [1, 0.46],
        [0, 1], [0.5, 1], [1, 1],
    ]

    static let duskColors: [Color] = [
        Color(red: 0.06, green: 0.07, blue: 0.10),
        Color(red: 0.10, green: 0.12, blue: 0.18),
        Color(red: 0.08, green: 0.09, blue: 0.14),
        Color(red: 0.14, green: 0.19, blue: 0.27),
        Color(red: 0.60, green: 0.47, blue: 0.32),
        Color(red: 0.22, green: 0.23, blue: 0.31),
        Color(red: 0.05, green: 0.06, blue: 0.09),
        Color(red: 0.30, green: 0.22, blue: 0.16),
        Color(red: 0.07, green: 0.08, blue: 0.11),
    ]


    /// The symbols and scene pages: a quiet graphite stage with one soft, cool light
    /// behind the logo.
    static let stagePoints: [SIMD2<Float>] = [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.48], [0.5, 0.36], [1, 0.48],
        [0, 1], [0.5, 1], [1, 1],
    ]

    static let stageColors: [Color] = [
        Color(red: 0.05, green: 0.05, blue: 0.06),
        Color(red: 0.09, green: 0.10, blue: 0.11),
        Color(red: 0.05, green: 0.05, blue: 0.06),
        Color(red: 0.12, green: 0.13, blue: 0.15),
        Color(red: 0.42, green: 0.45, blue: 0.50),
        Color(red: 0.12, green: 0.13, blue: 0.15),
        Color(red: 0.03, green: 0.03, blue: 0.04),
        Color(red: 0.10, green: 0.11, blue: 0.13),
        Color(red: 0.03, green: 0.03, blue: 0.04),
    ]

    /// The graph page: a deep teal night with a band of cyan-green light
    /// along the wire's line, a little stronger toward the left, where the
    /// wire comes in.
    static let circuitPoints: [SIMD2<Float>] = [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.38], [0.5, 0.36], [1, 0.40],
        [0, 1], [0.5, 1], [1, 1],
    ]

    static let circuitColors: [Color] = [
        Color(red: 0.02, green: 0.06, blue: 0.07),
        Color(red: 0.04, green: 0.12, blue: 0.13),
        Color(red: 0.03, green: 0.07, blue: 0.09),
        Color(red: 0.05, green: 0.26, blue: 0.28),
        Color(red: 0.20, green: 0.62, blue: 0.58),
        Color(red: 0.10, green: 0.28, blue: 0.36),
        Color(red: 0.02, green: 0.05, blue: 0.06),
        Color(red: 0.05, green: 0.16, blue: 0.17),
        Color(red: 0.02, green: 0.05, blue: 0.07),
    ]

    /// The physics page: a deep plum dark with a warm amber light low
    /// down, where the nodes land.
    static let impactPoints: [SIMD2<Float>] = [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.6], [0.5, 0.62], [1, 0.58],
        [0, 1], [0.5, 1], [1, 1],
    ]

    static let impactColors: [Color] = [
        Color(red: 0.05, green: 0.04, blue: 0.09),
        Color(red: 0.09, green: 0.06, blue: 0.15),
        Color(red: 0.05, green: 0.04, blue: 0.10),
        Color(red: 0.20, green: 0.10, blue: 0.22),
        Color(red: 0.74, green: 0.42, blue: 0.22),
        Color(red: 0.24, green: 0.10, blue: 0.24),
        Color(red: 0.04, green: 0.03, blue: 0.06),
        Color(red: 0.16, green: 0.08, blue: 0.10),
        Color(red: 0.04, green: 0.03, blue: 0.06),
    ]

    /// The icon page: a deep navy dawn with rose-gold light coming up
    /// behind the icon.
    static let dawnPoints: [SIMD2<Float>] = [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.44], [0.5, 0.38], [1, 0.42],
        [0, 1], [0.5, 1], [1, 1],
    ]

    static let dawnColors: [Color] = [
        Color(red: 0.04, green: 0.05, blue: 0.12),
        Color(red: 0.08, green: 0.09, blue: 0.20),
        Color(red: 0.05, green: 0.05, blue: 0.13),
        Color(red: 0.26, green: 0.14, blue: 0.26),
        Color(red: 0.86, green: 0.56, blue: 0.52),
        Color(red: 0.30, green: 0.16, blue: 0.30),
        Color(red: 0.03, green: 0.04, blue: 0.09),
        Color(red: 0.12, green: 0.08, blue: 0.16),
        Color(red: 0.03, green: 0.04, blue: 0.09),
    ]

    /// The last page: a clear, deep blue, its light at the center where
    /// the line sits.
    static let oceanPoints: [SIMD2<Float>] = [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.5], [0.5, 0.48], [1, 0.5],
        [0, 1], [0.5, 1], [1, 1],
    ]

    static let oceanColors: [Color] = [
        Color(red: 0.02, green: 0.05, blue: 0.16),
        Color(red: 0.04, green: 0.12, blue: 0.32),
        Color(red: 0.03, green: 0.06, blue: 0.20),
        Color(red: 0.05, green: 0.22, blue: 0.55),
        Color(red: 0.20, green: 0.52, blue: 0.95),
        Color(red: 0.10, green: 0.25, blue: 0.62),
        Color(red: 0.02, green: 0.06, blue: 0.18),
        Color(red: 0.05, green: 0.18, blue: 0.42),
        Color(red: 0.02, green: 0.05, blue: 0.16),
    ]
}
