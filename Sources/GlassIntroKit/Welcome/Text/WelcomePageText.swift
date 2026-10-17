//===--- WelcomePageText.swift - GlassIntroKit ------------------------------===//
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

/// A page's text: one title, one message, and the button that turns the
/// page.
struct WelcomePageText: View {
    let page: GlassIntroPage
    let index: Int
    let pageCount: Int
    let continueButton: Text
    let isRevealed: Bool
    let isEnabled: Bool
    let isCompact: Bool
    let onContinue: () -> Void
    /// Reports where the text's top sits in the welcome.
    let onTopChange: (CGFloat) -> Void

    var body: some View {
        VStack(spacing: 10) {
            WelcomePageDots(current: index, count: pageCount, isRevealed: isRevealed)
                .padding(.bottom, 8)

            page.title
                .font(.system(size: isCompact ? 26 : 32, weight: .semibold))
                .modifier(WelcomeReveal(isRevealed: isRevealed, order: 0))

            page.message
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.72))
                .frame(maxWidth: 460)
                .modifier(WelcomeReveal(isRevealed: isRevealed, order: 1))

            Button(action: onContinue) {
                (page.continueButton ?? continueButton)
                    .frame(minWidth: 160)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .welcomeDefaultAction(isRevealed)
            .disabled(!isRevealed || !isEnabled)
            .padding(.top, 18)
            .modifier(WelcomeReveal(isRevealed: isRevealed, order: 2))
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.white)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .named(WelcomeView.coordinateSpace)).minY
        } action: { top in
            onTopChange(top)
        }
        .allowsHitTesting(isRevealed)
        .accessibilityHidden(!isRevealed)
    }
}

/// The last page: one line at the center, and the button that begins.
struct WelcomeReadyText: View {
    let index: Int
    let pageCount: Int
    let title: Text
    let button: Text
    let isRevealed: Bool
    let isEnabled: Bool
    let isCompact: Bool
    let onBegin: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            WelcomePageDots(current: index, count: pageCount, isRevealed: isRevealed)
            title
                .font(.system(size: isCompact ? 34 : 46, weight: .semibold))
                .modifier(WelcomeReveal(isRevealed: isRevealed, order: 0))
            Button(action: onBegin) {
                button
                    .frame(minWidth: 160)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .welcomeDefaultAction(isRevealed)
            .disabled(!isRevealed || !isEnabled)
            .modifier(WelcomeReveal(isRevealed: isRevealed, order: 1))
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.white)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(isRevealed)
        .accessibilityHidden(!isRevealed)
    }
}
