<div align="center">

<img src="Sources/GlassIntroKit/GlassIntroKit.docc/Resources/icon.png" width="128" alt="GlassIntroKit icon: a waving hand in glass on a blue grid.">

<h1>GlassIntroKit</h1>

<p>A first-launch intro for SwiftUI apps, made with Liquid Glass and Metal.</p>

<p>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.3%2B-F05138?logo=swift&logoColor=white" alt="Swift 6.3+"></a>
  <a href="#requirements"><img src="https://img.shields.io/badge/iOS-26%2B-0A84FF?logo=apple&logoColor=white" alt="iOS 26+"></a>
  <a href="#requirements"><img src="https://img.shields.io/badge/macOS-26%2B-0A84FF?logo=apple&logoColor=white" alt="macOS 26+"></a>
  <a href="#installation"><img src="https://img.shields.io/badge/SwiftPM-compatible-34C759" alt="SwiftPM"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue" alt="License: Apache 2.0"></a>
  <a href="CHANGELOG.md"><img src="https://img.shields.io/badge/version-0.1.0-5E5CE6" alt="Version 0.1.0"></a>
</p>

</div>

---

<p align="center">
  <img src="Sources/GlassIntroKit/GlassIntroKit.docc/Resources/intro-preview.gif" width="760" alt="The intro playing on a MacBook Pro and an iPhone side by side: the mark on frosted glass, hello written in glass over a forest, and one picture after another, ending in the app.">
</p>

The launch opens on your mark on frosted glass. On the first launch a welcome follows: the mark writes "hello" in glass, then turns, page by page, into the pictures your app's story needs. At the end a few words turn in, the mark fills with colour, and it dissolves over your app. The same intro runs on macOS and iOS. [Watch the full recording](Sources/GlassIntroKit/GlassIntroKit.docc/Resources/intro.mp4).

