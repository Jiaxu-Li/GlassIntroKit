# Contributing to GlassIntroKit

Thank you for your interest in GlassIntroKit. This document explains how to report problems, propose changes, and get a change merged. For a tour of the code itself — how to think about it, where to start, and what will bite you — read [HUMANS.md](HUMANS.md).

GlassIntroKit is maintained by Jiaxu Li ([@Jiaxu-Li](https://github.com/Jiaxu-Li)), who reviews issues and pull requests.

By taking part, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting bugs

Open an issue using the bug report template. Include:

- What you expected and what happened instead.
- The smallest steps or code that reproduce it, ideally a `.glassIntro(...)` call with the pages involved.
- The platform (iOS or macOS), OS version, Xcode and Swift versions, and device or Mac model.
- A screenshot or screen recording when the problem is visual.

Please report security problems privately. See [SECURITY.md](SECURITY.md).

## Proposing features

Open an issue before you write code for anything larger than a small fix: a new picture, a new option, a change to the public API, or a change to how pages connect. Describe the problem you want to solve and how you would like it to look in code. Agreeing on the shape first saves you from rework, and the public API is kept small on purpose.

Small fixes, such as typos, documentation, and clear bugs, can go straight to a pull request.

## Setting up

Requirements: macOS 26 or later, and Xcode 27 (Swift 6.4). The package declares Swift 6.3 or later.

```sh
git clone https://github.com/Jiaxu-Li/GlassIntroKit.git
cd GlassIntroKit
```

Open `Package.swift` in Xcode, or work from the command line with SwiftPM.

## Building

```sh
swift build
```

The package includes a Metal shader, which SwiftPM and Xcode both compile into the package's resource bundle.

## Running the tests

The tests play every page after every other page, and random welcomes of every shape, frame by frame. They rasterize each frame and fail on any visual jump. That is a lot of frames, so run them optimized. They take several minutes:

```sh
swift test -c release -Xswiftc -enable-testing
```

All tests must pass before you open a pull request.

## Running the demo

Open `Examples/GlassIntroDemo/GlassIntroDemo.xcodeproj` in Xcode, choose the iOS or macOS destination, and run. The demo opens on a settings screen where you can try every option without writing code. Use it to check visual changes by eye.

## Coding conventions

- **Swift 6 and isolation.** The package uses Swift 6 with `MainActor` as the default isolation. Mark pure data and drawing types `nonisolated` so they can be used off the main actor.
- **One responsibility per file.** Keep files small and focused. Each picture lives in its own folder under `Sources/GlassIntroKit/Welcome/Motions`. Do not grow a crowded folder or a large file; split it.
- **File header.** Every Swift and Metal source file starts with this header, with the first line padded with dashes to 82 characters:

  ```swift
  //===--- FileName.swift - GlassIntroKit -----------------------------------===//
  //
  // This source file is part of the GlassIntroKit open source project
  //
  // Copyright (c) 2026 Jiaxu Li
  // Licensed under the Apache License, Version 2.0
  //
  // See LICENSE for license information
  //
  //===----------------------------------------------------------------------===//
  ```

- **Comments.** Explain intent and the reason for a choice, not what the syntax does.
- **Naming.** Use American English in identifiers, comments, and documentation.
- **Public API.** Keep it small. Every public type, property, and method has a DocC comment (`///`). Prefer an option on an existing type to a new type.
- **SF Symbols.** Symbols used by defaults must not be restricted. A test checks the defaults against the system's restriction list.

## Animation changes

Animations are tested for continuity. A change must keep the continuity tests passing. If you add a picture or an option, add tests for it, including how it connects to and from the other pictures.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Make a focused change. Unrelated changes belong in separate pull requests.
3. Run the tests in release, as above.
4. Update the README, the DocC documentation, and `CHANGELOG.md` for any user-visible change.
5. Open a pull request and fill in the template.

Before you submit, check that:

- [ ] The tests pass with `swift test -c release -Xswiftc -enable-testing`.
- [ ] New and changed public API has DocC comments.
- [ ] New options are documented in the README and DocC.
- [ ] Every new source file has the header.
- [ ] Visual changes include screenshots or a recording.
- [ ] `CHANGELOG.md` is updated for user-visible changes.

## AI coding assistants

If you use an AI coding assistant, point it at [AGENTS.md](AGENTS.md). You are responsible for any change you submit, whatever tool produced it.

## License

GlassIntroKit is licensed under the Apache License, Version 2.0. Under section 5 of the license, any contribution you intentionally submit for inclusion is licensed under the same terms, with no additional terms or conditions. There is no Contributor License Agreement.
