# Customizing the Ending and the Mark

Choose the words after the last page, the last page's own words, and your mark.

## Overview

The last page asks to begin. Its button plays the ending: a few words turn in, one after another, in glass; the mark forms at the center and fills with colour from its light; then it dissolves over your app.

![The last page with Let's Begin and Get Started, the word Welcome in glass, the mark in colour on black, and the app.](diagram-ending.jpg)

### The words

By default the words are "Welcome", "to", and your app's name. Choose up to three lines of your own, or none:

```swift
GlassIntro(appName: "Orbit", pages: pages)                                // "Welcome", "to", "Orbit"
GlassIntro(appName: "Orbit", pages: pages, finale: ["Have a", "good trip"])
GlassIntro(appName: "Orbit", pages: pages, finale: [])                    // straight to the mark
```

The last page's title and button, and the button on every other page, are yours to word too:

```swift
GlassIntro(
    appName: "Orbit",
    pages: pages,
    startTitle: Text("Off You Go"),
    startButton: Text("Start Exploring"),
    continueButton: Text("Next")
)
```

### The mark

``GlassIntroMark/standard`` is a white pearl with a yellow light set into it. ``GlassIntroMark/symbol(_:color:)`` draws an SF Symbol on a white body instead. For artwork of your own, use ``GlassIntroMark/custom(bodyDiameterRatio:bodyColor:light:outline:view:)``, which takes the mark in colour and its outline for glass — the round body with its detail cut out, opening from the plain body at 0 to the full detail at 1:

```swift
.custom(outline: { rect, opening in myMarkOutline(in: rect, opening: opening) }) {
    MyMarkView()
}

// The outline is drawn off the main actor, from `rect` and `opening` alone.
nonisolated func myMarkOutline(in rect: CGRect, opening: CGFloat) -> Path {
    // The body, with the detail cut out of it, scaled by `opening`.
}
```

To show the mark in your own views, use ``GlassIntroMarkView``.

## See Also

- ``GlassIntro``
- ``GlassIntroMark``
