//===--- WelcomeReveal.swift - GlassIntroKit --------------------------------===//
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

/// The welcome's lines come into focus one after another, rising a little
/// as they sharpen, and leave together.
struct WelcomeReveal: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    let isRevealed: Bool
    let order: Int
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(isRevealed ? 1 : 0)
            .blur(radius: isRevealed || reducesMotion ? 0 : 10)
            .offset(y: isRevealed || reducesMotion ? 0 : 16)
            .animation(
                reducesMotion ? .easeOut(duration: 0.2) : isRevealed
                    ? .smooth(duration: 0.9).delay(Double(order) * 0.14 + delay)
                    : .easeIn(duration: 0.3),
                value: isRevealed
            )
    }
}

extension View {
    /// Return continues from the page on screen only.
    @ViewBuilder
    func welcomeDefaultAction(_ isActive: Bool) -> some View {
        // Preserve the button's identity throughout its reveal animation.
        keyboardShortcut(isActive ? .defaultAction : nil)
    }
}

/// Where the welcome is: a dot for each page, the current one drawn out
/// into a short bar.
struct WelcomePageDots: View {
    let current: Int
    let count: Int
    let isRevealed: Bool

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(index == current ? 0.95 : index < current ? 0.5 : 0.25))
                    .frame(width: index == current ? 18 : 6, height: 6)
                    .modifier(WelcomeReveal(isRevealed: isRevealed, order: 0, delay: Double(index) * 0.035))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Page \(current + 1) of \(count)", bundle: .module))
    }
}
