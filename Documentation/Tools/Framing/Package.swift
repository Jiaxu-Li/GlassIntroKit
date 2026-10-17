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

/// Puts the documentation's screenshots and recordings in Apple product
/// bezels. The bezels are not part of this repository: download them from
/// developer.apple.com/design/resources, under Apple's license, and pass
/// their folder. See README.md beside this file.
let package = Package(
    name: "Framing",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "Framing"),
    ]
)
