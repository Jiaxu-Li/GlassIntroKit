//===--- RigidBodies.swift - GlassIntroKit ----------------------------------===//
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
import simd

/// A small 2D rigid-body solver for the welcome's physics page, after the
/// method of Box2D: convex polygons collide by separating axes with
/// clipped contact points, and contacts are solved with sequential
/// impulses, Coulomb friction, and restitution. A rounded tile is the
/// polygon that follows its corner arcs, so it rests and rolls on the
/// outline that is drawn.
///
/// Units are points and seconds, with y pointing down.
nonisolated struct RigidBodies: Sendable {
    struct Body: Sendable {
        var position: SIMD2<Double>
        var angle: Double
        var velocity: SIMD2<Double> = .zero
        var angularVelocity: Double = 0
        /// The outline about the body's center, unturned, in order around it.
        let vertices: [SIMD2<Double>]
        let inverseMass: Double
        let inverseInertia: Double
        let friction: Double
        let restitution: Double

        init(
            center: SIMD2<Double>,
            angle: Double = 0,
            size: SIMD2<Double>,
            radius: Double,
            isStatic: Bool = false,
            friction: Double = 0.55,
            restitution: Double = 0.18
        ) {
            position = center
            self.angle = angle
            vertices = Self.outline(size: size, radius: radius)
            self.friction = friction
            self.restitution = restitution
            if isStatic {
                inverseMass = 0
                inverseInertia = 0
            } else {
                // Density chosen so a node weighs about one unit per square
                // point; only the ratios matter.
                let mass = size.x * size.y
                inverseMass = 1 / mass
                inverseInertia = 12 / (mass * (size.x * size.x + size.y * size.y))
            }
        }

        /// A rectangle with each corner's quarter circle followed in four
        /// segments.
        private static func outline(size: SIMD2<Double>, radius: Double) -> [SIMD2<Double>] {
            let half = size / 2
            let r = min(max(radius, 0), min(half.x, half.y))
            guard r > 0.5 else {
                return [SIMD2(-half.x, -half.y), SIMD2(half.x, -half.y), SIMD2(half.x, half.y), SIMD2(-half.x, half.y)]
            }
            let inner = half - r
            let corners: [(center: SIMD2<Double>, start: Double)] = [
                (SIMD2(inner.x, -inner.y), -Double.pi / 2),
                (SIMD2(inner.x, inner.y), 0),
                (SIMD2(-inner.x, inner.y), Double.pi / 2),
                (SIMD2(-inner.x, -inner.y), Double.pi),
            ]
            var points: [SIMD2<Double>] = []
            for corner in corners {
                for step in 0...4 {
                    let angle = corner.start + Double(step) / 4 * Double.pi / 2
                    points.append(corner.center + SIMD2(cos(angle), sin(angle)) * r)
                }
            }
            return points
        }

        func worldVertices() -> [SIMD2<Double>] {
            let c = cos(angle)
            let s = sin(angle)
            return vertices.map { SIMD2(position.x + c * $0.x - s * $0.y, position.y + s * $0.x + c * $0.y) }
        }
    }

    /// An impact worth showing: where, when, and how hard.
    struct Impact: Sendable {
        let time: Double
        let point: SIMD2<Double>
        let normal: SIMD2<Double>
        /// 0 for a touch, 1 for a hard landing.
        let strength: Double
    }

    private struct Contact {
        var position: SIMD2<Double>
        var normal: SIMD2<Double>
        var separation: Double
        var normalImpulse = 0.0
        var tangentImpulse = 0.0
        var normalMass = 0.0
        var tangentMass = 0.0
        var bias = 0.0
    }

    var bodies: [Body]
    let gravity: SIMD2<Double>
    /// What a rounded tile loses rolling and moving through air, each a
    /// fraction a second; without it a tile with big corners rolls on like
    /// a wheel.
    var angularDamping = 2.5
    var linearDamping = 0.15
    private(set) var time = 0.0
    private(set) var impacts: [Impact] = []
    private var lastImpact: [Int: Double] = [:]

    init(bodies: [Body], gravity: SIMD2<Double>) {
        self.bodies = bodies
        self.gravity = gravity
    }

    mutating func step(_ dt: Double, iterations: Int = 12) {
        for index in bodies.indices where bodies[index].inverseMass > 0 {
            bodies[index].velocity += gravity * dt
            bodies[index].velocity *= 1 / (1 + linearDamping * dt)
            bodies[index].angularVelocity *= 1 / (1 + angularDamping * dt)
        }

        var arbiters: [(a: Int, b: Int, contacts: [Contact])] = []
        for a in bodies.indices {
            for b in bodies.indices where b > a {
                guard bodies[a].inverseMass > 0 || bodies[b].inverseMass > 0 else {
                    continue
                }
                let contacts = Self.collide(bodies[a], bodies[b])
                if !contacts.isEmpty {
                    arbiters.append((a, b, contacts))
                }
            }
        }

        for index in arbiters.indices {
            prepare(&arbiters[index], dt: dt)
        }
        for _ in 0..<iterations {
            for index in arbiters.indices {
                solve(&arbiters[index])
            }
        }

        for index in bodies.indices where bodies[index].inverseMass > 0 {
            bodies[index].position += bodies[index].velocity * dt
            bodies[index].angle += bodies[index].angularVelocity * dt
        }
        time += dt
    }

    // MARK: Solving

    private mutating func prepare(_ arbiter: inout (a: Int, b: Int, contacts: [Contact]), dt: Double) {
        let a = bodies[arbiter.a]
        let b = bodies[arbiter.b]
        let restitution = max(a.restitution, b.restitution)
        var hardest = 0.0
        var hardestContact: Contact?
        for index in arbiter.contacts.indices {
            var contact = arbiter.contacts[index]
            let r1 = contact.position - a.position
            let r2 = contact.position - b.position
            let n = contact.normal
            let t = SIMD2(n.y, -n.x)
            let rn1 = simd_dot(r1, n)
            let rn2 = simd_dot(r2, n)
            contact.normalMass = 1 / (a.inverseMass + b.inverseMass
                + a.inverseInertia * (simd_dot(r1, r1) - rn1 * rn1)
                + b.inverseInertia * (simd_dot(r2, r2) - rn2 * rn2))
            let rt1 = simd_dot(r1, t)
            let rt2 = simd_dot(r2, t)
            contact.tangentMass = 1 / (a.inverseMass + b.inverseMass
                + a.inverseInertia * (simd_dot(r1, r1) - rt1 * rt1)
                + b.inverseInertia * (simd_dot(r2, r2) - rt2 * rt2))
            // Push apart what overlaps beyond a small slop.
            contact.bias = -0.2 / dt * min(0, contact.separation + 0.4)
            // Bounce back what arrives fast enough.
            let approach = simd_dot(Self.relativeVelocity(a, b, r1, r2), n)
            if approach < -80 {
                contact.bias = max(contact.bias, -restitution * approach)
            }
            if -approach > hardest {
                hardest = -approach
                hardestContact = contact
            }
            arbiter.contacts[index] = contact
        }
        // Remember hard arrivals, once per pair while they settle.
        if hardest > 160, let contact = hardestContact {
            let key = arbiter.a * 64 + arbiter.b
            if time - (lastImpact[key] ?? -1) > 0.18 {
                lastImpact[key] = time
                impacts.append(Impact(
                    time: time,
                    point: contact.position,
                    normal: contact.normal,
                    strength: min(hardest / 1400, 1)
                ))
            }
        }
    }

    private mutating func solve(_ arbiter: inout (a: Int, b: Int, contacts: [Contact])) {
        var a = bodies[arbiter.a]
        var b = bodies[arbiter.b]
        let friction = (a.friction * b.friction).squareRoot()
        for index in arbiter.contacts.indices {
            var contact = arbiter.contacts[index]
            let r1 = contact.position - a.position
            let r2 = contact.position - b.position
            let n = contact.normal

            let vn = simd_dot(Self.relativeVelocity(a, b, r1, r2), n)
            var dPn = contact.normalMass * (-vn + contact.bias)
            let previousNormal = contact.normalImpulse
            contact.normalImpulse = max(previousNormal + dPn, 0)
            dPn = contact.normalImpulse - previousNormal
            Self.apply(n * dPn, at: r1, r2, to: &a, &b)

            let t = SIMD2(n.y, -n.x)
            let vt = simd_dot(Self.relativeVelocity(a, b, r1, r2), t)
            var dPt = -contact.tangentMass * vt
            let limit = friction * contact.normalImpulse
            let previousTangent = contact.tangentImpulse
            contact.tangentImpulse = min(max(previousTangent + dPt, -limit), limit)
            dPt = contact.tangentImpulse - previousTangent
            Self.apply(t * dPt, at: r1, r2, to: &a, &b)

            arbiter.contacts[index] = contact
        }
        bodies[arbiter.a] = a
        bodies[arbiter.b] = b
    }

    private static func relativeVelocity(_ a: Body, _ b: Body, _ r1: SIMD2<Double>, _ r2: SIMD2<Double>) -> SIMD2<Double> {
        b.velocity + cross(b.angularVelocity, r2) - a.velocity - cross(a.angularVelocity, r1)
    }

    private static func apply(_ impulse: SIMD2<Double>, at r1: SIMD2<Double>, _ r2: SIMD2<Double>, to a: inout Body, _ b: inout Body) {
        a.velocity -= impulse * a.inverseMass
        a.angularVelocity -= a.inverseInertia * cross(r1, impulse)
        b.velocity += impulse * b.inverseMass
        b.angularVelocity += b.inverseInertia * cross(r2, impulse)
    }

    private static func cross(_ w: Double, _ r: SIMD2<Double>) -> SIMD2<Double> {
        SIMD2(-w * r.y, w * r.x)
    }

    private static func cross(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> Double {
        a.x * b.y - a.y * b.x
    }

    // MARK: Collision

    /// Contacts between two convex polygons, the normal pointing from `a`
    /// to `b`.
    private static func collide(_ a: Body, _ b: Body) -> [Contact] {
        let polygonA = Polygon(a.worldVertices())
        let polygonB = Polygon(b.worldVertices())
        let (edgeA, separationA) = maxSeparation(polygonA, polygonB)
        if separationA > 0 {
            return []
        }
        let (edgeB, separationB) = maxSeparation(polygonB, polygonA)
        if separationB > 0 {
            return []
        }

        // The reference face is the one that separates best, preferring
        // `a`'s so the choice does not flicker between nearly equal faces.
        let flip = separationB > separationA + 0.05
        let reference = flip ? polygonB : polygonA
        let incident = flip ? polygonA : polygonB
        let edge = flip ? edgeB : edgeA

        let v1 = reference.vertices[edge]
        let v2 = reference.vertices[(edge + 1) % reference.vertices.count]
        let tangent = simd_normalize(v2 - v1)
        let normal = reference.normals[edge]

        // The incident edge: the one facing most against the reference
        // normal.
        var incidentEdge = 0
        var lowest = Double.infinity
        for index in incident.normals.indices {
            let d = simd_dot(normal, incident.normals[index])
            if d < lowest {
                lowest = d
                incidentEdge = index
            }
        }
        let points = [
            incident.vertices[incidentEdge],
            incident.vertices[(incidentEdge + 1) % incident.vertices.count],
        ]

        let clipped = clip(points, normal: -tangent, offset: -simd_dot(tangent, v1))
        guard clipped.count >= 2 else {
            return []
        }
        let inside = clip(clipped, normal: tangent, offset: simd_dot(tangent, v2))
        guard inside.count >= 2 else {
            return []
        }

        let front = simd_dot(normal, v1)
        var contacts: [Contact] = []
        for point in inside.prefix(2) {
            let separation = simd_dot(normal, point) - front
            if separation <= 0 {
                contacts.append(Contact(
                    // Halfway between the two surfaces.
                    position: point - normal * (separation / 2),
                    normal: flip ? -normal : normal,
                    separation: separation
                ))
            }
        }
        return contacts
    }

    private struct Polygon {
        let vertices: [SIMD2<Double>]
        /// Each edge's outward normal, edge `i` running from vertex `i` to
        /// the next.
        let normals: [SIMD2<Double>]

        init(_ vertices: [SIMD2<Double>]) {
            self.vertices = vertices
            let centroid = vertices.reduce(.zero, +) / Double(vertices.count)
            normals = vertices.indices.map { index in
                let edge = vertices[(index + 1) % vertices.count] - vertices[index]
                var n = simd_normalize(SIMD2(edge.y, -edge.x))
                if simd_dot(n, vertices[index] - centroid) < 0 {
                    n = -n
                }
                return n
            }
        }
    }

    /// The edge of `a` along which `b` lies furthest out, and how far.
    private static func maxSeparation(_ a: Polygon, _ b: Polygon) -> (Int, Double) {
        var best = 0
        var bestSeparation = -Double.infinity
        for index in a.normals.indices {
            let n = a.normals[index]
            let v = a.vertices[index]
            var deepest = Double.infinity
            for point in b.vertices {
                deepest = min(deepest, simd_dot(n, point - v))
            }
            if deepest > bestSeparation {
                bestSeparation = deepest
                best = index
            }
        }
        return (best, bestSeparation)
    }

    private static func clip(_ points: [SIMD2<Double>], normal: SIMD2<Double>, offset: Double) -> [SIMD2<Double>] {
        let d0 = simd_dot(normal, points[0]) - offset
        let d1 = simd_dot(normal, points[1]) - offset
        var out: [SIMD2<Double>] = []
        if d0 <= 0 {
            out.append(points[0])
        }
        if d1 <= 0 {
            out.append(points[1])
        }
        if d0 * d1 < 0 {
            out.append(points[0] + (points[1] - points[0]) * (d0 / (d0 - d1)))
        }
        return out
    }
}
