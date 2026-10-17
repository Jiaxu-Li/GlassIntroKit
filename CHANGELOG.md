# Changelog

## 0.1.0

First release.

- **Launch.** The launch opens on your mark on frosted glass and carries on into the welcome, or dissolves over your app. `opening: .stage` draws the opening stage first, in your `tint`. The launch plays once per process; `playsLaunchAnimation` turns it off when there is no welcome to show.
- **Welcome.** Eight pictures in Liquid Glass — `greeting`, `mark`, `symbols`, `scene`, `graph`, `physics`, `icon`, and `card` — in any order, as often as you like. Pictures made to follow one another carry straight on; any other two meet in a drop of glass. Each page can have its own `background` and `continueButton`.
- **Scenes.** A live, ray-marched Metal scene in five shapes, any colour, and four motions, revealed level by level or opened fully lit, and turned by dragging — or a view of your own, such as a `RealityView`, seen through the same lens.
- **Graphs.** Any nodes and links, or `.chain`, `.branch`, and `.diamond`, laid out in columns and scaled to fit the window.
- **Physics.** Up to eight nodes fall under rigid-body physics, and every one comes to rest face up on the line.
- **Ending.** Up to three lines of glass words of your own, or none, then the mark fills with colour and dissolves over your app. The last page's title and button are yours to word.
- **Marks.** `.standard`, a white pearl with a yellow light; `.symbol(_:color:)`; and `.custom(outline:view:)` for artwork of your own.
- **Presentation.** `.glassIntro(appName:mark:pages:finale:)`, `.glassIntro(_:)`, and `.glassIntro(_:isPresented:)` to replay. The welcome plays on the first launch, on every launch, or never, recorded in a `GlassIntroStorage` of your choosing; `GlassIntro.resetWelcome()` shows it again.
- **Windows.** Pictures fit a window that changes size while they move, and are laid out again for it once at rest. On macOS the window's title and toolbar stay hidden while the intro plays.
- **Accessibility.** Reduce Motion fades the launch and shows each page finished; Return continues; Escape skips the launch on macOS; page indicators carry VoiceOver labels.
- **Text.** Built-in text in English; page titles, messages, and buttons take your own localized text.
- **Documentation.** Guides in `Documentation`, a DocC catalog with an interactive tutorial, and a demo app that tries every option and writes out its code.
