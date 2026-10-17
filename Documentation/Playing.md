# Playing the Intro

## When it plays

The launch plays once per process, in the first window that shows it. The welcome plays according to `welcome`:

| `welcome` | The welcome plays |
|---|---|
| `.firstLaunchOnly` (default) | once, recorded in `storage` |
| `.everyLaunch` | at every launch |
| `.never` | never; only the launch plays |

`GlassIntro.resetWelcome()` makes it play on the next launch. Give `storage` a key of your own to show a new welcome with a new version of your app:

```swift
GlassIntro(appName: "Orbit", pages: pages, storage: GlassIntroStorage(key: "Orbit.welcome.2"))
```

## Playing it again

`.glassIntro(_:isPresented:)` plays the intro whenever its binding becomes true, welcome included unless the schedule is `.never`, and sets it back to false when the intro ends.

## How the launch opens

By default the launch opens straight on the mark. `opening: .stage` draws the opening stage first, in the `tint` colour. `playsLaunchAnimation: false` skips the launch when there is no welcome to show.

## Windows

A picture fits a window that changes size while it moves, and is laid out again for the new size once it is at rest. On macOS the window's title and toolbar are hidden while the intro plays.

## Accessibility and localization

- With Reduce Motion on, the launch fades and each page appears finished.
- Return continues; on macOS, Escape skips the launch.
- Page indicators carry VoiceOver labels.
- Built-in text is in English; `continueButton(_:)`, `startTitle`, and `startButton` take your own. Page titles and messages are `LocalizedStringKey`s, localized from your app's string catalog.

## Privacy

The intro makes no network requests and stores one Boolean in `UserDefaults` (or your `GlassIntroStorage`).
