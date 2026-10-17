//===--- Storyboard.swift - GlassIntroKit -----------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//


import CoreGraphics
import Foundation

/// The pictures of the intro in order, side by side, from the framed
/// screenshots in `folder`.
func writeStoryboard(from folder: URL, to url: URL) throws {
    let names = ["launch", "greeting", "mark", "symbols", "scene", "graph", "physics", "icon", "ending", "app"]
    let screens = try names.map { try loadImage(folder.appendingPathComponent("screenshot-\($0).png")) }
    let tileWidth = 338, tileHeight = 691, gap = 28
    let width = names.count * tileWidth + (names.count - 1) * gap
    let context = makeContext(width: width, height: tileHeight)
    context.interpolationQuality = .high
    for (index, screen) in screens.enumerated() {
        context.draw(screen, in: CGRect(x: index * (tileWidth + gap), y: 0, width: tileWidth, height: tileHeight))
    }
    try writeImage(context.makeImage()!, to: url)
}
