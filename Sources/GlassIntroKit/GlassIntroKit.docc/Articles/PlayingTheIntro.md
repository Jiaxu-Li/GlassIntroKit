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

### How the launch opens

By default the launch opens straight on the mark. ``GlassIntro/Opening/stage`` draws the opening stage first: rings and lines in the ``GlassIntro/tint`` colour, then white spreading across the window and closing onto the mark. ``GlassIntro/playsLaunchAnimation`` turns the launch off when there is no welcome to show.

### Windows

A picture fits a window that changes size while it moves, and is laid out again for the new size once it is at rest. On macOS the window's title and toolbar are hidden while the intro plays.

### Accessibility

- With Reduce Motion on, the launch fades instead of animating, and each page appears finished.
- Return continues on the page on screen.
- On macOS, Escape skips the launch.
- Page indicators carry VoiceOver labels.

## See Also

- ``GlassIntro``
- ``GlassIntroStorage``
