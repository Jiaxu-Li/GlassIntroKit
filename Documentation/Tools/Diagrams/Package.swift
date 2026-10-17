// swift-tools-version: 6.3

//===--- Package.swift - GlassIntroKit ---------------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import PackageDescription

/// Draws the documentation's diagrams into the DocC catalog's Resources:
///
///     swift run --package-path Documentation/Tools/Diagrams
let package = Package(
    name: "Diagrams",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Diagrams",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
    ]
)
