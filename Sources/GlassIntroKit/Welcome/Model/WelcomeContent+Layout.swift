//===--- WelcomeContent+Layout.swift - GlassIntroKit ------------------------===//
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

extension WelcomeContent {
    /// Page `index`'s picture at rest, laid out by `context`, for a window
    /// that has changed size.
    ///
    /// A picture that carried on from the one before is laid out carrying
    /// on from that one, itself laid out again at rest, so the graph's own
    /// nodes still fall, and the fallen nodes still become the icon.
    func restingMotion(
        for index: Int,
        carriesOn: Bool,
        interaction: IntroInteraction,
        context: (Int) -> IntroContext
    ) -> (motion: any IntroMotion, entry: IntroEntry) {
        let picture = picture(at: index)
        if carriesOn, index > 0 {
            let previous = restingMotion(for: index - 1, carriesOn: true, interaction: interaction, context: context).motion
            let handoff = previous.handoff(at: previous.settleTime, interaction: interaction)
            if picture.continues(from: handoff) {
                return (picture.motion(entry: .handoff(handoff), context: context(index)), .handoff(handoff))
            }
        }
        let entry: IntroEntry = picture.arrivesEmpty ? .empty : .seed
        return (picture.motion(entry: entry, context: context(index)), entry)
    }
}
