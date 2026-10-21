# Testing on Devices

The automated tests check every frame's data and every transition, and they run in the Simulator and on a Mac. Three things only real hardware shows: how the glass refracts what is behind it, whether the motion stays smooth, and whether the text reads well on a real screen. This page is the checklist for those, and a form to record what you found.

Use the demo app: it opens on a settings screen, and **Play** plays the intro you have set up.

## Before you start

- Build the demo in **Release** (Product › Scheme › Edit Scheme › Run › Build Configuration). Debug builds animate noticeably slower.
- Note the device, the system version, and the GlassIntroKit version or commit.
- For a number on smoothness, profile a play with Instruments' Animation Hitches template.

## Checklist

Run each line with all pages on, then once with the forest background off.

### Look

| # | Check | How |
|---|---|---|
| L1 | Glass refracts what is behind it, without banding or flicker | Watch "hello", the mark page, and the symbols page |
| L2 | The 3D object is lit and shadowed, and its edges are clean | Scene page, and drag to turn it |
| L3 | Titles, messages, and buttons are easy to read on every page | Read each page at arm's length |
| L4 | Dark Mode and Light Mode both look right | Switch the system appearance and play again |

### Motion

| # | Check | How |
|---|---|---|
| M1 | No stutter while pages turn | Watch each turn; note any page that drops frames |
| M2 | No frame where something pops, vanishes, or jumps | Record the screen and step through it if unsure |
| M3 | The device doesn't get hot and the battery isn't drained by one play | Play the full intro three times in a row |
| M4 | ProMotion displays run smoothly at their higher rate | iPhone Pro, iPad Pro, or MacBook Pro |

### Accessibility

Settings › Accessibility on iOS, System Settings › Accessibility › Display on macOS.

| # | Check | How |
|---|---|---|
| A1 | Reduce Motion: the launch fades, and each page appears finished | Turn it on, play |
| A2 | Reduce Transparency: no frosted glass, solid colours, opaque buttons, text clear | Turn it on, play |
| A3 | Both together | Turn both on, play |
| A4 | Increase Contrast | Turn it on, play, and read every page |
| A5 | VoiceOver reads page dots, titles, messages, buttons, and Skip; the escape gesture skips | Turn it on, play |
| A6 | Larger text sizes don't clip titles or buttons | Set the largest standard size |

### Skipping and interruptions

| # | Check | Expected |
|---|---|---|
| S1 | Tap Skip mid-welcome | The app appears; the welcome doesn't play at the next launch |
| S2 | Press Escape mid-welcome (Mac) | Same as S1 |
| S3 | Go to the Home Screen mid-turn, wait 10 seconds, come back | The intro carries on; nothing is stuck |
| S4 | Lock the device mid-launch, unlock | The launch finishes; nothing is stuck on the frosted glass |
| S5 | Force quit mid-welcome, open the app again | The welcome plays again from the start |
| S6 | Close the window mid-intro, open a new one (Mac) | The new window plays the intro from the start |
| S7 | Rotate, or resize the window, mid-turn | The picture stays inside the window and settles at the new size |

To see the welcome again in the demo, it plays every time you press **Play**. In your own app, call `GlassIntro.resetWelcome()` or delete the app.

## Record

Copy this table into an issue or a pull request, one row per device.

| Device | System | GlassIntroKit | Display | L1–L4 | M1–M4 | A1–A6 | S1–S7 | Notes |
|---|---|---|---|---|---|---|---|---|
| e.g. iPhone 17 Pro | iOS 26.1 | 0.2.0 | 120 Hz | ✓ ✓ ✓ ✓ | ✓ ✓ ✓ ✓ | ✓ ✓ ✓ ✓ ✓ ✓ | ✓ ✓ – ✓ ✓ – ✓ | – means not applicable |

When something is wrong, open a bug report with a screen recording: the template asks for everything needed to find it.

## Results so far

| Device | System | GlassIntroKit | Result |
|---|---|---|---|
| | | | Not yet tested on hardware |
