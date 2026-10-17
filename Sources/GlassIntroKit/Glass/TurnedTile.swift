//===--- TurnedTile.swift - GlassIntroKit -----------------------------------===//
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

/// A rounded tile turned about its center: the outline glass follows as a
/// node falls, tumbles, and is gathered back up.
nonisolated enum TurnedTile {
    static func path(size: CGSize, cornerRadius: CGFloat, angle: Double, center: CGPoint) -> Path {
        Path(
            roundedRect: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ),
            cornerRadius: cornerRadius,
            style: .continuous
        )
        .applying(
            CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: angle)
        )
    }
}
