//===--- HelloView.swift - GlassIntroKit ------------------------------------===//
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

/// The app the intro opens onto: a greeting, a title, and a line beneath it.
struct HelloView: View {
    let appName: String
    let onAdjust: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Hello")
                .font(.system(size: 56, weight: .bold, design: .rounded))
            Text("Welcome to \(appName)")
                .font(.title2.weight(.semibold))
            Text("Everything is ready. Your first day starts here.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Adjust", systemImage: "slider.horizontal.3", action: onAdjust)
            }
        }
    }
}
