//===--- IntroCanvas.swift - GlassIntroKit ----------------------------------===//
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

/// The welcome's geometry for one window size: where the pictures sit and
/// how large the mark is.
nonisolated struct IntroCanvas: Equatable, Sendable {
    /// Where the pictures sit, as a fraction of the height: above the
    /// center, clear of the text at the bottom.
    static let graphicHeight: CGFloat = 0.36

    let size: CGSize
    /// The mark's round body, as a fraction of the mark's square.
    let bodyDiameterRatio: CGFloat
    /// The highest top of any page's text, when it is known: pictures are
    /// centered in the room above it.
    let stageBottom: CGFloat?

    init(size: CGSize, bodyDiameterRatio: CGFloat, stageBottom: CGFloat? = nil) {
        self.size = CGSize(width: max(size.width, 1), height: max(size.height, 1))
        self.bodyDiameterRatio = bodyDiameterRatio
        self.stageBottom = stageBottom
    }

    var center: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }

    /// The center of every picture: midway between the top of the window,
    /// past the status bar or title bar, and the highest text, so a tall
    /// phone's picture is not crowded up against the top.
    var graphicCenter: CGPoint {
        guard let stageBottom else {
            return CGPoint(x: size.width / 2, y: size.height * Self.graphicHeight)
        }
        let top = min(max(size.height * 0.06, 24), 64)
        let middle = (top + stageBottom - 24) / 2
        return CGPoint(
            x: size.width / 2,
            y: min(max(middle, size.height * 0.3), size.height * 0.45)
        )
    }

    var isCompact: Bool {
        size.width < 640
    }

    /// The mark's square, as the launch leaves it.
    var markDimension: CGFloat {
        OpeningStage.markDimension(in: size)
    }

    /// The mark's body, as the closed stage sizes it.
    var bodyDiameter: CGFloat {
        markDimension * bodyDiameterRatio - 2
    }

    /// A circle wide enough that its rim has left every corner when it is
    /// centered on `point`.
    func coveringDiameter(around point: CGPoint) -> CGFloat {
        let reach = max(
            hypot(point.x, point.y),
            hypot(size.width - point.x, point.y),
            hypot(point.x, size.height - point.y),
            hypot(size.width - point.x, size.height - point.y)
        )
        return reach * 2 + 80
    }

    /// The droplet every picture gathers into before the next grows out of
    /// it: the mark's body, in glass, at the pictures' center.
    var seed: GlassSeed {
        GlassSeed(center: graphicCenter, diameter: bodyDiameter)
    }
}

/// A round drop of glass: where one picture ends and the next begins
/// when they have nothing else in common.
nonisolated struct GlassSeed: Equatable, Sendable {
    static let pieceID = "seed"

    var center: CGPoint
    var diameter: CGFloat

    var rect: CGRect {
        CGRect(
            x: center.x - diameter / 2,
            y: center.y - diameter / 2,
            width: diameter,
            height: diameter
        )
    }

    /// The drop at `scale` of its size, as a piece of glass.
    func piece(scale: CGFloat = 1) -> GlassPiece {
        let side = diameter * max(scale, 0)
        return GlassPiece(
            id: Self.pieceID,
            path: Path(ellipseIn: CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side))
        )
    }
}
