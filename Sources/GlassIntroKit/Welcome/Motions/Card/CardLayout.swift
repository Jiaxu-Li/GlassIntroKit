//===--- CardLayout.swift - GlassIntroKit -----------------------------------===//
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

/// Where the card sits, and how large it is, in a canvas.
nonisolated struct CardLayout: Equatable, Sendable {
    /// The card's corner radius at rest.
    static let cornerRadius: CGFloat = 28
    /// The least clear space between the card and the top, or the page's text.
    static let margin: CGFloat = 24
    static let minimumHeight: CGFloat = 80

    /// The card at rest.
    let rect: CGRect

    /// The card centered across the canvas, and on the pictures' center as
    /// far as the top and the page's text leave room for it.
    init(canvas: IntroCanvas, textTop: CGFloat) {
        let width = min(canvas.size.width * 0.72, 520)
        let wanted = min(canvas.size.height * 0.4, 320)
        let room = textTop - Self.margin - Self.margin
        let height = max(min(wanted, room), Self.minimumHeight)
        let lowest = textTop - Self.margin - height
        let top = max(Self.margin, min(canvas.graphicCenter.y - height / 2, lowest))
        rect = CGRect(x: (canvas.size.width - width) / 2, y: top, width: width, height: height)
    }

    /// The card `progress` of the way from the seed's circle to its rest.
    /// Progress may overshoot 1 a little, as a spring does.
    func rect(from seed: GlassSeed, progress: Double) -> CGRect {
        let center = Ease.lerp(seed.center, CGPoint(x: rect.midX, y: rect.midY), progress)
        let width = max(Ease.lerp(seed.diameter, rect.width, progress), 0)
        let height = max(Ease.lerp(seed.diameter, rect.height, progress), 0)
        return CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }

    /// The corner radius of `rect`, `progress` of the way from the seed's
    /// full roundness to the card's own corners.
    func cornerRadius(of rect: CGRect, from seed: GlassSeed, progress: Double) -> CGFloat {
        let radius = Ease.lerp(seed.diameter / 2, Self.cornerRadius, progress)
        return max(min(radius, min(rect.width, rect.height) / 2), 0)
    }
}
