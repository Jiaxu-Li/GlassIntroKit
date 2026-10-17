//===--- IntroMotion.swift - GlassIntroKit ----------------------------------===//
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

/// One picture of the welcome, from the moment it starts to come in.
///
/// A motion is built when its page turns in, from what came before it,
/// and from then on is a pure function of time: `frame(at:)` describes the
/// picture `time` seconds after it began, and comes to rest at
/// `settleTime`. Every motion can come in from the seed, so any page can
/// follow any other; a motion that knows the picture before it can carry
/// straight on from it instead.
nonisolated protocol IntroMotion: Sendable {
    var context: IntroContext { get }
    /// When the picture has come to rest.
    var settleTime: Double { get }
    /// When the page's text comes in.
    var textTime: Double { get }
    /// Whether the picture keeps moving once at rest, as a live scene does.
    var isLive: Bool { get }
    /// Whether the picture can be turned by dragging across it.
    var isInteractive: Bool { get }
    /// Whether the picture grows out of the seed itself. Otherwise the seed
    /// shrinks away beneath it as it comes in, so its first frame must start
    /// from nothing, or from the seed's center.
    var absorbsSeed: Bool { get }
    /// How long the picture takes to leave for the seed.
    var exitDuration: Double { get }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame
    /// What the picture offers the next page if the page turns `time`
    /// seconds in. Only called once the picture is at rest.
    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff
    /// The picture leaving for the seed, `progress` of the way into it.
    /// `frame` is what the picture shows at `time`, as it is on screen.
    func exitFrame(from frame: IntroFrame, at time: Double, progress: Double) -> IntroFrame
}

nonisolated extension IntroMotion {
    var isLive: Bool {
        false
    }

    var isInteractive: Bool {
        false
    }

    var absorbsSeed: Bool {
        false
    }

    var exitDuration: Double {
        IntroFrame.collapseDuration
    }

    func handoff(at time: Double, interaction: IntroInteraction) -> IntroHandoff {
        .other
    }

    func exitFrame(from frame: IntroFrame, at time: Double, progress: Double) -> IntroFrame {
        frame.collapsed(into: context.canvas.seed, progress: progress, canvas: context.canvas)
    }
}

/// Where a motion starts from.
nonisolated enum IntroEntry: Sendable {
    /// The seed, at the canvas's graphic center.
    case seed
    /// Nothing: the picture before has dissolved where it was.
    case empty
    /// The picture before it, at rest, which this motion carries straight
    /// on from.
    case handoff(IntroHandoff)
}

/// What a picture at rest offers the page after it.
nonisolated enum IntroHandoff: Sendable {
    /// The mark in colour at the canvas's center, as the launch leaves it.
    case launch
    /// "hello", written in glass.
    case word
    /// The mark in glass at the graphic center, its detail open.
    case mark
    /// The mark melted into its center symbol, the symbols scattered: the
    /// symbols page's own symbols, so the next picture can gather them.
    case symbols(scatter: [String], center: String?)
    /// The live scene across the canvas, the object posed at `yaw`,
    /// `pitch`, and `lift`, looking as `look` says.
    case scene(yaw: Float, pitch: Float = 0, lift: Float = 0, look: SceneLook = .standard)
    /// The graph's wires and nodes.
    case graph(GraphFrame)
    /// The nodes where they fell.
    case fallen(PhysicsFrame)
    /// Nothing a page can carry on from.
    case other
}

/// What the viewer is doing to the picture.
nonisolated struct IntroInteraction: Sendable {
    /// The cube's turn added by dragging it.
    var yawOffset: Double = 0
    var reducesMotion = false
}

/// What a motion knows about the welcome and its page.
nonisolated struct IntroContext: Sendable {
    let canvas: IntroCanvas
    let markOutline: GlassIntroMarkOutline
    /// Every traced symbol, each fitted to a unit square centered on the
    /// origin.
    let outlines: [String: Path]
    /// The page the picture belongs to.
    let page: Int
    /// The page's symbols: the scattered ones, the graph's nodes, or the
    /// icon's symbol and badge.
    let symbols: [String]
    /// The symbol the mark melts into on a symbols page.
    let centerSymbol: String?
    /// A graph page's nodes and wires.
    var graph: GlassIntroGraph? = nil
    /// What a scene page shows.
    var scene = SceneLook.standard
    /// The mark's own symbol, for a symbol mark.
    let markSymbol: String?
    /// The words of the welcome's ending.
    let words: [String]
    /// The top of the page's text, in the canvas.
    let textTop: CGFloat

    /// The page's graph: its own, or its symbols with the first branching
    /// out to the rest.
    var nodeGraph: GlassIntroGraph {
        graph ?? .branching(symbols.isEmpty ? GlassIntroPage.defaultNodeSymbols : symbols)
    }

    /// The mark's traced symbol, cut out of its body in glass.
    var markSymbolOutline: Path? {
        markSymbol.flatMap { outlines[$0] }
    }

    /// The traced symbol the mark melts into, if any.
    var centerGlyph: CenterGlyph? {
        centerSymbol.flatMap { outlines[$0] }.map(CenterGlyph.init(unitPath:))
    }

    /// The mark in glass, laid out in the square of `rect`, its detail
    /// `opening` of the way open.
    func glassMark(in rect: CGRect, opening: CGFloat) -> Path {
        markOutline.path(in: rect, apertureOpening: opening, symbolOutline: markSymbolOutline)
    }
}
