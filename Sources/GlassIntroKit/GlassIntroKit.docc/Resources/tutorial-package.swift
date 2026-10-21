// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Orbit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/Jiaxu-Li/GlassIntroKit.git", from: "0.2.0"),
    ],
    targets: [
        .executableTarget(name: "Orbit", dependencies: ["GlassIntroKit"]),
    ]
)
