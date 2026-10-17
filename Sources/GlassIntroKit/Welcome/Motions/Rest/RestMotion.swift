//===--- RestMotion.swift - GlassIntroKit -----------------------------------===//
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

/// The last page, which asks to begin: nothing but its light.
///
/// There is no picture to draw. The picture before gathers into the seed,
/// and the seed shrinks away beneath this one, so the page's own light is
/// all that is left. The motion is at rest as soon as the seed is gone.
nonisolated struct RestMotion: PageMotion {
    let context: IntroContext

    /// Whatever came before dissolves where it is.
    static func continues(from handoff: IntroHandoff) -> Bool {
        false
    }

    static var arrivesEmpty: Bool {
        true
    }

    init(entry: IntroEntry, context: IntroContext) {
        self.context = context
    }

    var settleTime: Double {
        0
    }

    var textTime: Double {
        0
    }

    var absorbsSeed: Bool {
        true
    }

    func frame(at time: Double, interaction: IntroInteraction) -> IntroFrame {
        IntroFrame()
    }
}
