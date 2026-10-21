//===--- IntroButtonStyle.swift - GlassIntroKit -----------------------------===//
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

extension View {
    /// The intro's buttons: Liquid Glass, or with Reduce Transparency on,
    /// opaque bordered buttons that stay legible over any picture.
    @ViewBuilder
    func introButtonStyle(prominent: Bool, reducesTransparency: Bool) -> some View {
        switch (prominent, reducesTransparency) {
        case (true, false):
            buttonStyle(.glassProminent)
        case (true, true):
            buttonStyle(.borderedProminent)
        case (false, false):
            buttonStyle(.glass)
        case (false, true):
            buttonStyle(.bordered)
        }
    }
}
