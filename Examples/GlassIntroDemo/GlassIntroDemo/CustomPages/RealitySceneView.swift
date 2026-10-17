//===--- RealitySceneView.swift - GlassIntroKit -----------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

import RealityKit
import SwiftUI

/// A scene page's own view, made with RealityKit: a small planet with a
/// moon, lit and turning. Any `RealityView` can stand here.
struct RealitySceneView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.08, blue: 0.2), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            RealityView { content in
                content.camera = .virtual
                let world = Entity()

                let planet = ModelEntity(
                    mesh: .generateSphere(radius: 0.16),
                    materials: [SimpleMaterial(color: Self.platformColor(red: 0.2, green: 0.55, blue: 0.95), roughness: 0.35, isMetallic: false)]
                )
                let band = ModelEntity(
                    mesh: .generateCylinder(height: 0.008, radius: 0.27),
                    materials: [SimpleMaterial(color: Self.platformColor(red: 0.95, green: 0.8, blue: 0.55), roughness: 0.2, isMetallic: true)]
                )
                band.orientation = simd_quatf(angle: 0.35, axis: [1, 0, 0])
                let moon = ModelEntity(
                    mesh: .generateBox(size: 0.07, cornerRadius: 0.02),
                    materials: [SimpleMaterial(color: Self.platformColor(red: 0.92, green: 0.92, blue: 0.95), roughness: 0.5, isMetallic: false)]
                )
                moon.position = [0.36, 0.05, 0]
                let orbit = Entity()
                orbit.addChild(moon)

                world.addChild(planet)
                world.addChild(band)
                world.addChild(orbit)
                // The pictures' center sits a little above the middle.
                world.position = [0, 0.06, 0]
                content.add(world)

                let light = DirectionalLight()
                light.light.intensity = 3000
                light.look(at: .zero, from: [-0.6, 0.8, 0.8], relativeTo: nil)
                content.add(light)

                let camera = PerspectiveCamera()
                camera.look(at: [0, 0.02, 0], from: [0, 0.26, 1.7], relativeTo: nil)
                content.add(camera)

                Self.spin(world, every: 14)
                Self.spin(orbit, every: 4)
            }
        }
    }

    /// Turns `entity` about the vertical once every `seconds`, for good.
    private static func spin(_ entity: Entity, every seconds: Double) {
        let half = FromToByAnimation<Transform>(
            from: Transform(rotation: simd_quatf(angle: 0, axis: [0, 1, 0]), translation: entity.position),
            to: Transform(rotation: simd_quatf(angle: .pi, axis: [0, 1, 0]), translation: entity.position),
            duration: seconds / 2,
            timing: .linear,
            bindTarget: .transform,
            repeatMode: .cumulative
        )
        if let animation = try? AnimationResource.generate(with: half) {
            entity.playAnimation(animation)
        }
    }

    private static func platformColor(red: Double, green: Double, blue: Double) -> SimpleMaterial.Color {
        SimpleMaterial.Color(red: red, green: green, blue: blue, alpha: 1)
    }
}
