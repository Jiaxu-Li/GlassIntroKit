//===--- SymbolTracerTests.swift - GlassIntroKit ----------------------------===//
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
import SwiftUI
import Testing
@testable import GlassIntroKit

@Suite struct SymbolTracerTests {
    @Test func squareTracesToAUnitSquare() throws {
        let size = 32
        var values = [UInt8](repeating: 0, count: size * size)
        for y in 8..<24 {
            for x in 8..<24 {
                values[y * size + x] = 255
            }
        }
        let outline = try #require(SymbolTracer.outline(of: CoverageMask(width: size, height: size, values: values)))
        let bounds = outline.boundingRect
        #expect(abs(bounds.width - 1) < 0.01)
        #expect(abs(bounds.height - 1) < 0.01)
        #expect(abs(bounds.midX) < 0.01 && abs(bounds.midY) < 0.01)
        #expect(outline.contains(.zero))
    }

    @Test func emptyMaskHasNoOutline() {
        let mask = CoverageMask(width: 8, height: 8, values: [UInt8](repeating: 0, count: 64))
        #expect(SymbolTracer.outline(of: mask) == nil)
    }

    @Test func realSymbolsTraceToOutlines() async {
        let outlines = await SymbolOutlines.outlines(for: ["star.fill", "globe.americas.fill"])
        #expect(outlines.count == 2)
        for outline in outlines.values {
            #expect(!outline.isEmpty)
            #expect(outline.boundingRect.width <= 1.001 && outline.boundingRect.height <= 1.001)
        }
    }

    @Test func symbolMarkCutsItsSymbolOutOfTheBody() async throws {
        let outlines = await SymbolOutlines.outlines(for: ["star.fill"])
        let star = try #require(outlines["star.fill"])
        let mark = GlassIntroMarkOutline.symbol("star.fill")
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let plain = mark.path(in: rect, apertureOpening: 1, symbolOutline: nil)
        let cut = mark.path(in: rect, apertureOpening: 1, symbolOutline: star)
        #expect(plain.contains(CGPoint(x: 100, y: 100)))
        #expect(!cut.contains(CGPoint(x: 100, y: 100)))
        #expect(cut.contains(CGPoint(x: 100, y: 30)))
    }
}
