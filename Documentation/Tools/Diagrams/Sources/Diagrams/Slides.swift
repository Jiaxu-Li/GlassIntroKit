//===--- Slides.swift - GlassIntroKit ---------------------------------------===//
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

/// The layers an intro is built from, from your app down to the system.
struct LayersSlide: View {
    var body: some View {
        Slide {
            let left: CGFloat = 250
            let width: CGFloat = 1100
            let rows: [CGFloat] = [190, 270, 350, 430, 510, 590, 670]
            Block(text: "Your app", color: Tone.gray, width: width, height: 54).at(800, rows[0])
            Block(text: ".glassIntro(_:)   ·   .glassIntro(_:isPresented:)", color: Tone.green, width: width, height: 54, code: true).at(800, rows[1])
            Block(text: "GlassIntro — appName · mark · pages · finale · opening · welcome · storage", color: Tone.green, width: width, height: 54).at(800, rows[2])
            Block(text: "Launch", color: Tone.lavender, width: 360, height: 54).at(left + 180, rows[3])
            Block(text: "Welcome player", color: Tone.indigo, width: 360, height: 54).at(800, rows[3])
            Block(text: "Ending", color: Tone.lavender, width: 360, height: 54).at(left + width - 180, rows[3])
            ForEach(Array(["greeting", "mark", "symbols", "scene", "graph", "physics", "icon", "card"].enumerated()), id: \.offset) { index, name in
                Block(text: name, color: Tone.violet, width: 128, height: 54, code: true)
                    .at(left + 64 + CGFloat(index) * (width - 128) / 7, rows[4])
            }
            ForEach(Array(["SwiftUI", "Liquid Glass", "Metal", "Rigid-body physics"].enumerated()), id: \.offset) { index, name in
                Block(text: name, color: index < 2 ? Tone.pale : Tone.lavender, width: 266, height: 54)
                    .at(left + 133 + CGFloat(index) * (width - 266) / 3, rows[5])
            }
            Block(text: "iOS 26  ·  macOS 26", color: Tone.orange, width: width, height: 54).at(800, rows[6])
        }
    }
}

/// How an intro plays.
struct FlowSlide: View {
    var body: some View {
        Slide {
            Connectors(lines: [
                .init(from: CGPoint(x: 345, y: 450), to: CGPoint(x: 548, y: 450), dashed: true),
                .init(from: CGPoint(x: 862, y: 330), to: CGPoint(x: 1030, y: 330)),
                .init(from: CGPoint(x: 862, y: 450), to: CGPoint(x: 1030, y: 450)),
                .init(from: CGPoint(x: 862, y: 570), to: CGPoint(x: 1030, y: 570)),
                .init(from: CGPoint(x: 1180, y: 600), to: CGPoint(x: 1180, y: 700)),
            ])
            Block(text: "GlassIntro", width: 210).at(240, 450)
            Caption(text: "first launch, or isPresented").at(447, 424)
            Panel(width: 330, height: 380).at(705, 450)
            Block(text: "Launch", width: 270).at(705, 330)
            Block(text: "Welcome", width: 270).at(705, 450)
            Block(text: "Ending", width: 270).at(705, 570)
            StackedBlock(text: "Mark comes up on frosted glass", width: 300).at(1196, 330)
            StackedBlock(text: "Your pages, one at a time", width: 300).at(1196, 450)
            StackedBlock(text: "Words, then the mark in colour", width: 300).at(1196, 570)
            Block(text: "Your app", color: Tone.gray, width: 300).at(1180, 730)
            Caption(text: "the mark dissolves where it is").at(1300, 650)
        }
    }
}

/// How one page leads to the next.
struct TransitionsSlide: View {
    var body: some View {
        Slide {
            let names = ["greeting", "mark", "symbols", "scene", "graph", "physics", "icon"]
            Connectors(lines: (0..<6).map { index in
                .init(from: CGPoint(x: 548 + CGFloat(index) * 160, y: 250), to: CGPoint(x: 572 + CGFloat(index) * 160, y: 250))
            } + [
                .init(from: CGPoint(x: 560, y: 450), to: CGPoint(x: 712, y: 450)),
                .init(from: CGPoint(x: 788, y: 450), to: CGPoint(x: 940, y: 450)),
                .init(from: CGPoint(x: 560, y: 650), to: CGPoint(x: 820, y: 650)),
            ])
            Caption(text: "Carries straight on", size: 22, weight: .semibold, color: Tone.ink).at(220, 236)
            Caption(text: "Pictures made to follow one another").at(220, 266)
            ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                Block(text: ".\(name)", width: 128, code: true).at(484 + CGFloat(index) * 160, 250)
            }
            Caption(text: "Meets in a drop of glass", size: 22, weight: .semibold, color: Tone.ink).at(220, 436)
            Caption(text: "Any other two").at(220, 466)
            Block(text: ".icon", width: 128, code: true).at(484, 450)
            Caption(text: "gathers").at(636, 426)
            Circle().fill(Tone.pale).overlay(Circle().strokeBorder(Tone.indigo, lineWidth: 2)).frame(width: 52, height: 52).at(750, 450)
            Caption(text: "grows").at(864, 426)
            Block(text: ".greeting", width: 128, code: true).at(1016, 450)
            Caption(text: "Lets go where it is", size: 22, weight: .semibold, color: Tone.ink).at(220, 636)
            Caption(text: "Before the last page").at(220, 666)
            Block(text: "any page", color: Tone.lavender, width: 128).at(484, 650)
            Caption(text: "draws in to nothing").at(690, 626)
            Block(text: "Let's Begin", color: Tone.lavender, width: 160).at(904, 650)
        }
    }
}