![Five screens of the intro: the mark on frosted glass, hello written in glass, the mark in glass, symbols scattered around it, and a lit cube seen through a lens.](Sources/GlassIntroKit/GlassIntroKit.docc/Resources/diagram-story.jpg)

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [How an intro plays](#how-an-intro-plays)
- [Pages](#pages)
- [The ending and the mark](#the-ending-and-the-mark)
- [Playing the intro](#playing-the-intro)
- [All options](#all-options)
- [Accessibility, localization, and privacy](#accessibility-localization-and-privacy)
- [Demo app](#demo-app)
- [Documentation](#documentation)
- [Building and testing](#building-and-testing)
- [FAQ](#faq)
- [Contributing](#contributing)
- [Author](#author)
- [License](#license)

## Features

- **One modifier.** `.glassIntro(appName:pages:)` on your root view, and the intro plays over it.
- **Eight pictures, any order.** A greeting, the mark, scattered symbols, a live Metal scene, a graph, falling nodes, an app icon, and cards with your own views. Every pair joins without a jump.
- **Yours to shape.** Graphs of your own nodes and wires, scenes in your shape, colour, and motion, a RealityKit or SwiftUI view through the lens, backgrounds, buttons, and the words of the ending.
- **Tested frame by frame.** The tests play every page after every other page and fail on any frame that jumps.
- **Accessible.** Reduce Motion, keyboard, and VoiceOver support.
- **No dependencies, no network.** It stores one Boolean to remember that the welcome was shown.

## Requirements

| | |
|---|---|
| Version | 0.1.0 |
| Platforms | iOS 26 or later, macOS 26 or later |
| Swift | 6.3 or later, Swift 6 language mode |
| Tested with | Xcode 27, Swift 6.4 |
| Built-in text | English |
| Dependencies | None |
| License | Apache 2.0 |

## Installation

### Xcode

Choose **File › Add Package Dependencies…**, enter `https://github.com/Jiaxu-Li/GlassIntroKit.git`, and add **GlassIntroKit** to your app target.

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Jiaxu-Li/GlassIntroKit.git", from: "0.1.0"),
],
targets: [
    .target(name: "MyApp", dependencies: ["GlassIntroKit"]),
]
```

## Quick start

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
                        .symbols("Everything in Reach", message: "Maps, photos, and notes gather around each trip."),
                        .icon("Ready When You Are", message: "Packed and ready to go."),
                    ]
                )
        }
    }
}
```

Run the app. The launch plays once per process, in the first window that shows it, and the welcome plays on the first launch. While you work on it, set `welcome: .everyLaunch` to see it at every launch (see [Playing the intro](#playing-the-intro)).

## How an intro plays

![GlassIntro starts the launch, the welcome, and the ending; they show the mark on frosted glass, your pages one at a time, and the words then the mark in colour, before the mark dissolves over your app.](Sources/GlassIntroKit/GlassIntroKit.docc/Resources/diagram-flow.png)

1. **Launch.** Your mark comes up on frosted glass over the app.
2. **Welcome.** Your pages, one at a time. Each has a picture, a title, a message, and **Continue**.
3. **Last page.** "Let's Begin" and **Get Started**, in your words if you like.
4. **Ending.** Up to three lines of glass words, then the mark fills with colour.
5. **Your app.** The mark dissolves where it is, and the app is yours.

## Pages

![A page on screen: the background behind the picture, the picture, the page indicator, the title and message, and the Continue button.](Sources/GlassIntroKit/GlassIntroKit.docc/Resources/diagram-anatomy.jpg)

### The eight pictures

| Page | Picture | Options |
|---|---|---|
| `.greeting(_:message:)` | The mark gathers into a pen and writes "hello" in glass. | |
| `.mark(_:message:)` | The mark in glass, its detail opening. | |
| `.symbols(_:message:symbols:center:)` | The mark melts into a symbol, and glass symbols scatter out of it. | the symbols, and the symbol the mark melts into |
| `.scene(_:message:scene:)` | A glass lens opens over a live, ray-marched Metal scene, turned by dragging. | shape, colour, motion — or a view of your own |
| `.graph(_:message:graph:)` | A wire shoots out of a glass point, and a graph grows, column by column. | any nodes and links |
| `.physics(_:message:nodes:)` | Up to eight nodes fall onto a line under rigid-body physics. | the nodes |
| `.icon(_:message:symbol:badge:)` | Glass gathers into an app icon, which is polished and badged. | the icon's symbol and badge |
| `.card(_:message:content:)` | Your own SwiftUI view, on a card of glass. | any view |

![Every picture in turn: the launch, the greeting, the mark, the symbols, the scene, the graph, the falling nodes, the icon, the ending, and the app.](Sources/GlassIntroKit/GlassIntroKit.docc/Resources/storyboard.png)

### How pages connect

Pages come in any order, as often as you like, and a welcome can be a single page. Pictures made to follow one another — greeting, mark, symbols, scene, graph, physics, icon — carry straight on, the same glass continuing from one to the next. Any other two meet in a drop of glass: one gathers into it, and the next grows out of it. Before the last page, the picture lets go where it is.

![Carrying straight on, meeting in a drop of glass, and letting go before the last page.](Sources/GlassIntroKit/GlassIntroKit.docc/Resources/diagram-transitions.png)

### Symbols

```swift
.symbols(
    "Everything in Reach",
    message: "Maps, photos, and notes.",
    symbols: ["map.fill", "airplane", "photo.fill", "music.note", "camera.fill", "fork.knife"],
    center: "leaf.fill"   // by default, the mark's own symbol
)
```

### Graphs

Any nodes, wired any way. Nodes are laid out left to right, each one column past the furthest node wired into it, and the graph is scaled to fit the window.

```swift
.graph("Connected", message: "…", nodes: ["calendar", "person.2.fill", "creditcard.fill"])   // the first branches to the rest
.graph("Pipeline", message: "…", graph: .chain(["tray.fill", "gearshape.fill", "paperplane.fill"]))
.graph("Trip", message: "…", graph: .branch("airplane.departure", into: ["bed.double.fill", "fork.knife", "camera.fill"]))
.graph("Plans", message: "…", graph: .diamond("lightbulb.fill", through: ["pencil", "paintpalette.fill"], into: "sparkles"))
.graph("Yours", message: "…", graph: GlassIntroGraph(
    nodes: ["envelope.fill", "calendar", "checklist", "bell.fill"],
    links: [.init(0, 2), .init(1, 2), .init(2, 3)]
))
```

Links run from an earlier node to a later one; a link that runs backward, repeats, or names a missing node is left out. A graph shows up to eight nodes.

### Physics

```swift
.physics("Feels Real", message: "…", nodes: ["calendar", "envelope.fill", "bell.fill", "cart.fill"])
```

Up to eight nodes fall, and every one comes to rest face up on the line. Right after a graph, the graph's own nodes fall instead.

### Scenes

The scene renders an object on a studio floor:

```swift
.scene("Seen in Depth", message: "…", scene: GlassIntroScene(
    shape: .ring,            // .cube, .sphere, .ring, .capsule, .cylinder
    color: .orange,
    motion: .float,          // .turntable, .turntable(speed:), .tumble, .float, .still
    revealsRendering: false, // open fully lit, rather than raised level by level
    isDraggable: true        // turn it by dragging
))
```

Or show a view of your own — a `RealityView`, a video, any SwiftUI view — through the same lens. It is laid out across the window and is not interactive:

```swift
.scene("Your World", message: "…") {
    MyRealityView()
}
```

### Icons

```swift
.icon("Ready When You Are", message: "…", symbol: "suitcase.rolling.fill", badge: "checkmark")
```

### Cards

```swift
.card("Your Itinerary", message: "Any view can be a page.") {
    ItineraryCard()   // laid out in the card; use white or light content
}
```

### Backgrounds and buttons

Every page can have its own background — the picture's own light, a colour, or an image — and its own button:

```swift
.greeting("Welcome to Orbit", message: "…")
    .background(.image(Image("Forest")))   // .automatic, .color(_:), or .image(_:)
    .continueButton(Text("Let's Go"))
```

## The ending and the mark

![The last page, a word of the ending in glass, the mark in colour, and the app.](Sources/GlassIntroKit/GlassIntroKit.docc/Resources/diagram-ending.jpg)

### The words

The last page asks to begin. Its button plays the ending: the words of `finale` turn in one after another in glass, the mark forms at the center and fills with colour, and it dissolves over your app.

```swift
GlassIntro(appName: "Orbit", pages: pages)                                // "Welcome", "to", "Orbit"
GlassIntro(appName: "Orbit", pages: pages, finale: ["Have a", "good trip"])
GlassIntro(appName: "Orbit", pages: pages, finale: [])                    // straight to the mark
```

Up to three lines are shown; the last is the line's subject and comes in from below.

### The buttons

```swift
GlassIntro(
    appName: "Orbit",
    pages: pages,
    startTitle: Text("Off You Go"),        // "Let's Begin"
    startButton: Text("Start Exploring"),  // "Get Started"
    continueButton: Text("Next")           // "Continue", on every page without its own
)
```

### The mark

| Mark | What it is |
|---|---|
| `.standard` (default) | A white pearl with a yellow light set into it, high on its left. |
| `.symbol(_:color:)` | An SF Symbol, in your colour, on a white body. |
| `.custom(bodyDiameterRatio:bodyColor:light:outline:view:)` | Artwork of your own. |

In glass, the mark's detail is cut out of its body. A custom mark gives its view in colour and its outline for glass — the round body with the detail cut out, opening from the plain body at 0 to the full detail at 1:

```swift
.custom(outline: { rect, opening in myMarkOutline(in: rect, opening: opening) }) {
    MyMarkView()
}

// The outline is drawn off the main actor, from `rect` and `opening` alone.
nonisolated func myMarkOutline(in rect: CGRect, opening: CGFloat) -> Path {
    // The body, with the detail cut out of it, scaled by `opening`.
}
```

To show the mark in your own views, such as an about screen, use `GlassIntroMarkView(mark)`.

## Playing the intro

### When the welcome plays

| `welcome` | The welcome plays |
|---|---|
| `.firstLaunchOnly` (default) | once; recorded in `storage` when it is shown or skipped |
| `.everyLaunch` | at every launch |
| `.never` | never; only the launch plays |

`GlassIntro.resetWelcome()` makes it play on the next launch. Give `storage` a key of your own — for example, to show a new welcome with a new version of your app:

```swift
GlassIntro(appName: "Orbit", pages: pages, storage: GlassIntroStorage(key: "Orbit.welcome.2"))
```

### Playing it again

`.glassIntro(_:isPresented:)` plays the intro whenever its binding becomes true, welcome included unless the schedule is `.never`, and sets the binding back to false when it ends:

```swift
struct ContentView: View {
    @State private var showsIntro = false

    var body: some View {
        Button("Show the Intro") { showsIntro = true }
            .glassIntro(Self.intro, isPresented: $showsIntro)
    }

    static let intro = GlassIntro(appName: "Orbit", pages: [
        .greeting("Welcome to Orbit", message: "Plan trips together."),
    ])
}
```

### How the launch opens

By default the launch opens straight on the mark. `opening: .stage` draws the opening stage first: rings and lines in the `tint` colour, white spreading across the window, closing onto the mark. `playsLaunchAnimation: false` skips the launch when there is no welcome to show.

### Windows

A picture fits a window that changes size while it moves, and is laid out again for the new size once it is at rest. The intro covers the whole window; on macOS the window's title and toolbar are hidden while it plays and return before the app is revealed.

## All options

`GlassIntro(…)` takes these, in this order; only `appName` and `pages` are required.

| Parameter | Default | |
|---|---|---|
| `appName` | — | The app's name, the last word of the ending by default |
| `mark` | `.standard` | The mark the launch opens on and the welcome turns to glass |
| `pages` | — | The welcome's pages, in any order |
| `finale` | `["Welcome", "to", appName]` | The ending's words, up to three lines; `[]` for none |
| `startTitle` | "Let's Begin" | The last page's line |
| `startButton` | "Get Started" | The last page's button |
| `continueButton` | "Continue" | The button on every other page |
| `tint` | `.accentColor` | The opening stage's colour, with `opening: .stage` |
| `background` | the window background | What the window shows behind the launch |
| `welcome` | `.firstLaunchOnly` | When the welcome plays |
| `opening` | `.mark` | How the launch begins: `.mark` or `.stage` |
| `playsLaunchAnimation` | `true` | Whether the launch plays when the welcome does not |
| `storage` | `.standard` | Where it records that the welcome was shown |

The modifiers:

| Modifier | |
|---|---|
| `.glassIntro(appName:mark:pages:finale:)` | Plays an intro of these pages when the view first appears |
| `.glassIntro(_:)` | Plays a `GlassIntro` when the view first appears |
| `.glassIntro(_:isPresented:)` | Plays a `GlassIntro` whenever the binding becomes true |

## Accessibility, localization, and privacy

- **Reduce Motion.** The launch fades instead of animating, and each page appears finished.
- **Keyboard.** Return continues on the page on screen; on macOS, Escape skips the launch.
- **VoiceOver.** Page indicators carry labels; the pictures are decorative and hidden from VoiceOver.
- **Localization.** The built-in text — "Continue", "Let's Begin", "Get Started", and the page labels — is in English; `continueButton(_:)`, `startTitle`, and `startButton` take your own. Page titles and messages are `LocalizedStringKey`s, localized from your app's string catalog.
- **Privacy.** No network requests. One Boolean in `UserDefaults`, or in the `GlassIntroStorage` you give.
- **SF Symbols.** Symbols are traced into glass outlines. Some SF Symbols may only refer to particular Apple products and must not be modified; the SF Symbols app marks them. Don't pass those to a page. The default symbols may be used by anyone, and a test checks them.

## Demo app

`Examples/GlassIntroDemo/GlassIntroDemo.xcodeproj` runs on iOS and macOS. It opens on a settings screen where you can try every option without writing code — the app's name and mark, how the launch opens, which pages play, the scene, the graph, the falling nodes, the ending's words, and the buttons — and writes out the code for the intro you have set up. **Play** plays it and lands in a simple app.

<p align="center">
  <img src="Sources/GlassIntroKit/GlassIntroKit.docc/Resources/screenshot-settings.png" width="220" alt="The demo app's settings screen.">
  <img src="Sources/GlassIntroKit/GlassIntroKit.docc/Resources/screenshot-app.png" width="220" alt="The demo app after the intro.">
</p>

On the Mac, the window opens at a comfortable size, the intro fits it as you resize it, and the title bar and toolbar stay hidden while it plays.

<p align="center">
  <img src="Sources/GlassIntroKit/GlassIntroKit.docc/Resources/mac-settings.png" width="400" alt="The demo app's settings screen on a MacBook Pro.">
  <img src="Sources/GlassIntroKit/GlassIntroKit.docc/Resources/mac-greeting.png" width="400" alt="The greeting on a MacBook Pro: hello written in glass over a forest.">
</p>

## Documentation

| Guide | What it covers |
|---|---|
| [Getting Started](Documentation/GettingStarted.md) | Installing, a first intro step by step, and the demo app |
| [Pages](Documentation/Pages.md) | The eight pictures and their options |
| [The Ending and the Mark](Documentation/Ending.md) | The words after the last page, the buttons, the mark |
| [Playing the Intro](Documentation/Playing.md) | When it plays, replaying it, storage, windows |
| [Architecture](Documentation/Architecture.md) | How the kit is built, for contributors |

The DocC catalog has the same guides, the API reference, and an interactive tutorial. In Xcode, choose **Product › Build Documentation**.

## Building and testing

The package includes a Metal shader, which SwiftPM and Xcode both compile into the package's resource bundle.

```sh
swift build
swift test -c release -Xswiftc -enable-testing
```

The tests play every page after every other page, random welcomes, every graph shape and scene, any number of falling nodes, and resized windows, frame by frame, and fail on any frame that jumps. They take several minutes; run them in release.

## FAQ

**The welcome doesn't play again.** It plays on the first launch only. Use `welcome: .everyLaunch` while you work, call `GlassIntro.resetWelcome()`, or play it with `.glassIntro(_:isPresented:)`.

**Can pages come in any order?** Yes, as often as you like. Pictures that weren't made to follow one another meet in a drop of glass.

**Can I use my own 3D content?** Yes: `.scene(_:message:content:)` shows any view, such as a `RealityView`, through the lens.

**Can I leave out the words at the end?** Yes: `finale: []`.

**Does it work in a window that changes size?** Yes, on iOS and macOS. A picture is fitted while it moves and laid out again once at rest.

**Is it open source?** Yes, under the Apache License 2.0.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md), and report security problems as described in [SECURITY.md](SECURITY.md). New to the code? Start with [HUMANS.md](HUMANS.md). Coding assistants should read [AGENTS.md](AGENTS.md). Changes are listed in [CHANGELOG.md](CHANGELOG.md).

## Author

GlassIntroKit is created and maintained by **Jiaxu Li** ([@Jiaxu-Li](https://github.com/Jiaxu-Li)).

## License

GlassIntroKit is © 2026 Jiaxu Li and licensed under the [Apache License, Version 2.0](LICENSE). See [NOTICE](NOTICE) for the works it includes. The forest picture in the demo app is not covered by that license and may not be used outside the demo ([details](Examples/GlassIntroDemo/ASSETS.md)).

The device frames in the screenshots and video are from [Apple Design Resources](https://developer.apple.com/design/resources/). Apple, iPhone, MacBook Pro, and macOS are trademarks of Apple Inc., registered in the U.S. and other countries and regions.

---

<p align="center">
  <img src="https://img.shields.io/badge/SwiftUI-0A84FF?logo=swift&logoColor=white" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Liquid%20Glass-5E5CE6" alt="Liquid Glass">
  <img src="https://img.shields.io/badge/Metal-1C1C1E?logo=apple&logoColor=white" alt="Metal">
  <img src="https://img.shields.io/badge/Swift%20Testing-F05138?logo=swift&logoColor=white" alt="Swift Testing">
  <a href="https://github.com/Jiaxu-Li"><img src="https://img.shields.io/badge/made%20by-Jiaxu%20Li-34C759?logo=github&logoColor=white" alt="Made by Jiaxu Li"></a>
</p>
