//===--- StandardMark.swift - GlassIntroKit ---------------------------------===//
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

/// The kit's own mark: a white pearl with a yellow light set into it, high
/// on its left.
nonisolated enum StandardMark {
    /// The pearl's diameter as a fraction of the mark's square frame.
    static let pearlRatio: CGFloat = 0.76
    /// The light's square, as a fraction of the mark's square frame, and how
    /// far its center sits from the mark's, left and up.
    static let lightSide: CGFloat = 0.526
    static let lightOffset: CGFloat = 0.142

    /// Where the light sits in the mark's square frame, for colour to spread
    /// from at the end of the welcome.
    static let light = UnitPoint(x: 0.5 - lightOffset, y: 0.5 - lightOffset)

    /// The mark as one outline for glass: the pearl with the light's
    /// aperture left open, laid out in the square of `rect`. `opening`
    /// scales the aperture about its own center, from closed at 0.
    static func outline(in rect: CGRect, opening: CGFloat) -> Path {
        let dimension = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let pearlDiameter = dimension * pearlRatio
        let pearl = Path(ellipseIn: CGRect(
            x: center.x - pearlDiameter / 2,
            y: center.y - pearlDiameter / 2,
            width: pearlDiameter,
            height: pearlDiameter
        ))
        let opening = min(max(opening, 0), 1)
        guard opening > 0 else {
            return pearl
        }
        let side = dimension * lightSide
        let lightCenter = CGPoint(x: center.x - dimension * lightOffset, y: center.y - dimension * lightOffset)
        let aperture = LightApertureShape()
            .path(in: CGRect(x: lightCenter.x - side / 2, y: lightCenter.y - side / 2, width: side, height: side))
            .applying(
                CGAffineTransform(translationX: lightCenter.x, y: lightCenter.y)
                    .scaledBy(x: opening, y: opening)
                    .translatedBy(x: -lightCenter.x, y: -lightCenter.y)
            )
        return pearl.subtracting(aperture)
    }
}

/// The light's aperture: a soft, rounded lens turned to follow the pearl's
/// edge, high on its left.
nonisolated struct LightApertureShape: Shape {
    func path(in rect: CGRect) -> Path {
        let box = CGRect(
            x: rect.midX - rect.width * 0.39,
            y: rect.midY - rect.height * 0.3275,
            width: rect.width * 0.78,
            height: rect.height * 0.655
        )
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: box.minX + box.width * x, y: box.minY + box.height * y)
        }
        var path = Path()
        path.move(to: point(0.02, 0.47))
        path.addCurve(to: point(0.49, 0.02), control1: point(0.03, 0.23), control2: point(0.26, 0.01))
        path.addCurve(to: point(0.98, 0.52), control1: point(0.75, 0.01), control2: point(0.98, 0.24))
        path.addCurve(to: point(0.51, 0.98), control1: point(0.99, 0.77), control2: point(0.76, 0.99))
        path.addCurve(to: point(0.02, 0.47), control1: point(0.25, 0.99), control2: point(0.01, 0.76))
        path.closeSubpath()

        // Turned to lie along the pearl's edge as the original pearl's light
        // does at the upper right, then mirrored to the upper left.
        let radial = atan2(-0.125, 0.125)
        let tangent = radial + .pi / 2
        return path.applying(
            CGAffineTransform(translationX: rect.midX, y: rect.midY)
                .scaledBy(x: -1, y: 1)
                .rotated(by: tangent)
                .translatedBy(x: -rect.midX, y: -rect.midY)
        )
    }
}

/// The kit's own mark in colour.
struct StandardMarkView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        GeometryReader { proxy in
            let dimension = min(proxy.size.width, proxy.size.height)
            ZStack {
                pearl(dimension: dimension)
                light(dimension: dimension)
            }
            .frame(width: dimension, height: dimension)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func pearl(dimension: CGFloat) -> some View {
        Circle()
            .fill(LinearGradient(stops: pearlStops, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Circle()
                    .fill(RadialGradient(
                        stops: [
                            .init(color: .white.opacity(colorScheme == .dark ? 0.15 : 0.17), location: 0),
                            .init(color: .white.opacity(0.04), location: 0.46),
                            .init(color: .clear, location: 1),
                        ],
                        center: UnitPoint(x: 0.71, y: 0.24),
                        startRadius: 0,
                        endRadius: dimension * 0.52
                    ))
                    .opacity(0.9)
            }
            .frame(width: dimension * StandardMark.pearlRatio, height: dimension * StandardMark.pearlRatio)
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.065 : 0.055),
                radius: dimension * 0.010,
                y: dimension * 0.014
            )
    }

    private func light(dimension: CGFloat) -> some View {
        let side = dimension * StandardMark.lightSide
        let glow = Color(red: 1.00, green: 0.74, blue: 0.18).opacity(colorSchemeContrast == .increased ? 0.196 : 0.14)

        return LightApertureShape()
            .fill(LinearGradient(
                stops: [
                    .init(color: Color(red: 1.00, green: 0.85, blue: 0.36), location: 0),
                    .init(color: Color(red: 1.00, green: 0.82, blue: 0.30), location: 0.58),
                    .init(color: Color(red: 0.985, green: 0.79, blue: 0.25), location: 1),
                ],
                startPoint: UnitPoint(x: 0.74, y: 0.20),
                endPoint: UnitPoint(x: 0.22, y: 0.84)
            ))
            .overlay {
                LightApertureShape()
                    .fill(RadialGradient(
                        stops: [
                            .init(color: Color(red: 1.00, green: 0.985, blue: 0.91).opacity(colorScheme == .dark ? 0.60 : 0.54), location: 0),
                            .init(color: Color(red: 1.00, green: 0.96, blue: 0.78).opacity(0.20), location: 0.60),
                            .init(color: .clear, location: 0.94),
                        ],
                        center: UnitPoint(x: 0.45, y: 0.54),
                        startRadius: 0,
                        endRadius: side * 0.58
                    ))
            }
            .overlay {
                LightApertureShape()
                    .fill(LinearGradient(
                        stops: [
                            .init(color: .black.opacity(colorScheme == .dark ? 0.22 : 0.18), location: 0),
                            .init(color: .black.opacity(colorScheme == .dark ? 0.09 : 0.07), location: 0.24),
                            .init(color: .clear, location: 0.52),
                            .init(color: .white.opacity(colorScheme == .dark ? 0.04 : 0.07), location: 1),
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ))
                    .blendMode(.multiply)
            }
            .shadow(color: glow, radius: dimension * 0.0082)
            .frame(width: side, height: side)
            .offset(x: -dimension * StandardMark.lightOffset, y: -dimension * StandardMark.lightOffset)
    }

    private var pearlStops: [Gradient.Stop] {
        let first = colorScheme == .dark
            ? Color(red: 0.995, green: 0.99, blue: 0.975)
            : Color(red: 1.00, green: 0.998, blue: 0.985)
        return [
            .init(color: first, location: 0),
            .init(color: Color(red: 0.975, green: 0.975, blue: 0.968), location: 0.62),
            .init(color: Color(red: 0.93, green: 0.937, blue: 0.945), location: 1),
        ]
    }
}
