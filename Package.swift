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

let package = Package(
    name: "GlassIntroKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        .library(name: "GlassIntroKit", targets: ["GlassIntroKit"]),
    ],
    targets: [
        .target(
            name: "GlassIntroKit",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
        .testTarget(
            name: "GlassIntroKitTests",
            dependencies: ["GlassIntroKit"],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ]
        ),
    ]
)
