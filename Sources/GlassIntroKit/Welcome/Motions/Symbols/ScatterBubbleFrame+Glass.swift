//===--- ScatterBubbleFrame+Glass.swift - GlassIntroKit ---------------------===//
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

nonisolated extension ScatterBubbleFrame {
    /// The bubble as a piece of glass in the shape of its symbol, placed on
    /// the canvas. Until the symbol is traced it is a small circle.
    func glassPiece(outline: Path?) -> GlassPiece {
        let rect = CGRect(
            x: center.x - diameter / 2,
            y: center.y - diameter / 2,
            width: diameter,
            height: diameter
        )
        return GlassPiece(
            id: "bubble.\(id)",
            path: SymbolGlassShape(outline: outline).path(in: rect),
            blur: blur
        )
    }
}
