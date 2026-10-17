import GlassIntroKit
import SwiftUI

struct ContentView: View {
    @State private var showsIntro = false

    var body: some View {
        NavigationStack {
            Text("Your trips")
                .navigationTitle("Orbit")
                .toolbar {
                    Button("Show the Intro", systemImage: "play.circle") {
                        showsIntro = true
                    }
                }
        }
        .glassIntro(Self.intro, isPresented: $showsIntro)
    }

    static let intro = GlassIntro(
        appName: "Orbit",
        pages: [
            .greeting("Welcome to Orbit", message: "Plan trips with the people you travel with."),
            .icon("Ready When You Are", message: "Packed and ready to go.", symbol: "suitcase.rolling.fill"),
        ],
        finale: ["Have a", "good trip"]
    )
}
