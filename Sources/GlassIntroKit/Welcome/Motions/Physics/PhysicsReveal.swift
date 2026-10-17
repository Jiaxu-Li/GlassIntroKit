//===--- PhysicsReveal.swift - GlassIntroKit --------------------------------===//
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

/// The physics page's movement. The logic graph's wires draw back and leave
/// the nodes unsupported; a thin line opens above where the page's text
/// sits, and the nodes fall onto it under real gravity: they land, bounce,
/// slide, tip, and knock into one another, each hard landing throwing up a
/// little dust. The nodes are separate pieces of glass now and never merge.
///
/// The fall is simulated once, when the page turns, and played back.
nonisolated struct PhysicsReveal: Sendable {
    static let retractDuration = 0.5
    static let platformStart = 0.25
    static let platformDuration = 0.65
    static let release = 0.55
    static let simulatedDuration = 3.4
    static let textStart = 1.1
    static let end = release + simulatedDuration

    /// Gravity in points a second squared, for nodes the size of a few
    /// centimetres seen up close.
    private static let gravity = 3000.0
    private static let stepRate = 240.0
    private static let sampleRate = 120.0

    /// How each node lets go: a slight lift, drift, and turn. The first
    /// lands flat; the top branch drifts onto the bottom one. Chosen so
    /// every node comes to rest face up on Mac, iPhone, and iPad canvases.
    private static let nudges: [(velocity: SIMD2<Double>, spin: Double)] = [
        (SIMD2(-6, -40), 0),
        (SIMD2(20, -70), -0.15),
        (SIMD2(-4, -30), 0.05),
    ]

    private struct Pose: Sendable {
        let position: SIMD2<Double>
        let angle: Double
    }

    private struct Node: Sendable {
        let symbol: String
        let size: CGSize
        let cornerRadius: CGFloat
        let symbolSize: CGFloat
    }

    private let wires: [Path]
    private let beads: [CGPoint]
    private let nodes: [Node]
    private let platformCenter: CGPoint
    private let platformWidth: CGFloat
    /// Each sample's poses, one per node, `sampleRate` samples a second.
    private let samples: [[Pose]]
    /// Where each node hung when the picture began.
    private let hanging: [SIMD2<Double>]
    private let impacts: [RigidBodies.Impact]

    /// - Parameter platformY: where the thin line sits, just above the
    ///   page's text.
    init(canvasSize: CGSize, logic: GraphFrame, platformY: CGFloat) {
        wires = logic.wires
        beads = logic.beads
        nodes = logic.nodes.map {
            Node(
                symbol: $0.symbol,
                size: $0.rect.size,
                cornerRadius: $0.cornerRadius,
                symbolSize: $0.symbolSize
            )
        }
        hanging = logic.nodes.map { SIMD2(Double($0.rect.midX), Double($0.rect.midY)) }
        let centerX = logic.nodes.isEmpty
            ? canvasSize.width / 2
            : (logic.nodes.map(\.rect.minX).min()! + logic.nodes.map(\.rect.maxX).max()!) / 2
        platformCenter = CGPoint(x: centerX, y: platformY)
        let spread = logic.nodes.isEmpty
            ? 0
            : logic.nodes.map(\.rect.maxX).max()! - logic.nodes.map(\.rect.minX).min()!
        // Wide enough for the nodes as they hang, and for every node side by
        // side, within the canvas.
        let sideBySide = logic.nodes.reduce(0) { $0 + $1.rect.width * 1.25 } + 40
        platformWidth = min(
            canvasSize.width - 48,
            max(min(max(canvasSize.width * 0.5, 300), 620), spread + 80, sideBySide)
        )

        // The first way of letting go under which every node comes to rest
        // face up on the line; failing all, the one that leaves the most.
        var best: (samples: [[Pose]], impacts: [RigidBodies.Impact], settled: Int)?
        for release in Self.releases {
            let run = Self.simulate(
                nodes: logic.nodes,
                release: release,
                platformCenter: platformCenter,
                platformWidth: platformWidth
            )
            let settled = Self.settledCount(
                run.samples[run.samples.count - 1],
                before: run.samples[max(run.samples.count - 2, 0)],
                platformCenter: platformCenter,
                platformWidth: platformWidth
            )
            if best == nil || settled > best!.settled {
                best = (run.samples, run.impacts, settled)
            }
            if settled == logic.nodes.count {
                break
            }
        }
        samples = best?.samples ?? []
        impacts = best?.impacts ?? []
    }

    /// The ways the nodes may let go, tried in turn: the nudges as made,
    /// then gentler ones, then none at all.
    private static let releases: [Release] = [.nudged(1), .nudged(0.5), .nudged(0.2), .nudged(0), .spread]

    private enum Release {
        /// Each node's nudge, scaled.
        case nudged(Double)
        /// Each node glides sideways to a place of its own along the line
        /// before it lets go, and drops straight down, so that none can
        /// stack and topple.
        case spread
    }

    /// The fall, with each node let go as `release` says.
    private static func simulate(
        nodes: [GraphNodeFrame],
        release: Release,
        platformCenter: CGPoint,
        platformWidth: CGFloat
    ) -> (samples: [[Pose]], impacts: [RigidBodies.Impact]) {
        // The platform: a static slab whose top face is the line.
        let slabDepth = 400.0
        var bodies = [RigidBodies.Body(
            center: SIMD2(Double(platformCenter.x), Double(platformCenter.y) + slabDepth / 2),
            size: SIMD2(Double(platformWidth), slabDepth),
            radius: 0,
            isStatic: true,
            friction: 0.6,
            restitution: 0.15
        )]
        // A place of its own for each node along the line, in the order the
        // nodes hang from left to right, top to bottom.
        let order = nodes.indices.sorted {
            (nodes[$0].rect.midX, nodes[$0].rect.midY) < (nodes[$1].rect.midX, nodes[$1].rect.midY)
        }
        let span = Double(platformWidth) - 40
        var places = [Double](repeating: 0, count: nodes.count)
        for (slot, index) in order.enumerated() {
            places[index] = Double(platformCenter.x) - span / 2 + span * (Double(slot) + 0.5) / Double(nodes.count)
        }
        // Each node lets go with a small, different nudge, as a thing does
        // when what held it gives way.
        for (index, node) in nodes.enumerated() {
            var body = RigidBodies.Body(
                center: SIMD2(Double(node.rect.midX), Double(node.rect.midY)),
                size: SIMD2(Double(node.rect.width), Double(node.rect.height)),
                radius: Double(node.cornerRadius)
            )
            switch release {
            case .nudged(let share):
                let nudge = nudges[index % nudges.count]
                body.velocity = nudge.velocity * share
                body.angularVelocity = nudge.spin * share
            case .spread:
                // Let go from its place, straight down: it glides there
                // while the wires draw back.
                body.position.x = places[index]
            }
            bodies.append(body)
        }

        var world = RigidBodies(bodies: bodies, gravity: SIMD2(0, gravity))
        let stepsPerSample = Int(stepRate / sampleRate)
        let sampleCount = Int(simulatedDuration * sampleRate) + 1
        var samples: [[Pose]] = []
        samples.reserveCapacity(sampleCount)
        for sample in 0..<sampleCount {
            if sample > 0 {
                for _ in 0..<stepsPerSample {
                    world.step(1 / stepRate)
                }
            }
            samples.append(world.bodies.dropFirst().map { Pose(position: $0.position, angle: $0.angle) })
        }
        return (samples, world.impacts)
    }

    /// How many nodes are at rest, face up, above the line, between its
    /// ends, judged from the last two samples.
    private static func settledCount(
        _ last: [Pose],
        before: [Pose],
        platformCenter: CGPoint,
        platformWidth: CGFloat
    ) -> Int {
        zip(last, before).filter { pose, previous in
            let x = pose.position.x - Double(platformCenter.x)
            let upright = abs(remainder(pose.angle, 2 * .pi)) < 0.06
            let moved = pose.position - previous.position
            let still = (moved * moved).sum() < 0.25
            return abs(x) < Double(platformWidth) / 2 && pose.position.y < Double(platformCenter.y) && upright && still
        }.count
    }

    func frame(at time: Double) -> PhysicsFrame {
        var frame = PhysicsFrame()

        // The wires draw back: the long one off the canvas to the left, the
        // branches into the first node.
        let retract = Ease.smoother(time / Self.retractDuration)
        if retract <= 0 {
            frame.wires = wires
        } else if retract < 1 {
            frame.wires = wires.map { $0.trimmedPath(from: 0, to: 1 - retract) }
        }
        // The beads on the wires shrink away with them.
        if retract < 1 {
            frame.beads = beads
            frame.beadDiameter = GraphReveal.beadDiameter * CGFloat(1 - retract)
        }

        frame.platformCenter = platformCenter
        frame.platformWidth = platformWidth
            * CGFloat(Ease.easeOut((time - Self.platformStart) / Self.platformDuration))

        let simulated = min(max(time - Self.release, 0), Self.simulatedDuration)
        var poses = pose(at: simulated)
        if time < Self.release {
            // Each node glides from where it hung to where it lets go; for
            // all but a spread release, that is where it hung.
            let glide = Ease.smoother(time / Self.release)
            poses = zip(hanging, poses).map { from, to in
                Pose(position: from + (to.position - from) * glide, angle: to.angle * glide)
            }
        }
        frame.nodes = zip(nodes.indices, zip(nodes, poses)).map { index, pair in
            let (node, pose) = pair
            return PhysicsNodeFrame(
                id: index,
                symbol: node.symbol,
                center: CGPoint(x: pose.position.x, y: pose.position.y),
                angle: pose.angle,
                size: node.size,
                cornerRadius: node.cornerRadius,
                symbolSize: node.symbolSize
            )
        }
        frame.particles = particles(at: time - Self.release)
        return frame
    }

    /// The poses `time` seconds into the fall, between the two nearest
    /// samples.
    private func pose(at time: Double) -> [Pose] {
        let position = time * Self.sampleRate
        let lower = min(Int(position), samples.count - 1)
        let upper = min(lower + 1, samples.count - 1)
        let t = position - Double(lower)
        return zip(samples[lower], samples[upper]).map { a, b in
            Pose(
                position: a.position + (b.position - a.position) * t,
                angle: a.angle + (b.angle - a.angle) * t
            )
        }
    }

    /// Dust from each hard landing: grains thrown up and out along the
    /// surface, falling back under a lighter gravity as they fade.
    private func particles(at time: Double) -> [PhysicsParticle] {
        var result: [PhysicsParticle] = []
        for (impactIndex, impact) in impacts.enumerated() {
            let age = time - impact.time
            guard age >= 0, age < 1 else {
                continue
            }
            let count = 6 + Int(14 * impact.strength)
            for grain in 0..<count {
                let u = Self.random(impactIndex, grain, 0)
                let lifetime = 0.45 + 0.4 * Self.random(impactIndex, grain, 1)
                guard age < lifetime else {
                    continue
                }
                // Up, and mostly out to the sides.
                let angle = -Double.pi / 2 + (u - 0.5) * 2.7
                let speed = (110 + 420 * Self.random(impactIndex, grain, 2)) * (0.45 + 0.55 * impact.strength)
                let velocity = SIMD2(cos(angle), sin(angle)) * speed
                let position = impact.point + velocity * age + SIMD2(0, 0.5 * 900 * age * age)
                let fade = 1 - age / lifetime
                result.append(PhysicsParticle(
                    center: CGPoint(x: position.x, y: position.y),
                    diameter: 1.5 + 2.5 * Self.random(impactIndex, grain, 3),
                    opacity: 0.85 * fade * fade
                ))
            }
        }
        return result
    }

    /// A repeatable value in 0..<1 for the given indices.
    private static func random(_ a: Int, _ b: Int, _ c: Int) -> Double {
        var x = UInt64(truncatingIfNeeded: a &* 73_856_093 ^ b &* 19_349_663 ^ c &* 83_492_791)
        x ^= x >> 33
        x &*= 0xff51_afd7_ed55_8ccd
        x ^= x >> 33
        x &*= 0xc4ce_b9fe_1a85_ec53
        x ^= x >> 33
        return Double(x >> 11) / Double(1 << 53)
    }
}
