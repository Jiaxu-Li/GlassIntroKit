//===--- Style.swift - GlassIntroKit ----------------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import AppKit
import SwiftUI

/// The diagrams' look, after the diagrams in WWDC sessions: flat blocks in
/// a few solid colours with small white labels, thin arrows, stacked
/// copies for "one of many", on a soft grey slide.
enum Tone {
    static let indigo = Color(red: 0.29, green: 0.28, blue: 0.76)
    static let violet = Color(red: 0.36, green: 0.33, blue: 0.84)
    static let lavender = Color(red: 0.69, green: 0.68, blue: 0.89)
    static let pale = Color(red: 0.79, green: 0.79, blue: 0.92)
    static let green = Color(red: 0.36, green: 0.67, blue: 0.35)
    static let gray = Color(red: 0.42, green: 0.43, blue: 0.44)
    static let orange = Color(red: 0.80, green: 0.48, blue: 0.18)
    static let ink = Color(red: 0.16, green: 0.17, blue: 0.19)
}

/// A 16:9 slide, 1600 × 900 points, on which everything is placed by its
/// center.
struct Slide<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color(red: 0.94, green: 0.945, blue: 0.95), Color(red: 0.85, green: 0.86, blue: 0.87)],
                startPoint: .top,
                endPoint: .bottom
            )
            content
        }
        .frame(width: 1600, height: 900)
        .environment(\.colorScheme, .light)
    }
}

/// A flat block with a small white label.
struct Block: View {
    let text: String
    var color = Tone.indigo
    var width: CGFloat = 220
    var height: CGFloat = 46
    var code = false

    var body: some View {
        Text(text)
            .font(code ? .system(size: 16, weight: .medium, design: .monospaced) : .system(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 12)
            .frame(width: width, height: height)
            .background(color, in: .rect(cornerRadius: 5))
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
    }
}

/// A block standing for one of many: two paler copies behind it.
struct StackedBlock: View {
    let text: String
    var color = Tone.indigo
    var width: CGFloat = 220
    var code = false

    var body: some View {
        ZStack {
            Block(text: "", color: Tone.lavender.opacity(0.55), width: width).offset(x: -16, y: 12)
            Block(text: "", color: Tone.lavender.opacity(0.85), width: width).offset(x: -8, y: 6)
            Block(text: text, color: color, width: width, code: code)
        }
    }
}

/// A soft white panel that groups blocks.
struct Panel: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.92))
            .frame(width: width, height: height)
            .shadow(color: Tone.lavender.opacity(0.7), radius: 16)
    }
}

/// Small grey text, for captions and arrow labels.
struct Caption: View {
    let text: String
    var size: CGFloat = 14
    var weight: Font.Weight = .medium
    var color = Color(white: 0.38)
    var code = false

    var body: some View {
        Text(text)
            .font(code ? .system(size: size, weight: weight, design: .monospaced) : .system(size: size, weight: weight))
            .foregroundStyle(color)
            .fixedSize()
    }
}

/// A screenshot of the running app in its device's bezel, `height` points
/// tall. The bezel is shown as Apple provides it: no shadow, tilt, or crop.
struct Screen: View {
    let name: String
    let height: CGFloat

    var body: some View {
        let image = NSImage(contentsOf: Images.folder.appendingPathComponent("screenshot-\(name).png")) ?? NSImage()
        let aspect = image.size.width / max(image.size.height, 1)
        Image(nsImage: image)
            .resizable()
            .frame(width: height * aspect, height: height)
    }

    /// Where a point of the screen, in the recording's own pixels, falls on
    /// the slide when the framed screenshot is `height` tall and centered on
    /// `center`. The framed screenshots are the iPhone 18 Pro bezel at half
    /// size, its screen starting 72 and 69 pixels in.
    static func point(_ screen: CGPoint, height: CGFloat, center: CGPoint) -> CGPoint {
        let framed = CGSize(width: 675, height: 1380)
        let scale = height / framed.height
        let origin = CGPoint(x: center.x - framed.width * scale / 2, y: center.y - height / 2)
        return CGPoint(
            x: origin.x + (72 + screen.x) / 2 * scale,
            y: origin.y + (69 + screen.y) / 2 * scale
        )
    }
}

/// Lines between points, each ending in a small arrowhead or a dot.
struct Connectors: View {
    struct Line {
        var from: CGPoint
        var to: CGPoint
        var dashed = false
        var head = true
        var dot = false
        var via: CGPoint?
    }

    let lines: [Line]
    var color = Tone.indigo

    var body: some View {
        Canvas { context, _ in
            for line in lines {
                var path = Path()
                path.move(to: line.from)
                if let via = line.via {
                    path.addLine(to: via)
                }
                path.addLine(to: line.to)
                let style = StrokeStyle(lineWidth: 2, lineCap: .round, dash: line.dashed ? [3, 5] : [])
                context.stroke(path, with: .color(color), style: style)
                let last = line.via ?? line.from
                if line.head {
                    let angle = atan2(line.to.y - last.y, line.to.x - last.x)
                    var head = Path()
                    head.move(to: line.to)
                    head.addLine(to: CGPoint(x: line.to.x - 11 * cos(angle - 0.42), y: line.to.y - 11 * sin(angle - 0.42)))
                    head.addLine(to: CGPoint(x: line.to.x - 11 * cos(angle + 0.42), y: line.to.y - 11 * sin(angle + 0.42)))
                    head.closeSubpath()
                    context.fill(head, with: .color(color))
                }
                if line.dot {
                    context.fill(Path(ellipseIn: CGRect(x: line.to.x - 4, y: line.to.y - 4, width: 8, height: 8)), with: .color(color))
                }
            }
        }
        .frame(width: 1600, height: 900)
        .allowsHitTesting(false)
    }
}

extension View {
    /// Places the view's center at `x`, `y` on the slide.
    func at(_ x: CGFloat, _ y: CGFloat) -> some View {
        position(x: x, y: y)
    }
}

/// Where the screenshots are, and where the diagrams go.
enum Images {
    static let folder = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("../../../../../Sources/GlassIntroKit/GlassIntroKit.docc/Resources")
        .standardizedFileURL
}
