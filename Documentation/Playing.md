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

## Skipping and interruptions

A Skip button shows in the corner while the welcome plays, on iOS and macOS; `showsSkipButton: false` hides it and `skipButton` relabels it. Escape skips on a Mac, and VoiceOver's escape gesture skips everywhere.

Whether the welcome counts as seen depends on how it ended:

| How it ended | Recorded as seen | What happens next |
|---|---|---|
| The last page's button, and the ending played | Yes | With `.firstLaunchOnly`, it doesn't play again |
| The Skip button, Escape, or the VoiceOver escape gesture | Yes | With `.firstLaunchOnly`, it doesn't play again |
| The app went to the background and came back | — | The intro carries on |
| The app was quit, or crashed, mid-welcome | No | It plays again, from the start, at the next launch |
| Its window was closed mid-intro (macOS) | No | The next window to open plays it from the start |

A replay with `isPresented` follows the same rules, and its binding is set back to false however it ends.

## How the launch opens

By default the launch opens straight on the mark. `opening: .stage` draws the opening stage first, in the `tint` colour. `playsLaunchAnimation: false` skips the launch when there is no welcome to show.

## Windows

A picture fits a window that changes size while it moves, and is laid out again for the new size once it is at rest. On macOS the window's title and toolbar are hidden while the intro plays.

## Accessibility and localization

- With Reduce Motion on, the launch fades and each page appears finished.
- With Reduce Transparency on, the mark rests on a solid surface, each page shows one solid colour, and the buttons are opaque. The two settings work together.
- Return continues; on macOS, Escape skips. VoiceOver's escape gesture skips everywhere.
- Page indicators and the Skip button carry VoiceOver labels.
- Built-in text is in English; `continueButton(_:)`, `startTitle`, `startButton`, and `skipButton` take your own. Page titles and messages are `LocalizedStringKey`s, localized from your app's string catalog.

## Privacy

The intro makes no network requests and stores one Boolean in `UserDefaults` (or your `GlassIntroStorage`).
