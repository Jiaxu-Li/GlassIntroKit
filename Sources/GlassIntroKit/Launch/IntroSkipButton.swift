//===--- IntroSkipButton.swift - GlassIntroKit ------------------------------===//
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

/// The button in the corner that skips the welcome, on every platform.
struct IntroSkipButton: View {
    @Environment(\.accessibilityReduceTransparency) private var reducesTransparency

    let label: Text
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
                .padding(.horizontal, 4)
                // White, not the accent colour, which reads weakly on the
                // opaque button Reduce Transparency brings.
                .foregroundStyle(.white)
        }
        .introButtonStyle(prominent: false, reducesTransparency: reducesTransparency)
        .controlSize(.regular)
        // The welcome is always dark, whatever the app's appearance.
        .environment(\.colorScheme, .dark)
        .accessibilityHint(Text("Skips the welcome. It won't show again.", bundle: .module))
    }
}
