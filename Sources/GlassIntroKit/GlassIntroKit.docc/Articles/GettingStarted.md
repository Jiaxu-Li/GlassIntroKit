# Getting Started

Add the package, give your root view an intro, and see it play.

## Overview

GlassIntroKit needs iOS 26 or macOS 26 or later, and Swift 6.3 or later. It is built and tested with Xcode 27 and Swift 6.4.

| | |
|---|---|
| Platforms | iOS 26+, macOS 26+ |
| Swift | 6.3+ (Swift 6 language mode) |
| Built-in text | English |
| License | Apache 2.0 |

### Add the package

In Xcode, choose **File › Add Package Dependencies…** and enter the repository URL, or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Jiaxu-Li/GlassIntroKit.git", from: "0.2.0"),
],
targets: [
    .target(name: "MyApp", dependencies: ["GlassIntroKit"]),
]
```

### Add an intro

Give the root view of your window the ``SwiftUICore/View/glassIntro(appName:mark:pages:finale:)`` modifier:

```swift
import GlassIntroKit
import SwiftUI

@main
struct OrbitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .glassIntro(
                    appName: "Orbit",
                    pages: [
                        .greeting("Welcome to Orbit", message: "Plan trips with the people you travel with."),
                        .mark("Simple, by Design", message: "One calm place for every plan."),
                        .symbols("Everything in Reach", message: "Maps, photos, and notes gather around each trip."),
                    ]
                )
        }
    }
}
```

Run the app. The launch plays once per process, in the first window that shows it, and the welcome plays on the first launch.

![The intro from launch to app: GlassIntro starts the launch, the welcome, and the ending, which lead to the mark on frosted glass, your pages, the words and the mark in colour, and finally your app.](diagram-flow.png)

Page titles and messages are `LocalizedStringKey`s, so they are localized from your app's string catalog like any other text.

### Try every option

The demo app in `Examples/GlassIntroDemo` opens on a settings screen where you can try every option without writing code, and it writes out the code for the intro you have set up.

![The demo app's settings screen.](screenshot-settings.png)

## See Also

- <doc:ChoosingPages>
- <doc:/tutorials/Tutorials>
