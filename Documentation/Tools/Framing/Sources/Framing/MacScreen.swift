//===--- MacScreen.swift - GlassIntroKit ------------------------------------===//
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

/// A Mac's screen with the app's window on it: a blue wallpaper, light at
/// the top and deep at the bottom, and the recorded window, centered, with
/// its rounded corners and shadow, as it looks when the app runs.
struct MacScreen {
    let size: CGSize
    /// The window's corner radius, in the recording's pixels.
    var cornerRadius: CGFloat = 30
    /// Pixels trimmed from each edge of the recording: a window capture
    /// catches a sliver of whatever is behind the window at its edges.
    var trim = 4

    func compose(window recorded: CGImage) -> CGImage {
        let window = recorded.cropping(to: CGRect(
            x: trim, y: trim, width: recorded.width - 2 * trim, height: recorded.height - 2 * trim
        )) ?? recorded
        let width = Int(size.width), height = Int(size.height)
        let context = makeContext(width: width, height: height, opaque: true)
        // Wallpaper: blue, from light at the top to deep at the bottom.
        let colors = [
            CGColor(srgbRed: 0.42, green: 0.68, blue: 0.98, alpha: 1),
            CGColor(srgbRed: 0.12, green: 0.36, blue: 0.82, alpha: 1),
            CGColor(srgbRed: 0.04, green: 0.13, blue: 0.42, alpha: 1),
        ] as CFArray
        let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: [0, 0.55, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: .zero, options: [])

        // The window, centered.
        let windowSize = CGSize(width: window.width, height: window.height)
        let origin = CGPoint(x: (size.width - windowSize.width) / 2, y: (size.height - windowSize.height) / 2)
        let frame = CGRect(origin: origin, size: windowSize)
        let outline = CGPath(roundedRect: frame, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -24), blur: 90, color: CGColor(gray: 0, alpha: 0.5))
        context.addPath(outline)
        context.setFillColor(CGColor(gray: 0.1, alpha: 1))
        context.fillPath()
        context.restoreGState()
        context.saveGState()
        context.addPath(outline)
        context.clip()
        context.draw(window, in: frame)
        context.restoreGState()
        return context.makeImage()!
    }
}
