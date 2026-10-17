//===--- main.swift - GlassIntroKit -----------------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import CoreGraphics
import Foundation

/// Puts the documentation's screenshots and recordings in product bezels.
///
///     swift run --package-path Documentation/Tools/Framing Framing <bezels> <recordings> <output>
///
/// `<bezels>` holds the bezel PNGs from developer.apple.com/design/resources.
/// `<recordings>` holds `ios.mov` and `mac.mov`, recordings of the demo app
/// from its settings screen through the intro, and `timing.json`, which says
/// where each recording starts and which moments become screenshots:
///
///     { "iosStart": 4.4, "macStart": 1.6, "macCleanFrom": 2.45, "duration": 57,
///       "ios": { "launch": 8.0, … }, "mac": { "greeting": 11.0, … } }
///
/// `macCleanFrom` is the first moment the Mac recording shows only the
/// window. A window capture starts before the window has settled where it
/// was asked to be, so the desktop and other windows show at first; any
/// earlier moment shows the frame at `macCleanFrom` instead.
struct Timing: Decodable {
    let iosStart: Double
    let macStart: Double
    var macCleanFrom: Double? = nil
    let duration: Double
    let ios: [String: Double]
    let mac: [String: Double]
}

let arguments = CommandLine.arguments
// `Framing storyboard <folder>` draws storyboard.png from the framed
// screenshots already in <folder>.
if arguments.count == 3, arguments[1] == "storyboard" {
    let folder = URL(fileURLWithPath: arguments[2])
    try writeStoryboard(from: folder, to: folder.appendingPathComponent("storyboard.png"))
    exit(0)
}
guard arguments.count == 4 else {
    print("usage: Framing <bezels folder> <recordings folder> <output folder>\n       Framing storyboard <folder>")
    exit(1)
}
let bezels = URL(fileURLWithPath: arguments[1])
let recordings = URL(fileURLWithPath: arguments[2])
let output = URL(fileURLWithPath: arguments[3])

let iPhone = try Bezel.iPhone(in: bezels)
let mac = try Bezel.macBookPro(in: bezels)
let macScreen = MacScreen(size: mac.screen.size)
let timing = try JSONDecoder().decode(Timing.self, from: Data(contentsOf: recordings.appendingPathComponent("timing.json")))

do {
    let ios = try await Recording(recordings.appendingPathComponent("ios.mov"))
    let macRecording = try await Recording(recordings.appendingPathComponent("mac.mov"), start: timing.macCleanFrom ?? 0)

    // Screenshots: the iPhone at half its pixels, the Mac at a width
    // that reads in a page.
    for (name, time) in timing.ios {
        let framed = iPhone.framing(try await ios.frame(at: time), scale: 0.5)
        try writeImage(framed, to: output.appendingPathComponent("screenshot-\(name).png"))
    }
    for (name, time) in timing.mac {
        let framed = mac.framing(macScreen.compose(window: try await macRecording.frame(at: time)), scale: 0.42)
        try writeImage(framed, to: output.appendingPathComponent("mac-\(name).png"))
    }

    try writeStoryboard(from: output, to: output.appendingPathComponent("storyboard.png"))

    // The two side by side: the full recording, and a quicker loop.
    let sideBySide = SideBySide(mac: mac, iPhone: iPhone, macScreen: macScreen, width: 1440)
    let movie = try MovieWriter(url: output.appendingPathComponent("intro.mp4"), width: sideBySide.width,
                                height: sideBySide.height, fps: 30, bitrate: 2_200_000)
    var loop: [CGImage] = []
    let frameCount = Int(timing.duration * 30)
    for index in 0..<frameCount {
        let time = Double(index) / 30
        let frame = sideBySide.compose(
            macWindow: try await macRecording.frame(at: timing.macStart + time),
            iPhoneScreen: try await ios.frame(at: timing.iosStart + time)
        )
        await movie.append(frame)
        // Every eighth frame, shown for an eighth of a second: the loop
        // runs at about twice the speed.
        if index % 8 == 0 {
            loop.append(scaled(frame, width: 760))
        }
    }
    await movie.finish()
    try writeGIF(loop, delay: 0.125, to: output.appendingPathComponent("intro-preview.gif"))
    try writeImage(sideBySide.compose(
        macWindow: try await macRecording.frame(at: timing.macStart + 12),
        iPhoneScreen: try await ios.frame(at: timing.iosStart + 9.5)
    ), to: output.appendingPathComponent("devices.jpg"), jpeg: true)
} catch {
    print("error: \(error)")
    exit(1)
}
