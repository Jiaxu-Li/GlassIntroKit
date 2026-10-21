//===--- IntroSettings.swift - GlassIntroKit --------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import GlassIntroKit
import SwiftUI

/// Everything the demo lets you change about the intro. It makes the intro
/// itself, and the code that makes the same intro.
@Observable
final class IntroSettings {
    var appName = "MyApp"
    /// The kit's own mark when nil; otherwise a white body with this symbol.
    var markSymbol: String?
    var markColor = Color.blue
    var opening = GlassIntro.Opening.mark

    /// The pages shown, always in the order they were made for.
    var pages: Set<PageKind> = [.greeting, .mark, .symbols, .scene, .graph, .physics, .icon]
    /// The forest picture is for this demo only; see `Examples/GlassIntroDemo/ASSETS.md`.
    var greetingOverForest = true
    var sceneSource = SceneSource.rendered
    var sceneShape = GlassIntroScene.Shape.cube
    var sceneColor = Color(red: 0.91, green: 0.90, blue: 0.88)
    var sceneMotion = MotionChoice.turntable
    var revealsRendering = true
    var graphShape = GraphShape.branch
    var graphNodeCount = 3
    var physicsNodeCount = 3
    var iconSymbol = "shippingbox.fill"
    var card = CardContent.itinerary

    var finale = FinaleChoice.standard
    var customFinale = "Have a\ngood day"
    var startTitle = ""
    var startButton = ""
    var continueButton = ""
    var showsSkipButton = true

    static let markSymbols = [
        "sparkles", "globe.americas.fill", "leaf.fill", "bolt.fill", "star.fill",
        "paperplane.fill", "camera.fill", "music.note", "heart.fill",
    ]
    static let iconSymbols = [
        "shippingbox.fill", "suitcase.rolling.fill", "paperplane.fill", "camera.fill", "checkmark.seal.fill",
    ]
    static let scatterSymbols = [
        "map.fill", "airplane", "photo.fill", "music.note", "camera.fill",
        "fork.knife", "bed.double.fill", "tram.fill", "sun.max.fill",
        "suitcase.rolling.fill", "ticket.fill", "mappin.and.ellipse", "binoculars.fill",
        "figure.hiking", "leaf.fill", "star.fill",
    ]
    static let nodeSymbols = [
        "airplane.departure", "bed.double.fill", "fork.knife", "camera.fill",
        "tram.fill", "ticket.fill", "binoculars.fill", "airplane.arrival",
    ]

    var orderedPages: [PageKind] {
        PageKind.allCases.filter(pages.contains)
    }

    var graphNodes: [String] {
        Array(Self.nodeSymbols.prefix(max(graphNodeCount, graphShape.minimumNodes)))
    }

    var physicsNodes: [String] {
        Array(Self.nodeSymbols.prefix(physicsNodeCount))
    }

    /// The words of the ending, or nil for the kit's own.
    var finaleWords: [String]? {
        switch finale {
        case .standard:
            nil
        case .custom:
            customFinale.split(whereSeparator: \.isNewline).map(String.init)
        case .none:
            []
        }
    }

    var intro: GlassIntro {
        GlassIntro(
            appName: appName,
            mark: markSymbol.map { .symbol($0, color: markColor) } ?? .standard,
            pages: orderedPages.map(page),
            finale: finaleWords,
            startTitle: startTitle.isEmpty ? nil : Text(verbatim: startTitle),
            startButton: startButton.isEmpty ? nil : Text(verbatim: startButton),
            continueButton: continueButton.isEmpty ? nil : Text(verbatim: continueButton),
            showsSkipButton: showsSkipButton,
            welcome: .everyLaunch,
            opening: opening
        )
    }

    private func page(_ kind: PageKind) -> GlassIntroPage {
        switch kind {
        case .greeting:
            let page = GlassIntroPage.greeting("Welcome to \(appName)", message: "Everything you need, in one place.")
            return greetingOverForest ? page.background(.image(Image("Forest"))) : page
        case .mark:
            return .mark("Simple, by Design", message: "One calm place for all of it.")
        case .symbols:
            return .symbols("Everything in Reach", message: "Maps, photos, and music gather around you.", symbols: Self.scatterSymbols)
        case .scene:
            switch sceneSource {
            case .rendered:
                return .scene("Seen in Depth", message: "A live 3D preview. Drag to turn it.", scene: GlassIntroScene(
                    shape: sceneShape,
                    color: sceneColor,
                    motion: sceneMotion.motion,
                    revealsRendering: revealsRendering
                ))
            case .realityKit:
                return .scene("Seen in Depth", message: "A RealityKit view of your own.") { RealitySceneView() }
            case .swiftUI:
                return .scene("Seen in Depth", message: "Any SwiftUI view of your own.") { SpinningGlobeView() }
            }
        case .graph:
            return .graph("Connected", message: "A change in one place updates the rest.", graph: graph)
        case .physics:
            return .physics("Feels Real", message: "Everything responds the way you expect.", nodes: physicsNodes)
        case .icon:
            return .icon("Ready When You Are", message: "Packed and ready to go.", symbol: iconSymbol)
        case .card:
            return switch card {
            case .itinerary: .card("Your Own View", message: "Any view can be a page.") { ItineraryCard() }
            case .stats: .card("Your Own View", message: "Any view can be a page.") { StatsCard() }
            case .checklist: .card("Your Own View", message: "Any view can be a page.") { ChecklistCard() }
            }
        }
    }

    private var graph: GlassIntroGraph {
        let nodes = graphNodes
        return switch graphShape {
        case .branch: .branch(nodes[0], into: Array(nodes.dropFirst()))
        case .chain: .chain(nodes)
        case .diamond: .diamond(nodes[0], through: Array(nodes.dropFirst().dropLast()), into: nodes[nodes.count - 1])
        }
    }
}
