//===--- IntroFrameView.swift - GlassIntroKit -------------------------------===//
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

/// Draws one frame of the welcome. Every picture is drawn here; pictures
/// only describe themselves.
struct IntroFrameView: View {
    let frame: IntroFrame
    let canvasSize: CGSize
    let content: WelcomeContent

    var body: some View {
        ZStack {
            if let scene = frame.scene {
                SceneLayer(scene: scene, canvasSize: canvasSize, content: content)
            }
            // One container, so glass close together flows into one piece
            // and pulls apart like liquid.
            GlassEffectContainer(spacing: 44) {
                ZStack {
                    ForEach(frame.glass) { piece in
                        GlassPieceView(piece: piece, canvasSize: canvasSize)
                    }
                }
            }
            .opacity(frame.glassOpacity)
            ForEach(frame.looseGlass) { piece in
                GlassPieceView(piece: piece, canvasSize: canvasSize)
            }
            ForEach(frame.lines) { line in
                Capsule()
                    .fill(Color.white.opacity(line.opacity))
                    .frame(width: max(line.width, 0), height: line.thickness)
                    .position(line.center)
            }
            ForEach(frame.symbols) { symbol in
                Image(systemName: symbol.name)
                    .font(.system(size: max(symbol.size, 1), weight: symbol.weight))
                    .foregroundStyle(Color.white)
                    .rotationEffect(.radians(symbol.angle))
                    .scaleEffect(max(symbol.scale, 0.001))
                    .opacity(symbol.opacity)
                    .position(symbol.center)
            }
            ForEach(frame.sheens) { sheen in
                SheenView(sheen: sheen)
            }
            if !frame.particles.isEmpty {
                ParticleLayer(particles: frame.particles)
            }
            if let card = frame.card, card.page < content.pages.count,
               let cardContent = content.pages[card.page].customContent {
                cardContent()
                    .frame(width: max(card.rect.width, 1), height: max(card.rect.height, 1))
                    .scaleEffect(max(card.contentScale, 0.001))
                    .opacity(card.contentOpacity)
                    .position(x: card.rect.midX, y: card.rect.midY)
                    .environment(\.colorScheme, .dark)
            }
            if let mark = frame.mark {
                MarkSpriteView(sprite: mark, mark: content.mark, canvas: IntroCanvas(
                    size: canvasSize,
                    bodyDiameterRatio: content.mark.bodyDiameterRatio
                ))
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .accessibilityHidden(true)
    }
}

/// One piece of glass, its outline placed on the canvas.
private struct GlassPieceView: View {
    let piece: GlassPiece
    let canvasSize: CGSize

    var body: some View {
        Color.clear
            .frame(width: canvasSize.width, height: canvasSize.height)
            .glassEffect(
                piece.tint > 0 ? .clear.tint(.white.opacity(piece.tint)) : .clear,
                in: PlacedPath(path: piece.path)
            )
            .blur(radius: piece.blur)
            .opacity(piece.opacity)
    }
}

/// An outline already placed on the canvas, as a shape.
nonisolated struct PlacedPath: Shape {
    let path: Path

    func path(in rect: CGRect) -> Path {
        path
    }
}

/// A soft diagonal band of light crossing a rounded square once.
private struct SheenView: View {
    let sheen: SheenSprite

    var body: some View {
        let side = sheen.rect.width
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .white.opacity(0.4), location: 0.5),
                .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: side * 0.45, height: side * 2)
        .rotationEffect(.degrees(20))
        .offset(x: side * CGFloat(-1 + 2 * sheen.progress))
        .frame(width: side, height: sheen.rect.height)
        .clipShape(RoundedRectangle(cornerRadius: sheen.cornerRadius, style: .continuous))
        .blendMode(.plusLighter)
        .position(x: sheen.rect.midX, y: sheen.rect.midY)
    }
}

/// Grains of warm dust.
private struct ParticleLayer: View {
    let particles: [ParticleSprite]

    var body: some View {
        Canvas { context, _ in
            for particle in particles {
                let radius = particle.diameter / 2
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: particle.center.x - radius,
                        y: particle.center.y - radius,
                        width: particle.diameter,
                        height: particle.diameter
                    )),
                    with: .color(Color(red: 1, green: 0.9, blue: 0.78).opacity(particle.opacity))
                )
            }
        }
        .allowsHitTesting(false)
    }
}
