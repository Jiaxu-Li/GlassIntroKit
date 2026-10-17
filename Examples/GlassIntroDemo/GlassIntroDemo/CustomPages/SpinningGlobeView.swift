//===--- SpinningGlobeView.swift - GlassIntroKit ----------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

/// A scene page's own view, made with nothing but SwiftUI: a globe turning
/// over a night sky.
struct SpinningGlobeView: View {
    var body: some View {
        TimelineView(.animation) { context in
            let seconds = context.date.timeIntervalSinceReferenceDate
            let angle = seconds.truncatingRemainder(dividingBy: 12) / 12 * 360
            GeometryReader { proxy in
                ZStack {
                    LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
                    // A few stars, drifting slowly.
                    Canvas { canvas, size in
                        for index in 0..<60 {
                            let x = (Double(index * 73 % 997) / 997 * size.width + seconds * 4).truncatingRemainder(dividingBy: size.width)
                            let y = Double(index * 151 % 991) / 991 * size.height
                            canvas.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)), with: .color(.white.opacity(0.5)))
                        }
                    }
                    Image(systemName: "globe.europe.africa.fill")
                        .font(.system(size: 120))
                        .foregroundStyle(.cyan.gradient)
                        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
                        // The pictures' center sits a little above the middle.
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.4)
                }
            }
        }
    }
}
