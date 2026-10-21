# SwiftUI and Metal

Almost everything in the intro is SwiftUI. Metal draws one thing: the 3D object on a scene page. This page says which part draws what, so you know where to look.

## The split

| What you see | Drawn by | Where |
|---|---|---|
| Glass: "hello", the mark, scattered symbols, graph wires and nodes, the lens | SwiftUI Liquid Glass, `glassEffect(_:in:)` in a `GlassEffectContainer` | `Welcome/Rendering/IntroFrameView.swift` |
| The shapes the glass takes | Core Graphics paths, built off the main actor | `Glass/`, each picture's `…Motion` |
| SF Symbols, lines, sheens, particles | SwiftUI views and a `Canvas` | `Welcome/Rendering/IntroFrameView.swift` |
| Each page's light | SwiftUI `MeshGradient`, or your image or colour | `Welcome/Backdrop/WelcomeBackdrop.swift` |
| Titles, messages, buttons, page dots, Skip | SwiftUI | `Welcome/Text/`, `Launch/IntroSkipButton.swift` |
| The launch: frosted glass and the mark | SwiftUI materials (`NSVisualEffectView` on macOS) | `Launch/` |
| The 3D object on its floor, lit and shadowed | **Metal**: a ray-marched `[[stitchable]]` shader | `Shaders/WelcomeScene.metal` |
| A view of your own through the lens, such as a `RealityView` | Your view | `.scene(_:message:content:)` |

## How Metal is used

There is no `MTKView` and no render loop. The shader is a SwiftUI color effect:

```swift
Rectangle()
    .fill(Color.black)
    .colorEffect(ShaderLibrary.bundle(.module).welcomeScene(/* size, center, shape, colour, turn, … */))
```

SwiftUI calls the shader once per pixel of that rectangle. For each pixel it marches a ray into a scene of one object (a cube, sphere, ring, capsule, or cylinder) on a studio floor, and shades it with soft shadows, ambient occlusion, highlights, reflections, and a glossy floor, revealed level by level. Everything the shader needs (the object's turn, the light level of the reveal, the sweep of the rendering) arrives as arguments from the picture's frame for that moment. The shader keeps no state.

SwiftUI then masks the result to the lens, a circle of Liquid Glass, so the object is seen through it.

The package's `.metal` file is compiled by SwiftPM and Xcode into the package's resource bundle; nothing needs setting up. `ResourceTests` checks that the shader is packaged.

## How SwiftUI is used

Every picture is a function of time that returns an `IntroFrame`: a list of glass pieces with their paths, symbols, a scene, and the mark. One view, `IntroFrameView`, draws whatever frame it's given, inside a `TimelineView` that only runs while something moves.

All glass sits in one `GlassEffectContainer`, so pieces close together flow into one another and pull apart like liquid. The system draws the glass. With Reduce Transparency on, the system makes the glass frostier on its own; the intro also replaces each page's light with one solid colour and uses opaque buttons.

## Where to change things

- **How something moves:** its picture's folder under `Welcome/Motions`. Every picture keeps its timeline in its `…Reveal` type and turns it into frames in its `…Motion` type.
- **How glass looks:** `IntroFrameView` and `GlassPieceView`.
- **How the 3D object looks:** `WelcomeScene.metal`. The scene's look, such as shape, colour, and motion, comes from `GlassIntroScene` through `SceneLook`.
- **The page's light:** `WelcomeBackdrop.palette(for:)`.
