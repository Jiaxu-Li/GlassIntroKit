//===--- GlassIntroPage.swift - GlassIntroKit -------------------------------===//
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

/// One page of the welcome: a title, a message, and the picture it turns to.
///
/// Pages may come in any order, as often as you like. Each picture gathers
/// into a drop of glass that the next one grows out of; pictures that belong
/// together, such as `.greeting` followed by `.mark`, carry straight on from
/// one another instead.
///
/// ```swift
/// .symbols("Everything in Reach", message: "Maps, photos, and notes.")
///     .background(.color(.indigo))
/// ```
public struct GlassIntroPage {
    /// The picture a page turns to.
    nonisolated public enum Visual: CaseIterable, Hashable, Sendable {
        /// The mark gathers into a pen and writes "hello" in glass.
        case greeting
        /// The mark in glass, its detail opening.
        case mark
        /// The mark melts into a symbol, and glass symbols scatter out of it.
        case symbols
        /// A glass lens opens over a live scene: an object rendered with
        /// Metal that can be turned by dragging, or a view of your own.
        case scene
        /// A wire shoots out of a glass point, and a graph of nodes grows.
        case graph
        /// Nodes fall onto a line under real physics.
        case physics
        /// Glass gathers into an app icon that is polished and badged.
        case icon
        /// Your own view, on a card of glass.
        case card
    }

    /// The picture the page turns to.
    public let visual: Visual
    /// The page's title and the line beneath it, shown below the picture.
    public let title: Text
    public let message: Text
    /// The symbols the page shows: the scattered symbols, the nodes, or the
    /// icon's symbol and its badge.
    public let symbols: [String]
    /// The symbol the mark melts into on a `symbols` page.
    public let centerSymbol: String?
    /// The nodes and wires of a `graph` page.
    public private(set) var graph: GlassIntroGraph?
    /// What a `scene` page renders, unless it shows a view of its own.
    public private(set) var scene = GlassIntroScene()
    /// What the page shows behind its picture.
    public private(set) var background: GlassIntroBackground = .automatic
    /// The button that turns to the next page, if not the intro's own.
    public private(set) var continueButton: Text?
    /// The view a `card` page shows on its glass, or a `scene` page through
    /// its lens.
    let customContent: (@MainActor () -> AnyView)?

    /// A page with a picture, text, and symbols of your choice.
    public init(
        _ visual: Visual,
        title: Text,
        message: Text,
        symbols: [String] = [],
        centerSymbol: String? = nil
    ) {
        self.init(visual, title: title, message: message, symbols: symbols, centerSymbol: centerSymbol, customContent: nil)
    }

    init(
        _ visual: Visual,
        title: Text,
        message: Text,
        symbols: [String],
        centerSymbol: String?,
        customContent: (@MainActor () -> AnyView)?
    ) {
        self.visual = visual
        self.title = title
        self.message = message
        self.symbols = symbols.isEmpty ? Self.defaultSymbols(for: visual) : symbols
        self.centerSymbol = centerSymbol
        self.customContent = customContent
        if visual == .graph {
            graph = .branching(self.symbols)
        }
    }

    /// "hello", written in glass.
    public static func greeting(_ title: LocalizedStringKey, message: LocalizedStringKey) -> Self {
        Self(.greeting, title: Text(title), message: Text(message))
    }

    /// The mark in glass.
    public static func mark(_ title: LocalizedStringKey, message: LocalizedStringKey) -> Self {
        Self(.mark, title: Text(title), message: Text(message))
    }

    /// The mark melts into `center`, by default the mark's own symbol, and
    /// `symbols` scatter out of it in two rings.
    public static func symbols(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey,
        symbols: [String] = defaultScatterSymbols,
        center: String? = nil
    ) -> Self {
        Self(.symbols, title: Text(title), message: Text(message), symbols: symbols, centerSymbol: center)
    }

