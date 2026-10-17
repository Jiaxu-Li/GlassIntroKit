//===--- IconMotion+Frame.swift - GlassIntroKit -----------------------------===//
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

/// The icon page's movement as the render list the welcome draws.
nonisolated extension IntroFrame {
    /// The icon page in `icon`, showing `symbols`: the icon's symbol, then
    /// its badge's.
    ///
    /// The gathering nodes, the icon, and its badge are pieces of the shared
    /// glass, so they flow into one another like liquid.
    init(icon: IconFrame, symbols names: [String]) {
        let iconSymbol = names.first ?? "shippingbox.fill"
        let badgeSymbol = names.dropFirst().first ?? "checkmark"
        self.init()

        if icon.platformWidth > 0.01 {
            lines.append(LineSprite(id: "platform", center: icon.platformCenter, width: icon.platformWidth))
        }
        for tile in icon.tiles {
            glass.append(GlassPiece(
                id: "tile.\(tile.id)",
                path: TurnedTile.path(
                    size: tile.size,
                    cornerRadius: tile.cornerRadius,
                    angle: tile.angle,
                    center: tile.center
                )
            ))
            symbols.append(SymbolSprite(
                id: "tile.\(tile.id).symbol",
                name: tile.symbol,
                center: tile.center,
                size: max(tile.symbolSize, 1),
                angle: tile.angle,
                opacity: tile.symbolOpacity
            ))
        }

        if icon.iconSide > 0.01 {
            let side = icon.iconSide
            let rect = CGRect(
                x: icon.iconCenter.x - side / 2,
                y: icon.iconCenter.y - side / 2,
                width: side,
                height: side
            )
            let corner = icon.iconCorner
            // Exactly a circle until the icon starts to take its shape, so
            // it can stand in for the seed.
            let outline = corner >= side / 2
                ? Path(ellipseIn: rect)
                : Path(roundedRect: rect, cornerRadius: corner, style: .continuous)
            glass.append(GlassPiece(id: "icon", path: outline))
            if icon.iconSymbolOpacity > 0.001 {
                symbols.append(SymbolSprite(
                    id: "icon.symbol",
                    name: iconSymbol,
                    center: icon.iconCenter,
                    size: side * 0.4,
                    scale: icon.iconSymbolScale,
                    opacity: icon.iconSymbolOpacity
                ))
            }
            if let progress = icon.sheen {
                sheens.append(SheenSprite(id: "icon.sheen", rect: rect, cornerRadius: corner, progress: progress))
            }
        }

        if icon.badgeDiameter > 0.01 {
            let radius = icon.badgeDiameter / 2
            glass.append(GlassPiece(id: "badge", path: Path(ellipseIn: CGRect(
                x: icon.badgeCenter.x - radius,
                y: icon.badgeCenter.y - radius,
                width: icon.badgeDiameter,
                height: icon.badgeDiameter
            ))))
            if icon.badgeSymbolOpacity > 0.001 {
                symbols.append(SymbolSprite(
                    id: "badge.symbol",
                    name: badgeSymbol,
                    center: icon.badgeCenter,
                    size: max(icon.badgeDiameter * 0.42, 1),
                    weight: .bold,
                    opacity: icon.badgeSymbolOpacity
                ))
            }
        }
    }
}
