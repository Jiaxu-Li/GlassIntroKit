//===--- GlassIntroMark.swift - GlassIntroKit -------------------------------===//
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

/// The mark the intro forms, writes with, and hands back to the app.
///
/// A mark is a round body with a detail on it. The opening stage closes onto
/// the body, the welcome gathers the body into the point of a pen, and the
/// mark's outline, the body with its detail cut out, is what turns to glass.
///
/// ```swift
/// .symbol("globe.americas.fill", color: .blue)
/// ```
public struct GlassIntroMark {
    /// The body's diameter as a fraction of the mark's square frame.
    public var bodyDiameterRatio: CGFloat
    /// The body's colour, drawn under the mark wherever the intro shows it.
    public var bodyColor: Color
    /// Where colour starts to spread through the mark as the welcome ends,
    /// in the mark's square frame.
    public var light: UnitPoint

    let outline: GlassIntroMarkOutline
    let content: @MainActor () -> AnyView

    /// A white round body with an SF Symbol on it in `color`.
    ///
    /// The symbol is cut out of the body when the mark turns to glass.
    /// Choose a symbol you may use freely: the SF Symbols app marks the
    /// symbols that may only refer to particular Apple products.
    public static func symbol(_ name: String, color: Color = .accentColor) -> GlassIntroMark {
        GlassIntroMark(
            bodyDiameterRatio: GlassIntroMarkOutline.symbolBodyRatio,
            bodyColor: .white,
            light: .center,
            outline: .symbol(name),
            content: { AnyView(SymbolMarkView(symbol: name, color: color)) }
        )
    }

    /// The kit's own mark: a white pearl with a yellow light set into it,
    /// high on its left. In glass, the light is cut out of the pearl.
    public static var standard: GlassIntroMark {
        GlassIntroMark(
            bodyDiameterRatio: StandardMark.pearlRatio,
            bodyColor: .white,
            light: StandardMark.light,
            outline: .standard,
            content: { AnyView(StandardMarkView()) }
        )
    }

    /// A mark of your own.
    ///
    /// - Parameters:
    ///   - bodyDiameterRatio: The round body's diameter as a fraction of the
    ///     mark's square frame.
    ///   - bodyColor: The body's colour.
    ///   - light: Where colour starts to spread at the end of the welcome.
    ///   - outline: The mark as one outline for glass: the body with its
    ///     detail cut out, laid out in the square `rect`. `opening` runs
    ///     from 0, the plain body, to 1, the full detail.
    ///   - view: The mark in colour, drawn to fill a square frame.
    public static func custom<Content: View>(
        bodyDiameterRatio: CGFloat = 0.76,
        bodyColor: Color = .white,
        light: UnitPoint = .center,
        outline: @escaping @Sendable (_ rect: CGRect, _ opening: CGFloat) -> Path,
        @ViewBuilder view: @escaping @MainActor () -> Content
    ) -> GlassIntroMark {
        GlassIntroMark(
            bodyDiameterRatio: bodyDiameterRatio,
            bodyColor: bodyColor,
            light: light,
            outline: .custom(bodyDiameterRatio: bodyDiameterRatio, outline),
            content: { AnyView(view()) }
        )
    }

    /// The SF Symbol on a `.symbol` mark.
    var symbolName: String? {
        if case .symbol(let name) = outline.kind {
            return name
        }
        return nil
    }
}

/// The mark in colour, as the intro draws it: for showing the mark in your
/// own views, such as an about screen.
public struct GlassIntroMarkView: View {
    private let mark: GlassIntroMark

    public init(_ mark: GlassIntroMark) {
        self.mark = mark
    }

    public var body: some View {
        mark.content()
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
    }
}

/// A mark's outline for glass. Kept apart from the mark's view so glass
/// shapes, which are laid out off the main actor, can draw it.
nonisolated struct GlassIntroMarkOutline: Sendable {
    enum Kind: Sendable {
        case symbol(String)
        case custom(@Sendable (CGRect, CGFloat) -> Path)
    }

    /// A symbol mark's body and the symbol's side, as fractions of the
    /// mark's square frame.
    static let symbolBodyRatio: CGFloat = 0.76
    static let symbolSideRatio: CGFloat = 0.36

    let kind: Kind
    let bodyDiameterRatio: CGFloat

    static func symbol(_ name: String) -> GlassIntroMarkOutline {
        GlassIntroMarkOutline(kind: .symbol(name), bodyDiameterRatio: symbolBodyRatio)
    }

    /// The kit's own mark: the pearl with its light's aperture cut out.
    static let standard = GlassIntroMarkOutline.custom(bodyDiameterRatio: StandardMark.pearlRatio) { rect, opening in
        StandardMark.outline(in: rect, opening: opening)
    }

    static func custom(
        bodyDiameterRatio: CGFloat,
        _ outline: @escaping @Sendable (CGRect, CGFloat) -> Path
    ) -> GlassIntroMarkOutline {
        GlassIntroMarkOutline(kind: .custom(outline), bodyDiameterRatio: bodyDiameterRatio)
    }

    /// The outline laid out in the square of `rect`. A symbol mark cuts out
    /// `symbolOutline`, a traced outline fitted to a unit square centered on
    /// the origin; without it, the body shows plain.
    func path(in rect: CGRect, apertureOpening: CGFloat, symbolOutline: Path?) -> Path {
        let opening = min(max(apertureOpening, 0), 1)
        switch kind {
        case .custom(let outline):
            return outline(rect, opening)
        case .symbol:
            let dimension = min(rect.width, rect.height)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let diameter = dimension * bodyDiameterRatio
            let body = Path(ellipseIn: CGRect(
                x: center.x - diameter / 2,
                y: center.y - diameter / 2,
                width: diameter,
                height: diameter
            ))
            guard opening > 0, let symbolOutline else {
                return body
            }
            let side = dimension * Self.symbolSideRatio * opening
            let symbol = symbolOutline.applying(
                CGAffineTransform(translationX: center.x, y: center.y)
                    .scaledBy(x: side, y: side)
            )
            return body.subtracting(symbol)
        }
    }
}

/// A `.symbol` mark in colour: a softly lit white body with the symbol on it.
private struct SymbolMarkView: View {
    let symbol: String
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let dimension = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.white, Color(white: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(
                        width: dimension * GlassIntroMarkOutline.symbolBodyRatio,
                        height: dimension * GlassIntroMarkOutline.symbolBodyRatio
                    )
                    .shadow(color: .black.opacity(0.08), radius: dimension * 0.012, y: dimension * 0.014)
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(color.gradient)
                    .frame(
                        width: dimension * GlassIntroMarkOutline.symbolSideRatio,
                        height: dimension * GlassIntroMarkOutline.symbolSideRatio
                    )
            }
            .frame(width: dimension, height: dimension)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
