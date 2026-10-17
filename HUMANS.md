# HUMANS.md

The coding agents got [AGENTS.md](AGENTS.md). This one is for you, the carbon-based developer. It won't tell you how to open a pull request — [CONTRIBUTING.md](CONTRIBUTING.md) does that — but it will tell you what nobody writes down: how to think about this code, where to look first, and what will bite you.

## Read these first, in this order

1. [README.md](README.md) — what the kit does, from the outside.
2. [Documentation/Architecture.md](Documentation/Architecture.md) — the one diagram worth remembering.
3. `Sources/GlassIntroKit/Welcome/Model/WelcomePlayer.swift` — the heart of it. About 200 lines.
4. One picture, start to finish. `Welcome/Motions/Card` is the smallest; `Mark` is a good second.

Then run the demo app and press **Play**. Watching it once explains more than any of the above.

## The one idea

**Every picture is a function of time that returns data.** A picture (an `IntroMotion`) is asked "what do you look like at 1.37 seconds?" and answers with an `IntroFrame`: outlines of glass, symbols, a scene, a mark. It draws nothing. One view, `IntroFrameView`, draws every frame of every picture.

Hold on to that and the rest follows:

- **No animation state.** There are no `withAnimation` calls inside pictures, no timers, no "current position". Ask for any time and you get the same frame. That is what makes the frame-by-frame tests possible.
- **Joining pictures is the player's job.** When a page turns, `WelcomePlayer` either lets the next picture carry straight on from the current one, or has the current one gather into a drop of glass for the next to grow out of. Pictures only say what they hand on and what they can carry on from.
- **The view is dumb on purpose.** If something looks wrong, it is almost always the frame, not the view. Print the frame.

## Things you'll want to do

**Change how a picture moves.** Open its folder under `Welcome/Motions/<Picture>`. The larger pictures keep their timeline in a `…Reveal` type (`GreetingPlan` for the greeting), with constants like `textStart` and `end`; the `…Motion` type turns it into frames. Change it, then run that picture's tests and the transition tests.

**Add an option to a page.** Public surface first (`API/GlassIntroPage.swift` or a small public type like `GlassIntroScene`), then pass it through `IntroContext` in `Welcome/Model/WelcomeContent.swift`, then use it in the motion. Add it to the demo's settings screen too — it's how most people will discover it.

**Add a whole new picture.** See "Adding a picture" in [Architecture.md](Documentation/Architecture.md). Budget for tests: it has to join every other picture without a jump.

**See it.** The demo app is the fastest loop. For anything frame-exact, record the Simulator (`xcrun simctl io booted recordVideo intro.mov`) and step through the video; the human eye misses a one-frame pop that a recording won't.

## When a test fails

The continuity tests rasterize frames and look for jumps. A failure reads like this:

```
.graph → .scene, turned 0.0s after the text: [6.3220s: 0.10% of the picture changes at once]
```

That says: in a welcome of a graph page then a scene page, at 6.322 seconds, a tenth of a percent of the picture changed between two moments that should have been nearly identical. In other words, something popped.

How to find it:

1. Look at the time. Work out which picture is on screen then and whether it is entering, resting, or leaving.
2. Print the frame just before and just after: which piece appears, vanishes, or teleports? (Glass pieces have stable `id`s; compare them.)
3. Usual suspects: something that starts at full size instead of growing from zero; something removed at the end of a fade a frame too early; a picture laid out for a different canvas than the one it hands over to.

Do not fix it by raising the tolerance or fading the pop faster. The floor is already small; a "fix" like that just hides a jump a sharp-eyed person will still see.

Run tests in release — `swift test -c release -Xswiftc -enable-testing` — or you'll be waiting a long time. `--filter` is your friend.

## Things that will bite you

- **Leading dots continue the previous line.** Why pages are an array and not a result builder: two `.greeting(…)` / `.mark(…)` lines in a row parse as one chained call.
- **Glass outlines are built off the main actor.** Anything a custom mark's outline closure calls must be `nonisolated`.
- **Pictures are laid out for the canvas they began on.** Resizing the window mid-animation is handled — the frame is fitted, then re-laid out at rest — but if you add canvas-dependent layout, test it in `ResizeLayoutTests`.
- **Some SF Symbols are off-limits.** Symbols are traced into glass, and some may only refer to Apple products. Check new defaults with `SymbolRestrictionTests`.
- **Debug builds of the tests are slow.** Really slow. See above.

## Working with agents

Agents read [AGENTS.md](AGENTS.md), which holds the same rules as this file, written for them. If you let one loose here:

- Review its diff like any other contributor's. The tests catch jumps, not bad ideas.
- Watch for weakened tests. "Made the tests pass" sometimes means "made the tests easier".
- Watch for confident documentation of APIs that don't exist. Every snippet in the README compiles; keep it that way.

## House style, briefly

American English. Comments say *why*, not *what*. Small files with one job each. Every public thing has a `///` comment. If a name needs a comment to explain it, rename it first.

## Stuck?

Open an issue, describe what you expected and what you saw, and attach a screen recording if it moves. That is the fastest way to a fix — and a nicer way to spend an afternoon than staring at a 0.10% jump at 6.322 seconds.
