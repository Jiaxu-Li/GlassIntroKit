# ``GlassIntroKit``

A first-launch intro for SwiftUI apps, made with Liquid Glass and Metal.

@Metadata {
    @Available(iOS, introduced: "26.0")
    @Available(macOS, introduced: "26.0")
    @PageImage(purpose: icon, source: "icon", alt: "A waving hand in glass on a blue grid.")
    @PageColor(blue)
}

## Overview

GlassIntroKit plays an intro over your app with one modifier. The launch opens on your mark on frosted glass. On the first launch a welcome follows: the mark writes "hello" in glass, then turns, page by page, into the pictures your app's story needs. At the end a few words turn in, the mark fills with colour, and it dissolves over your app.

![Five screens of the intro: the mark on frosted glass, "hello" written in glass over a forest, the mark in glass, symbols scattered around it, and a lit cube seen through a lens.](diagram-story.jpg)

```swift
ContentView()
    .glassIntro(
        appName: "Orbit",
        pages: [
            .greeting("Welcome to Orbit", message: "Plan trips together."),
            .symbols("Everything in Reach", message: "Maps, photos, and notes."),
            .icon("Ready When You Are", message: "Packed and ready to go."),
        ]
    )
```

Pages come in any order. Each picture can be configured — a graph of your own nodes and wires, a 3D scene in your shape, colour, and motion, or a view of your own — and every pair of pictures joins without a jump.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:/tutorials/Tutorials>
- ``SwiftUICore/View/glassIntro(appName:mark:pages:finale:)``
- ``GlassIntro``

### Pages

- <doc:ChoosingPages>
- ``GlassIntroPage``
- ``GlassIntroGraph``
- ``GlassIntroScene``
- ``GlassIntroBackground``

### The Ending and the Mark

- <doc:CustomizingTheEnding>
- ``GlassIntroMark``
- ``GlassIntroMarkView``

### Playing the Intro

- <doc:PlayingTheIntro>
- ``SwiftUICore/View/glassIntro(_:)``
- ``SwiftUICore/View/glassIntro(_:isPresented:)``
- ``GlassIntroStorage``
