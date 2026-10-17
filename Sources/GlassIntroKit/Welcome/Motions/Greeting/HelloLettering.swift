//===--- HelloLettering.swift - GlassIntroKit -------------------------------===//
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

/// The welcome's handwritten "hello", kept as one continuous pen stroke
/// rather than as font outlines: a glyph's outline has two edges, and
/// trimming it would trace the letters' borders instead of writing them.
nonisolated enum HelloLettering {
    /// The lettering's bounds in design units.
    static let designSize = CGSize(width: 839, height: 255.7)

    /// The pen's thickness in design units.
    static let lineWidth: CGFloat = 25

    /// How much larger the word is when the pen sets off than once it is
    /// written; it settles to its resting size as the writing goes on.
    static let startingGrowth: CGFloat = 0.24

    /// The pen's centerline in design units, from the lead-in at the lower
    /// left to the flourish leaving the "o", as cubic Bézier segments
    /// (start, control, control, end). Each segment runs between key points
    /// at the letters' extremes, where the line turns exactly horizontal or
    /// vertical, as a letterer would draw it; the h's stem is the one
    /// corner, where the pen reverses up its own line.
    private static let centerline: [[(CGFloat, CGFloat)]] = [
        [(0.0, 238.7), (44.4, 231.3), (169.3, 86.3), (169.3, 36.4)],
        [(169.3, 36.4), (169.3, 17.4), (167.0, 0.0), (143.4, 0.0)],
        [(143.4, 0.0), (105.2, 0.0), (79.3, 222.5), (79.5, 255.7)],
        [(79.5, 255.7), (82.8, 222.0), (109.5, 129.5), (151.1, 129.5)],
        [(151.1, 129.5), (183.2, 129.5), (181.7, 163.6), (181.7, 185.1)],
        [(181.7, 185.1), (181.7, 225.2), (172.6, 253.8), (227.6, 253.8)],
        [(227.6, 253.8), (267.3, 253.8), (336.4, 203.0), (336.4, 160.7)],
        [(336.4, 160.7), (336.4, 140.6), (324.0, 127.9), (303.9, 127.9)],
        [(303.9, 127.9), (269.9, 127.9), (260.1, 171.2), (260.1, 197.6)],
        [(260.1, 197.6), (260.1, 250.7), (274.7, 252.0), (321.6, 252.0)],
        [(321.6, 252.0), (405.2, 252.0), (494.3, 121.6), (494.3, 41.6)],
        [(494.3, 41.6), (494.3, 22.6), (493.3, 2.8), (469.1, 2.8)],
        [(469.1, 2.8), (429.5, 2.8), (414.0, 114.3), (414.0, 143.3)],
        [(414.0, 143.3), (414.0, 189.3), (410.8, 255.5), (472.0, 255.5)],
        [(472.0, 255.5), (533.5, 255.5), (626.7, 101.8), (626.7, 41.1)],
        [(626.7, 41.1), (626.7, 22.7), (624.8, 4.1), (601.5, 4.1)],
        [(601.5, 4.1), (562.4, 4.1), (546.0, 117.7), (546.0, 146.6)],
        [(546.0, 146.6), (546.0, 190.9), (544.8, 254.6), (605.4, 254.6)],
        [(605.4, 254.6), (631.0, 254.6), (639.9, 229.2), (654.0, 207.7)],
        [(654.0, 207.7), (677.3, 172.1), (698.9, 137.6), (741.5, 137.6)],
        [(741.5, 137.6), (771.5, 137.6), (783.6, 158.5), (783.6, 185.6)],
        [(783.6, 185.6), (783.6, 219.8), (761.6, 254.8), (724.5, 254.8)],
        [(724.5, 254.8), (693.6, 254.8), (676.5, 226.0), (676.5, 197.9)],
        [(676.5, 197.9), (676.5, 164.5), (704.7, 137.2), (739.0, 137.2)],
        [(739.0, 137.2), (760.7, 137.2), (771.3, 141.2), (793.0, 141.2)],
        [(793.0, 141.2), (814.3, 141.2), (822.3, 133.0), (839.0, 119.7)],
    ]

    /// The stroke resampled at even steps of the pen's travel, so a fraction
    /// of the progress is the same fraction of the writing and the pen keeps
    /// a steady speed through tight loops and long strokes alike.
    private static let samples: [CGPoint] = resample(
        flattened(centerline.map { segment in segment.map { CGPoint(x: $0.0, y: $0.1) } }),
        count: 1_600
    )

    /// For each sample, the word's x that sits under the screen's center.
    ///
    /// Through the first half of the word the pen's overall progress to the
    /// right is cancelled, so the pen stays near the center and the word
    /// slides left beneath it; loops still swing the pen from side to side,
    /// since only the pen's broad drift is followed. Once the word's middle
    /// reaches the center the word comes to rest, centered, and the pen
    /// carries on to the right.
    private static let anchors: [CGFloat] = {
        let drift = gaussianSmoothed(samples.map(\.x), sigma: 110)
        let middle = designSize.width / 2
        let resting = drift.firstIndex { $0 >= middle } ?? drift.count - 1
        let followed = drift.indices.map { $0 < resting ? drift[$0] : middle }
        return gaussianSmoothed(followed, sigma: 90)
    }()

    // MARK: Lookup

    static func designPoint(at progress: Double) -> CGPoint {
        let (index, fraction) = position(of: progress)
        let a = samples[index]
        let b = samples[index + 1]
        return CGPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction)
    }

    static func anchorX(at progress: Double) -> CGFloat {
        let (index, fraction) = position(of: progress)
        return anchors[index] + (anchors[index + 1] - anchors[index]) * fraction
    }

    /// The word's size relative to its resting size.
    static func growth(at progress: Double) -> CGFloat {
        let t = CGFloat(min(max(progress, 0), 1))
        let eased = t * t * t * (t * (t * 6 - 15) + 10)
        return 1 + startingGrowth * (1 - eased)
    }

    /// The samples the pen passes between `start` and `progress`.
    static func samplePoints(from start: Double, through progress: Double) -> ArraySlice<CGPoint> {
        let (first, _) = position(of: start)
        let (last, _) = position(of: progress)
        return samples[(first + 1)...max(last, first + 1)]
    }

    private static func position(of progress: Double) -> (Int, CGFloat) {
        let position = min(max(progress, 0), 1) * Double(samples.count - 1)
        let index = min(Int(position), samples.count - 2)
        return (index, CGFloat(position - Double(index)))
    }

    // MARK: Construction

    /// The segments flattened finely into one polyline.
    private static func flattened(_ segments: [[CGPoint]]) -> [CGPoint] {
        var result = [segments[0][0]]
        let steps = 48
        for segment in segments {
            let (p0, c1, c2, p3) = (segment[0], segment[1], segment[2], segment[3])
            for step in 1...steps {
                let t = CGFloat(step) / CGFloat(steps)
                let u = 1 - t
                let a = u * u * u
                let b = 3 * u * u * t
                let c = 3 * u * t * t
                let d = t * t * t
                result.append(CGPoint(
                    x: a * p0.x + b * c1.x + c * c2.x + d * p3.x,
                    y: a * p0.y + b * c1.y + c * c2.y + d * p3.y
                ))
            }
        }
        return result
    }

    /// The polyline resampled at `count` points spaced evenly along it.
    private static func resample(_ points: [CGPoint], count: Int) -> [CGPoint] {
        var lengths = [CGFloat](repeating: 0, count: points.count)
        for index in 1..<points.count {
            let a = points[index - 1]
            let b = points[index]
            lengths[index] = lengths[index - 1] + hypot(b.x - a.x, b.y - a.y)
        }
        let total = lengths[points.count - 1]
        var result: [CGPoint] = []
        result.reserveCapacity(count)
        var segment = 1
        for sample in 0..<count {
            let target = total * CGFloat(sample) / CGFloat(count - 1)
            while segment < points.count - 1, lengths[segment] < target {
                segment += 1
            }
            let start = lengths[segment - 1]
            let span = max(lengths[segment] - start, .ulpOfOne)
            let fraction = min(max((target - start) / span, 0), 1)
            let a = points[segment - 1]
            let b = points[segment]
            result.append(CGPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction))
        }
        return result
    }

    /// The values blurred along their order, holding the ends.
    private static func gaussianSmoothed(_ values: [CGFloat], sigma: Int) -> [CGFloat] {
        let radius = sigma * 3
        let weights = (-radius...radius).map { offset in
            exp(-CGFloat(offset * offset) / CGFloat(2 * sigma * sigma))
        }
        let total = weights.reduce(0, +)
        return values.indices.map { index in
            var sum: CGFloat = 0
            for (tap, weight) in weights.enumerated() {
                let source = min(max(index + tap - radius, 0), values.count - 1)
                sum += values[source] * weight
            }
            return sum / total
        }
    }
}