/// What a GlassIntro describes.
struct ConfigurationSlide: View {
    private let rows: [(String, String)] = [
        ("mark", ".standard · .symbol · .custom"),
        ("pages", ".greeting … .card, any order"),
        ("finale", "Words of your own, or [ ]"),
        ("startTitle · startButton", "The last page's words"),
        ("opening · welcome", ".mark or .stage · when it plays"),
    ]

    var body: some View {
        Slide {
            Connectors(lines: [.init(from: CGPoint(x: 345, y: 450), to: CGPoint(x: 520, y: 450), dashed: true)]
                + rows.indices.map { index in
                    let y = 270 + CGFloat(index) * 90
                    return .init(from: CGPoint(x: 862, y: y), to: CGPoint(x: 1010, y: y))
                })
            Block(text: "GlassIntro", width: 210).at(240, 450)
            Caption(text: "a value", code: false).at(432, 424)
            Panel(width: 360, height: 480).at(705, 450)
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                let y = 270 + CGFloat(index) * 90
                Block(text: row.0, width: 300, code: true).at(705, y)
                StackedBlock(text: row.1, width: 340).at(1196, y)
            }
        }
    }
}

/// How the kit is built, for contributors.
struct PipelineSlide: View {
    private let names = ["GlassIntro", "WelcomeContent", "IntroMotion", "WelcomePlayer", "IntroFrame", "IntroFrameView"]
    private let notes = ["your configuration", "each page's context", "one per picture", "the timeline", "plain data", "one renderer"]

    var body: some View {
        Slide {
            Connectors(lines: (0..<5).map { index in
                .init(from: CGPoint(x: 290 + CGFloat(index) * 228, y: 400), to: CGPoint(x: 342 + CGFloat(index) * 228, y: 400))
            } + [
                .init(from: CGPoint(x: 1112, y: 604), to: CGPoint(x: 1112, y: 478), dashed: true),
            ])
            ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                let x = 200 + CGFloat(index) * 228
                if name == "IntroMotion" {
                    StackedBlock(text: name, width: 176, code: true).at(x, 400)
                } else {
                    Block(text: name, color: index == 5 ? Tone.green : Tone.indigo, width: 176, code: true).at(x, 400)
                }
                Caption(text: notes[index]).at(x, 456)
            }
            Block(text: "Continuity tests rasterize every frame", color: Tone.lavender, width: 360).at(1112, 630)
            Caption(text: "and fail on any frame that jumps").at(1112, 680)
        }
    }
}

/// A page, as it shows on screen, and what each part of it comes from.
struct AnatomySlide: View {
    /// Each callout, and the point it marks, in the recording's pixels.
    private let callouts: [(label: String, y: CGFloat, point: CGPoint)] = [
        ("Background — .background(.image(_:))", 190, CGPoint(x: 1085, y: 500)),
        ("Picture — .greeting", 340, CGPoint(x: 965, y: 1065)),
        ("Page indicator", 560, CGPoint(x: 785, y: 2030)),
        ("Title and message", 660, CGPoint(x: 905, y: 2145)),
        ("Continue — continueButton(_:)", 790, CGPoint(x: 905, y: 2436)),
    ]

    var body: some View {
        Slide {
            Screen(name: "greeting", height: 820).at(520, 450)
            Connectors(lines: callouts.map { callout in
                .init(
                    from: CGPoint(x: 900, y: callout.y),
                    to: Screen.point(callout.point, height: 820, center: CGPoint(x: 520, y: 450)),
                    head: false,
                    dot: true,
                    via: CGPoint(x: 860, y: callout.y)
                )
            })
            ForEach(Array(callouts.enumerated()), id: \.offset) { _, callout in
                Block(text: callout.label, width: 420, code: false).at(1110, callout.y)
            }
        }
    }
}

/// The story, as it plays.
struct StorySlide: View {
    private let screens: [(name: String, label: String)] = [
        ("launch", "Launch"), ("greeting", ".greeting"), ("mark", ".mark"), ("symbols", ".symbols"), ("scene", ".scene"),
    ]

    var body: some View {
        Slide {
            ForEach(Array(screens.enumerated()), id: \.offset) { index, screen in
                let x = 180 + CGFloat(index) * 290
                Block(text: screen.label, width: 160, code: index > 0).at(x, 160)
                Screen(name: screen.name, height: 520).at(x, 500)
            }
            Connectors(lines: (0..<4).map { index in
                .init(from: CGPoint(x: 311 + CGFloat(index) * 290, y: 500), to: CGPoint(x: 339 + CGFloat(index) * 290, y: 500))
            })
            Caption(text: "each picture carries straight on from the one before").at(800, 812)
        }
    }
}

/// The last page, the ending, and the app.
struct EndingSlide: View {
    private let screens: [(name: String, label: String, code: Bool)] = [
        ("last-page", "startTitle · startButton", true), ("ending", "finale", true), ("colour", "The mark in colour", false), ("app", "Your app", false),
    ]

    var body: some View {
        Slide {
            ForEach(Array(screens.enumerated()), id: \.offset) { index, screen in
                let x = 284 + CGFloat(index) * 330
                Block(text: screen.label, color: index == 3 ? Tone.gray : Tone.indigo, width: 240, code: screen.code).at(x, 160)
                Screen(name: screen.name, height: 520).at(x, 500)
            }
            Connectors(lines: (0..<3).map { index in
                .init(from: CGPoint(x: 414 + CGFloat(index) * 330, y: 500), to: CGPoint(x: 484 + CGFloat(index) * 330, y: 500))
            })
        }
    }
}
