//===--- IntroFrame+Seed.swift - GlassIntroKit ------------------------------===//
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

/// How any picture gathers into the seed, and how the seed gives way to
/// the next. These two movements join every pair of pages that have no
/// movement of their own between them, so any page can follow any other.
nonisolated extension IntroFrame {
    /// How long a picture takes to gather into the seed.
    static let collapseDuration = 0.9
    /// How long the seed takes to shrink away beneath the next picture.
    static let seedDecayDuration = 0.55

    /// This frame gathered `progress` of the way into `seed`: every piece
    /// travels to the seed's center and shrinks as the seed swells, so the
    /// shared glass flows together like liquid; everything else fades on
    /// the way. At 1 only the seed is left.
    func collapsed(into seed: GlassSeed, progress: Double, canvas: IntroCanvas) -> IntroFrame {
        let p = Ease.clamp(progress)
        guard p < 1 else {
            return .seed(seed)
        }
        let travel = Ease.smoother(p)
        let shrink = 1 - travel

        var result = IntroFrame()
        result.glass = glass.compactMap { piece in
            Self.gathered(piece, toward: seed.center, travel: travel, scale: shrink)
        }
        result.glass.append(seed.piece(scale: CGFloat(Ease.smoother((p - 0.1) / 0.9))))
        let looseFade = 1 - Ease.smoother((p - 0.55) / 0.45)
        result.looseGlass = looseGlass.compactMap { piece in
            var gathered = Self.gathered(piece, toward: seed.center, travel: travel, scale: shrink)
            gathered?.opacity *= looseFade
            return gathered
        }
        // Glass a picture had hidden returns as it gathers.
        result.glassOpacity = Ease.lerp(glassOpacity, 1, travel)

        let spriteFade = 1 - Ease.smoother(p / 0.5)
        result.symbols = symbols.map { symbol in
            var symbol = symbol
            symbol.center = Ease.lerp(symbol.center, seed.center, travel)
            symbol.scale *= shrink
            symbol.opacity *= spriteFade
            return symbol
        }
        result.lines = lines.map { line in
            var line = line
            line.width *= shrink
            return line
        }
        result.particles = particles.map { particle in
            var particle = particle
            particle.opacity *= 1 - Ease.smoother(p / 0.4)
            return particle
        }
        if var scene {
            // The lens closes over the scene down to the seed.
            let from = scene.lensDiameter ?? canvas.coveringDiameter(around: scene.lensCenter)
            scene.lensDiameter = Ease.lerp(from, seed.diameter * 0.97, travel)
            scene.lensCenter = Ease.lerp(scene.lensCenter, seed.center, travel)
            scene.opacity *= 1 - Ease.smoother((p - 0.55) / 0.45)
            result.scene = scene
        }
        if var mark {
            mark.center = Ease.lerp(mark.center, seed.center, travel)
            mark.opacity *= 1 - Ease.smoother(p / 0.6)
            result.mark = mark
        }
        if var card {
            card.contentOpacity *= 1 - Ease.smoother(p / 0.35)
            card.contentScale *= shrink
            card.rect = Self.scaled(card.rect, toward: seed.center, travel: travel, scale: shrink)
            result.card = card
        }
        return result
    }

    /// This frame letting go where it is, `progress` of the way, as the
    /// original's icon lets go before the last page: every piece of glass
    /// draws in on itself to nothing, and everything else fades with it. At
    /// 1 nothing is left.
    func dissolved(progress: Double) -> IntroFrame {
        let p = Ease.clamp(progress)
        guard p < 1 else {
            return IntroFrame()
        }
        let gone = Ease.smoother(p)
        let fade = 1 - gone
        let shrink = 1 - gone
        var result = self
        func drawnIn(_ piece: GlassPiece) -> GlassPiece {
            var piece = piece
            let bounds = piece.path.boundingRect
            if !bounds.isNull, bounds.width.isFinite, bounds.height.isFinite {
                piece.path = piece.path.applying(
                    CGAffineTransform(translationX: bounds.midX, y: bounds.midY)
                        .scaledBy(x: shrink, y: shrink)
                        .translatedBy(x: -bounds.midX, y: -bounds.midY)
                )
            }
            return piece
        }
        result.glass = glass.map(drawnIn)
        result.looseGlass = looseGlass.map(drawnIn)
        result.symbols = symbols.map { symbol in
            var symbol = symbol
            symbol.scale *= shrink
            symbol.opacity *= fade
            return symbol
        }
        result.lines = lines.map { line in
            var line = line
            line.opacity *= fade
            return line
        }
        result.particles = particles.map { particle in
            var particle = particle
            particle.opacity *= fade
            return particle
        }
        result.sheens = []
        result.scene?.opacity *= fade
        result.mark?.opacity *= fade
        if var card {
            card.contentOpacity *= fade
            card.contentScale *= shrink
            result.card = card
        }
        return result
    }

    /// This frame with the seed it grew out of shrinking away beneath it,
    /// `elapsed` seconds after it began.
    func withDecayingSeed(_ seed: GlassSeed, elapsed: Double) -> IntroFrame {
        let remaining = 1 - Ease.smoother(elapsed / Self.seedDecayDuration)
        guard remaining > 0.001 else {
            return self
        }
        var result = self
        result.glass.insert(seed.piece(scale: CGFloat(remaining)), at: 0)
        return result
    }

    private static func gathered(
        _ piece: GlassPiece,
        toward center: CGPoint,
        travel: Double,
        scale: Double
    ) -> GlassPiece? {
        let bounds = piece.path.boundingRect
        guard scale > 0.02, !bounds.isNull, bounds.width.isFinite, bounds.height.isFinite else {
            return nil
        }
        let from = CGPoint(x: bounds.midX, y: bounds.midY)
        let to = Ease.lerp(from, center, travel)
        var piece = piece
        piece.path = piece.path.applying(
            CGAffineTransform(translationX: to.x, y: to.y)
                .scaledBy(x: scale, y: scale)
                .translatedBy(x: -from.x, y: -from.y)
        )
        return piece
    }

    private static func scaled(_ rect: CGRect, toward center: CGPoint, travel: Double, scale: Double) -> CGRect {
        let to = Ease.lerp(CGPoint(x: rect.midX, y: rect.midY), center, travel)
        let width = rect.width * scale
        let height = rect.height * scale
        return CGRect(x: to.x - width / 2, y: to.y - height / 2, width: width, height: height)
    }
}
