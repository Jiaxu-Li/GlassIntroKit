# Playing the Intro

Decide when the intro plays, play it again, and know what happens around it.

## Overview

The launch plays once per process, in the first window that shows it. The welcome plays on the first launch, and the intro records that it was shown.

### When the welcome plays

Set ``GlassIntro/welcome`` to ``GlassIntro/WelcomeSchedule/firstLaunchOnly`` (the default), ``GlassIntro/WelcomeSchedule/everyLaunch``, or ``GlassIntro/WelcomeSchedule/never``. ``GlassIntro/resetWelcome(storage:)`` makes the welcome play on the next launch. The record is kept in a ``GlassIntroStorage``; give your own key to show a new welcome with a new version of your app:

```swift
GlassIntro(appName: "Orbit", pages: pages, storage: GlassIntroStorage(key: "Orbit.welcome.2"))
```

### Playing it again

``SwiftUICore/View/glassIntro(_:isPresented:)`` plays the intro whenever its binding becomes true, welcome included unless the schedule is `never`, and sets the binding back to false when it ends:

```swift
struct ContentView: View {
    @State private var showsIntro = false

    var body: some View {
        Button("Show the Intro") {
            showsIntro = true
        }
        .glassIntro(intro, isPresented: $showsIntro)
    }
}
```

### Skipping and interruptions

A Skip button shows in the corner while the welcome plays, on iOS and macOS. ``GlassIntro/showsSkipButton`` hides it and ``GlassIntro/skipButton`` relabels it. Escape skips on a Mac, and VoiceOver's escape gesture skips everywhere.

Playing the welcome through, or skipping it, records it as seen. An interruption doesn't: if the app is quit mid-welcome, it plays again at the next launch; if its window is closed mid-intro on macOS, the next window plays it from the start. Moving to the background and back, the intro carries on.

### How the launch opens

By default the launch opens straight on the mark. ``GlassIntro/Opening/stage`` draws the opening stage first: rings and lines in the ``GlassIntro/tint`` colour, then white spreading across the window and closing onto the mark. ``GlassIntro/playsLaunchAnimation`` turns the launch off when there is no welcome to show.

### Windows

A picture fits a window that changes size while it moves, and is laid out again for the new size once it is at rest. On macOS the window's title and toolbar are hidden while the intro plays.

### Accessibility

- With Reduce Motion on, the launch fades instead of animating, and each page appears finished.
- With Reduce Transparency on, the mark rests on a solid surface instead of frosted glass, each page shows one solid colour, and the buttons are opaque. The two settings work together.
- Return continues on the page on screen.
- On macOS, Escape skips; VoiceOver's escape gesture skips everywhere.
- Page indicators and the Skip button carry VoiceOver labels.

## See Also

- ``GlassIntro``
- ``GlassIntroStorage``
