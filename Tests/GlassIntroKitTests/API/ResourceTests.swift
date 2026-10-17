//===--- ResourceTests.swift - GlassIntroKit --------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import Metal
import Testing
@testable import GlassIntroKit

@Suite struct ResourceTests {
    @Test func sceneShaderIsPackaged() throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let library = try device.makeDefaultLibrary(bundle: Bundle.module)
        #expect(library.functionNames.contains("welcomeScene"))
    }

    @Test func builtInTextIsPackaged() {
        #expect(Bundle.module.localizedString(forKey: "Get Started", value: nil, table: nil) == "Get Started")
        let pageLabel = Bundle.module.localizedString(forKey: "Page %lld of %lld", value: nil, table: nil)
        #expect(String(format: pageLabel, 2, 8) == "Page 2 of 8")
    }
}
