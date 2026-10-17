//===--- DemoChoices.swift - GlassIntroKit ----------------------------------===//
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

extension Color {
    /// How the colour is written in Swift.
    var code: String {
        let rgb = resolve(in: EnvironmentValues())
        return String(format: "Color(red: %.2f, green: %.2f, blue: %.2f)", rgb.red, rgb.green, rgb.blue)
    }
}

/// Each picture the welcome can show, in the order they were made for: each
/// carries straight on from the one before.
enum PageKind: String, CaseIterable, Identifiable {
    case greeting, mark, symbols, scene, graph, physics, icon, card

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .greeting: "Greeting"
        case .mark: "Mark"
        case .symbols: "Symbols"
        case .scene: "3D Scene"
        case .graph: "Graph"
        case .physics: "Physics"
        case .icon: "Icon"
        case .card: "Card"
        }
    }

    var systemImage: String {
        switch self {
        case .greeting: "hand.wave.fill"
        case .mark: "circle.circle.fill"
        case .symbols: "sparkles"
        case .scene: "cube.fill"
        case .graph: "point.3.connected.trianglepath.dotted"
        case .physics: "arrow.down.to.line"
        case .icon: "app.badge.fill"
        case .card: "rectangle.on.rectangle"
        }
    }
}

/// What a scene page shows through its lens.
enum SceneSource: String, CaseIterable, Identifiable {
    case rendered, realityKit, swiftUI

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .rendered: "Rendered Object"
        case .realityKit: "RealityKit View"
        case .swiftUI: "SwiftUI View"
        }
    }
}

/// How the scene's object moves.
enum MotionChoice: String, CaseIterable, Identifiable {
    case turntable, tumble, float, still

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .turntable: "Turntable"
        case .tumble: "Tumble"
        case .float: "Float"
        case .still: "Still"
        }
    }

    var motion: GlassIntroScene.Motion {
        switch self {
        case .turntable: .turntable
        case .tumble: .tumble
        case .float: .float
        case .still: .still
        }
    }
}

extension GlassIntroScene.Shape {
    var title: LocalizedStringKey {
        switch self {
        case .cube: "Cube"
        case .sphere: "Sphere"
        case .ring: "Ring"
        case .capsule: "Capsule"
        case .cylinder: "Cylinder"
        }
    }
}

/// How a graph page wires its nodes.
enum GraphShape: String, CaseIterable, Identifiable {
    case branch, chain, diamond

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .branch: "Branch"
        case .chain: "Chain"
        case .diamond: "Diamond"
        }
    }

    /// The fewest nodes the shape is drawn with.
    var minimumNodes: Int {
        self == .diamond ? 3 : 1
    }
}

/// What a card page shows.
enum CardContent: String, CaseIterable, Identifiable {
    case itinerary, stats, checklist

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .itinerary: "Itinerary"
        case .stats: "Statistics"
        case .checklist: "Checklist"
        }
    }

    var typeName: String {
        switch self {
        case .itinerary: "ItineraryCard"
        case .stats: "StatsCard"
        case .checklist: "ChecklistCard"
        }
    }
}

/// The words after the last page.
enum FinaleChoice: String, CaseIterable, Identifiable {
    /// "Welcome", "to", and the app's name.
    case standard
    case custom
    case none

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .standard: "Welcome to …"
        case .custom: "Your Own"
        case .none: "None"
        }
    }
}
