//===--- StandardMarkTests.swift - GlassIntroKit ----------------------------===//
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
import Testing
@testable import GlassIntroKit

/// The kit's own mark: a pearl with its yellow light high
/// on the left rather than the right, in colour and in glass.
@Suite @MainActor struct StandardMarkTests {
    /// The bounds of the yellow light and of the white pearl in the mark
    /// drawn `side` points square, in pixels from the top left.
    private func drawnBounds(side: Int) throws -> (light: CGRect, pearl: CGRect) {
        let renderer = ImageRenderer(content: GlassIntroMarkView(.standard)
            .frame(width: CGFloat(side), height: CGFloat(side))
            .background(Color.black))
        renderer.scale = 1
        let image = try #require(renderer.cgImage)
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try #require(CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var light = CGRect.null
        var pearl = CGRect.null
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                let (r, g, b) = (Int(pixels[i]), Int(pixels[i + 1]), Int(pixels[i + 2]))
                let pixel = CGRect(x: x, y: y, width: 1, height: 1)
                if r > 200, g > 150, b < 140 {
                    light = light.union(pixel)
                }
                if r > 150, g > 150 {
                    pearl = pearl.union(pixel)
                }
            }
        }
        return (light, pearl)
    }

    @Test func theLightSitsHighOnTheLeftOfACenteredPearl() throws {
        let side = 240
        let (light, pearl) = try drawnBounds(side: side)
        let center = CGFloat(side) / 2
        // The pearl is centered in the frame.
        #expect(abs(pearl.midX - center) <= 2 && abs(pearl.midY - center) <= 2, "pearl \(pearl)")
        // The light is up and to the left, as far as the original pearl's is up
        // and to the right.
        let offset = CGFloat(side) * StandardMark.lightOffset
        #expect(abs(light.midX - (center - offset)) <= 4, "light \(light)")
        #expect(abs(light.midY - (center - offset)) <= 4, "light \(light)")
        #expect(light.maxX < center + 10)
    }

    @Test func theGlassOutlineCutsTheLightOutHighOnTheLeft() {
        let rect = CGRect(x: 10, y: 20, width: 200, height: 200)
        let outline = GlassIntroMark.standard.outline.path(in: rect, apertureOpening: 1, symbolOutline: nil)
        let offset = 200 * StandardMark.lightOffset
        let lightCenter = CGPoint(x: rect.midX - offset, y: rect.midY - offset)
        let mirrored = CGPoint(x: rect.midX + offset, y: rect.midY - offset)
        #expect(!outline.contains(lightCenter))
        #expect(outline.contains(mirrored))
        #expect(outline.contains(CGPoint(x: rect.midX, y: rect.midY + offset)))
        // The aperture is the mirror image of the original's: left to
        // right, it reaches as far as that one does right to left.
        let aperture = LightApertureShape().path(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        let bounds = aperture.boundingRect
        #expect(abs(bounds.midY - 50) < 8)
        // Closed, it is the plain pearl.
        let closed = GlassIntroMark.standard.outline.path(in: rect, apertureOpening: 0, symbolOutline: nil)
        #expect(closed.contains(lightCenter))
    }
}
