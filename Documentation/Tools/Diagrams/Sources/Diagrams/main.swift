//===--- main.swift - GlassIntroKit -----------------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import AppKit
import SwiftUI

/// Draws each slide at twice its size into the DocC catalog: as PNG,
/// or as JPEG for a slide with screenshots on it, which would be large.
func render(_ view: some View, named name: String, photographic: Bool = false) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    let type: NSBitmapImageRep.FileType = photographic ? .jpeg : .png
    let properties: [NSBitmapImageRep.PropertyKey: Any] = photographic ? [.compressionFactor: 0.82] : [:]
    guard let image = renderer.cgImage,
          let data = NSBitmapImageRep(cgImage: image).representation(using: type, properties: properties) else {
        throw CocoaError(.fileWriteUnknown)
    }
    let file = Images.folder.appendingPathComponent("\(name).\(photographic ? "jpg" : "png")")
    try data.write(to: file)
    print("Wrote \(file.lastPathComponent), \(image.width)×\(image.height)")
}

try render(LayersSlide(), named: "diagram-layers")
try render(FlowSlide(), named: "diagram-flow")
try render(TransitionsSlide(), named: "diagram-transitions")
try render(ConfigurationSlide(), named: "diagram-configuration")
try render(PipelineSlide(), named: "diagram-pipeline")
try render(AnatomySlide(), named: "diagram-anatomy", photographic: true)
try render(StorySlide(), named: "diagram-story", photographic: true)
try render(EndingSlide(), named: "diagram-ending", photographic: true)