    /// An object on a studio floor, rendered live with Metal, that can be
    /// turned by dragging: its shape, colour, and motion are `scene`'s.
    public static func scene(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey,
        scene: GlassIntroScene = GlassIntroScene()
    ) -> Self {
        var page = Self(.scene, title: Text(title), message: Text(message))
        page.scene = scene
        return page
    }

    /// Your own view, such as a `RealityView` or a video, seen through the
    /// glass lens and filling the window once the lens has opened. The view
    /// is laid out across the whole window, and is not interactive.
    public static func scene<Content: View>(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Self {
        Self(
            .scene,
            title: Text(title),
            message: Text(message),
            symbols: [],
            centerSymbol: nil,
            customContent: { AnyView(content()) }
        )
    }

    /// A graph whose first node branches out to the rest, each showing one
    /// of `nodes`.
    public static func graph(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey,
        nodes: [String] = defaultNodeSymbols
    ) -> Self {
        Self(.graph, title: Text(title), message: Text(message), symbols: nodes)
    }

    /// A graph of your own: any nodes, wired as `graph` says.
    public static func graph(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey,
        graph: GlassIntroGraph
    ) -> Self {
        var page = Self(.graph, title: Text(title), message: Text(message), symbols: graph.nodes)
        if !graph.nodes.isEmpty {
            page.graph = graph
        }
        return page
    }

    /// Nodes, each showing one of `nodes`, fall onto a line under real
    /// physics; up to eight. Right after a `graph` page, the graph's own
    /// nodes fall.
    public static func physics(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey,
        nodes: [String] = defaultNodeSymbols
    ) -> Self {
        Self(.physics, title: Text(title), message: Text(message), symbols: nodes)
    }

    /// Glass gathers into an app icon showing `symbol`, with `badge`.
    public static func icon(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey,
        symbol: String = "shippingbox.fill",
        badge: String = "checkmark"
    ) -> Self {
        Self(.icon, title: Text(title), message: Text(message), symbols: [symbol, badge])
    }

    /// Your own view, on a card of glass that grows out of the glass before
    /// it. The view is laid out in the card's frame; keep it light, with text
    /// and images in white or other light colours.
    public static func card<Content: View>(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> Self {
        Self(
            .card,
            title: Text(title),
            message: Text(message),
            symbols: [],
            centerSymbol: nil,
            customContent: { AnyView(content()) }
        )
    }

    /// The page with `background` behind it.
    public func background(_ background: GlassIntroBackground) -> Self {
        var page = self
        page.background = background
        return page
    }

    /// The page with `label` on the button that turns to the next page.
    public func continueButton(_ label: Text) -> Self {
        var page = self
        page.continueButton = label
        return page
    }

    /// Symbols for the scatter that anyone may use: none of them refers to a
    /// particular Apple product.
    nonisolated public static let defaultScatterSymbols = [
        "paintbrush.pointed.fill", "music.note", "photo.fill", "map.fill", "gamecontroller.fill",
        "globe.americas.fill", "bolt.fill", "leaf.fill", "star.fill",
        "cpu.fill", "cube.transparent.fill", "square.stack.3d.up.fill", "hand.tap.fill",
        "keyboard.fill", "sparkles", "wand.and.stars",
    ]

    /// Symbols for the nodes of a graph or physics page that names none.
    nonisolated public static let defaultNodeSymbols = ["arrow.triangle.branch", "rotate.3d.fill", "speaker.wave.2.fill"]

    nonisolated static func defaultSymbols(for visual: Visual) -> [String] {
        switch visual {
        case .symbols:
            defaultScatterSymbols
        case .graph, .physics:
            defaultNodeSymbols
        case .icon:
            ["shippingbox.fill", "checkmark"]
        case .greeting, .mark, .scene, .card:
            []
        }
    }
}

/// What a page shows behind its picture.
public enum GlassIntroBackground {
    /// The picture's own light.
    case automatic
    /// Soft light in `color`.
    case color(Color)
    /// A picture of your own, filling the window.
    case image(Image)
}
