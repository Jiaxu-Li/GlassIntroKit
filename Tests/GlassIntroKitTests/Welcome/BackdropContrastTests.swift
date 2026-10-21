//===--- BackdropContrastTests.swift - GlassIntroKit ------------------------===//
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
import Testing
@testable import GlassIntroKit

/// With Reduce Transparency on, every page shows one solid colour, and
/// the white text and buttons on it must stay clear.
@Suite @MainActor struct BackdropContrastTests {
    /// WCAG contrast of white against `color`.
    private func contrastWithWhite(_ color: Color) -> Double {
        let resolved = color.resolve(in: EnvironmentValues())
        let luminance = 0.2126 * Double(resolved.linearRed)
            + 0.7152 * Double(resolved.linearGreen)
            + 0.0722 * Double(resolved.linearBlue)
        return 1.05 / (luminance + 0.05)
    }

    @Test func everyPictureHasAClearSolidColour() {
        let pictures: [IntroPicture] = [.launch, .rest, .finale] + GlassIntroPage.Visual.allCases.map { .page($0) }
        for picture in pictures {
            for background in [GlassIntroBackground.automatic, .image(Image(systemName: "photo"))] {
                let solid = BackdropStyle(background, picture: picture).solid
                #expect(contrastWithWhite(solid) >= 7, "\(picture)")
            }
        }
    }

    @Test func evenALightPageColourStaysClear() {
        for color in [Color.white, .yellow, .mint, .cyan, .pink, Color(white: 0.8)] {
            let solid = BackdropStyle(.color(color), picture: .page(.mark)).solid
            #expect(contrastWithWhite(solid) >= 7, "\(color)")
        }
    }
}
