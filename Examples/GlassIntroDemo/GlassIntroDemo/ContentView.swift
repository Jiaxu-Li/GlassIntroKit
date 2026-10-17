//===--- ContentView.swift - GlassIntroKit ----------------------------------===//
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

/// The demo: adjust the intro, play it, and land in the app it opens onto.
struct ContentView: View {
    @State private var settings = IntroSettings()
    /// Whether the intro plays. The kit sets it back to false when the intro
    /// ends.
    @State private var showsIntro = false
    /// Whether the app the intro opens onto is shown, rather than the
    /// settings.
    @State private var showsApp = false

    var body: some View {
        NavigationStack {
            if showsApp {
                HelloView(appName: settings.appName) {
                    showsApp = false
                }
            } else {
                SettingsView(settings: settings) {
                    showsApp = true
                    showsIntro = true
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 640, minHeight: 520)
        #endif
        .glassIntro(settings.intro, isPresented: $showsIntro)
    }
}

#Preview {
    ContentView()
}
