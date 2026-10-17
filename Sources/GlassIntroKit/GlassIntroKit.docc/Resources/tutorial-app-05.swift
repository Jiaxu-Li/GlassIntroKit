import GlassIntroKit
import SwiftUI

@main
struct OrbitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .glassIntro(
                    appName: "Orbit",
                    pages: [
                        .greeting("Welcome to Orbit", message: "Plan trips with the people you travel with."),
                        .mark("Simple, by Design", message: "One calm place for every plan."),
                        .symbols(
                            "Everything in Reach",
                            message: "Maps, photos, and notes gather around each trip.",
                            symbols: ["map.fill", "airplane", "photo.fill", "music.note", "camera.fill", "fork.knife"]
                        ),
                        .scene(
                            "Seen in Depth",
                            message: "A live 3D preview. Drag to turn it.",
                            scene: GlassIntroScene(shape: .cube, motion: .turntable)
                        ),
                        .graph(
                            "Connected",
                            message: "A change in one plan updates the rest.",
                            graph: .branch("airplane.departure", into: ["bed.double.fill", "fork.knife"])
                        ),
                        .physics("Feels Real", message: "Everything responds the way you expect."),
                    ]
                )
        }
    }
}
