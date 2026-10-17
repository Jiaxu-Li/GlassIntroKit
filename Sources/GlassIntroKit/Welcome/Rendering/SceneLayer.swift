//===--- SceneLayer.swift - GlassIntroKit -----------------------------------===//
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

/// The live Metal scene: seen through a lens, or across the canvas,
/// softened toward the text at the bottom.
struct SceneLayer: View {
    let scene: SceneSprite
    let canvasSize: CGSize
    let content: WelcomeContent

    var body: some View {
        ZStack {
            if let page = scene.look.customPage, page < content.pages.count,
               let custom = content.pages[page].customContent {
                // The page's own view, across the whole canvas.
                custom()
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .environment(\.colorScheme, .dark)
            } else {
                rendered
                BottomSoftening {
                    rendered
                }
            }
        }
        .mask {
            if let lens = scene.lensDiameter {
                Circle()
                    .frame(width: max(lens, 0), height: max(lens, 0))
                    .position(scene.lensCenter)
            } else {
                Rectangle()
            }
        }
        .opacity(scene.opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The object on its floor, ray marched. The scene's unit spans the
    /// canvas's shorter side, so a tall phone shows the object as a wide
    /// window does rather than filling its width.
    private var rendered: some View {
        Rectangle()
            .fill(Color.black)
            .colorEffect(ShaderLibrary.bundle(.module).welcomeScene(
                .float2(canvasSize),
                .float2(scene.cubeCenter),
                .float(min(canvasSize.width, canvasSize.height)),
                .float(Float(scene.look.shape)),
                .float3(scene.look.albedo.x, scene.look.albedo.y, scene.look.albedo.z),
                .float(scene.yaw),
                .float(scene.pitch),
                .float(scene.lift),
                .float(scene.level),
                .float(scene.sweep)
            ))
    }
}

struct BottomSoftening<Backdrop: View>: View {
    @ViewBuilder let backdrop: () -> Backdrop

    var body: some View {
        ZStack {
            backdrop()
                .blur(radius: 14, opaque: true)
                .mask(fade(from: 0.62, to: 0.86))
            backdrop()
                .blur(radius: 42, opaque: true)
                .mask(fade(from: 0.76, to: 1))
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.66),
                    .init(color: .black.opacity(0.38), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func fade(from start: CGFloat, to end: CGFloat) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .clear, location: start),
                .init(color: .black, location: end),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
