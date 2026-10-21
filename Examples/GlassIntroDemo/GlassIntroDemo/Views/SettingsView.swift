//===--- SettingsView.swift - GlassIntroKit ---------------------------------===//
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

/// Everything about the intro, changed in place, with the code that plays it.
struct SettingsView: View {
    @Bindable var settings: IntroSettings
    let onPlay: () -> Void

    var body: some View {
        Form {
            Section("App") {
                TextField("App Name", text: $settings.appName)
                Picker("Mark", selection: $settings.markSymbol) {
                    Text("Standard").tag(String?.none)
                    ForEach(IntroSettings.markSymbols, id: \.self) { Label($0, systemImage: $0).tag(Optional($0)) }
                }
                if settings.markSymbol != nil {
                    ColorPicker("Mark Colour", selection: $settings.markColor, supportsOpacity: false)
                }
                Picker("Opening", selection: $settings.opening) {
                    Text("Straight from the Mark").tag(GlassIntro.Opening.mark)
                    Text("Opening Stage").tag(GlassIntro.Opening.stage)
                }
            }

            Section {
                ForEach(PageKind.allCases) { kind in
                    Toggle(isOn: pageBinding(kind)) {
                        Label(kind.title, systemImage: kind.systemImage)
                    }
                }
            } header: {
                Text("Pages")
            } footer: {
                Text("Pages play in the order shown, each carrying straight on from the one before. In code, pages come in any order.")
            }

            if settings.pages.contains(.greeting) {
                Section("Greeting") {
                    Toggle("Forest Background", isOn: $settings.greetingOverForest)
                }
            }
            if settings.pages.contains(.scene) {
                sceneSection
            }
            if settings.pages.contains(.graph) {
                Section("Graph") {
                    Picker("Shape", selection: $settings.graphShape) {
                        ForEach(GraphShape.allCases) { Text($0.title).tag($0) }
                    }
                    Stepper("\(settings.graphNodes.count) Nodes", value: $settings.graphNodeCount, in: settings.graphShape.minimumNodes...8)
                }
            }
            if settings.pages.contains(.physics) {
                Section {
                    Stepper("\(settings.physicsNodeCount) Nodes", value: $settings.physicsNodeCount, in: 1...8)
                } header: {
                    Text("Physics")
                } footer: {
                    if settings.pages.contains(.graph) {
                        Text("Right after the graph, the graph's own nodes fall.")
                    }
                }
            }
            if settings.pages.contains(.icon) {
                Section("Icon") {
                    Picker("Symbol", selection: $settings.iconSymbol) {
                        ForEach(IntroSettings.iconSymbols, id: \.self) { Label($0, systemImage: $0).tag($0) }
                    }
                }
            }
            if settings.pages.contains(.card) {
                Section("Card") {
                    Picker("Shows", selection: $settings.card) {
                        ForEach(CardContent.allCases) { Text($0.title).tag($0) }
                    }
                }
            }

            Section {
                Picker("Ending Words", selection: $settings.finale) {
                    ForEach(FinaleChoice.allCases) { Text($0.title).tag($0) }
                }
                if settings.finale == .custom {
                    TextField("One Line Each", text: $settings.customFinale, axis: .vertical)
                        .lineLimit(1...3)
                }
                TextField("Last Page Title", text: $settings.startTitle, prompt: Text("Let's Begin"))
                TextField("Last Page Button", text: $settings.startButton, prompt: Text("Get Started"))
                TextField("Continue Button", text: $settings.continueButton, prompt: Text("Continue"))
                Toggle("Skip Button", isOn: $settings.showsSkipButton)
            } header: {
                Text("Words")
            } footer: {
                Text("The ending's words turn in after the last page's button, up to three lines.")
            }

            Section {
                CodeView(code: settings.code)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("GlassIntroKit")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Play", systemImage: "play.fill", action: onPlay)
                    .buttonStyle(.glassProminent)
                    .disabled(settings.pages.isEmpty)
            }
        }
    }

    private var sceneSection: some View {
        Section("3D Scene") {
            Picker("Shows", selection: $settings.sceneSource) {
                ForEach(SceneSource.allCases) { Text($0.title).tag($0) }
            }
            if settings.sceneSource == .rendered {
                Picker("Shape", selection: $settings.sceneShape) {
                    ForEach(GlassIntroScene.Shape.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                ColorPicker("Colour", selection: $settings.sceneColor, supportsOpacity: false)
                Picker("Motion", selection: $settings.sceneMotion) {
                    ForEach(MotionChoice.allCases) { Text($0.title).tag($0) }
                }
                Toggle("Reveal Rendering Level by Level", isOn: $settings.revealsRendering)
            }
        }
    }

    private func pageBinding(_ kind: PageKind) -> Binding<Bool> {
        Binding {
            settings.pages.contains(kind)
        } set: { isOn in
            if isOn {
                settings.pages.insert(kind)
            } else {
                settings.pages.remove(kind)
            }
        }
    }
}