/// Where the word sits on screen as it is written: it starts a little
/// larger with the pen near the center, slides and settles while the pen
/// writes, and comes to rest in `restingFrame`.
nonisolated struct HelloLayout: Equatable, Sendable {
    let restingFrame: CGRect

    /// Screen points per design unit at the resting size.
    private var unit: CGFloat {
        restingFrame.width / HelloLettering.designSize.width
    }

    func scale(at progress: Double) -> CGFloat {
        unit * HelloLettering.growth(at: progress)
    }

    /// A point of the word on screen, while the pen is at `progress`.
    func place(_ point: CGPoint, at progress: Double) -> CGPoint {
        let scale = scale(at: progress)
        return CGPoint(
            x: restingFrame.midX + scale * (point.x - HelloLettering.anchorX(at: progress)),
            y: restingFrame.midY + scale * (point.y - HelloLettering.designSize.height / 2)
        )
    }

    func penPoint(at progress: Double) -> CGPoint {
        place(HelloLettering.designPoint(at: progress), at: progress)
    }

    func lineWidth(at progress: Double) -> CGFloat {
        scale(at: progress) * HelloLettering.lineWidth
    }

    /// The word's centerline on screen between `start` and `progress` of
    /// the writing, with the camera where it is at `progress`.
    func centerline(from start: Double = 0, through progress: Double) -> Path {
        var path = Path()
        guard progress > start else {
            return path
        }
        path.move(to: penPoint(at: start, cameraAt: progress))
        for point in HelloLettering.samplePoints(from: start, through: progress) {
            path.addLine(to: place(point, at: progress))
        }
        path.addLine(to: penPoint(at: progress))
        return path
    }

    private func penPoint(at progress: Double, cameraAt camera: Double) -> CGPoint {
        place(HelloLettering.designPoint(at: progress), at: camera)
    }
}

nonisolated extension HelloLayout {
    /// Where the word rests on `canvas`: centered at the pictures' height,
    /// a third of the width across, two thirds on a narrow canvas.
    static func resting(in canvas: IntroCanvas) -> HelloLayout {
        let width = min(420, canvas.size.width * (canvas.isCompact ? 0.68 : 0.34))
        let height = width * HelloLettering.designSize.height / HelloLettering.designSize.width
        return HelloLayout(restingFrame: CGRect(
            x: canvas.graphicCenter.x - width / 2,
            y: canvas.graphicCenter.y - height / 2,
            width: width,
            height: height
        ))
    }
}
