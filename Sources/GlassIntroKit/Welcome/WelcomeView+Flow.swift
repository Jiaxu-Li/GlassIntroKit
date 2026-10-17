//===--- WelcomeView+Flow.swift - GlassIntroKit -----------------------------===//
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

/// How the welcome moves from page to page: the player decides the
/// picture; this keeps the text, the light, and the clock in step with it.
extension WelcomeView {
    /// Starts from the mark as the launch left it and turns to the first
    /// page.
    func start() async {
        // The mark is drawn at once, exactly where the launch leaves it, and
        // rests while symbols are traced; nothing moves until they are.
        clockOrigin = .now
        player = WelcomePlayer(resting: LaunchMotion(entry: .seed, context: context(for: 0)))
        outlines = await SymbolOutlines.outlines(for: content.tracedSymbols)
        // By now every page's text has been laid out; the pictures are
        // centered above the highest of it. The mark itself stays put.
        stageBottom = textTops.values.min()
        clockOrigin = .now
        player = WelcomePlayer(resting: LaunchMotion(entry: .seed, context: context(for: 0)))

        withAnimation(.easeInOut(duration: reducesMotion ? 0.35 : 0.6)) {
            blackOpacity = 1
        }
        let turn = turn(to: 0, at: 0)
        if reducesMotion {
            withAnimation(.easeOut(duration: 0.35)) {
                riseLight()
            }
        } else {
            // The light rises out of the black as the first picture forms.
            let rise = max(turn.textTime - 2.8, 0.6)
            Task {
                try? await Task.sleep(for: .seconds(rise))
                withAnimation(.easeInOut(duration: 3.0)) {
                    riseLight()
                }
            }
        }
        await settle(on: 0, after: turn)
    }

    /// Turns from page `index` to the next, or to the last page.
    func advance(from index: Int) {
        guard !isBusy, revealedPage == index, player != nil else {
            return
        }
        let next = index + 1
        isBusy = true
        revealedPage = nil
        withAnimation(.timingCurve(0.45, 0, 0.25, 1, duration: reducesMotion ? 0.4 : 2.2)) {
            backdropPage = next
        }
        let turn = turn(to: next, at: clock(at: .now))
        Task {
            await settle(on: next, after: turn)
        }
    }

    /// The ending: the words, the black, and the mark filling with colour
    /// where the launch takes it from.
    func beginFinale() {
        guard !isBusy, !isFinishing, revealedPage == content.readyIndex, var player else {
            return
        }
        isBusy = true
        isFinishing = true
        revealedPage = nil
        let now = clock(at: .now)
        let context = context(for: content.readyIndex)
        let turn = player.turn(
            at: now,
            interaction: interaction,
            continues: IntroPicture.finale.continues(from:),
            build: { entry in IntroPicture.finale.motion(entry: entry, context: context) }
        )
        self.player = player
        isMoving = true
        isInteractive = false
        let blackTime = (player.current.motion as? FinaleMotion)?.blackTime ?? 0
        let finaleStart = player.current.start
        Task {
            try? await Task.sleep(for: .seconds(max(finaleStart + blackTime - now, 0)))
            withAnimation(.easeInOut(duration: reducesMotion ? 0.3 : 0.8)) {
                pictureOpacity = 0
            }
            try? await Task.sleep(for: .seconds(max(turn.settleTime - clock(at: .now), reducesMotion ? 0.6 : 0)))
            // The black gives way to the launch, the mark staying exactly
            // where the launch draws it.
            withAnimation(.easeInOut(duration: reducesMotion ? 0.2 : 0.5)) {
                blackOpacity = 0
            }
            try? await Task.sleep(for: .milliseconds(reducesMotion ? 220 : 520))
            onFinish()
        }
    }

    /// Turns the player to page `index`'s picture at `clock`.
    @discardableResult
    func turn(to index: Int, at clock: Double) -> WelcomePlayer.Turn {
        // A picture laid out for a window since resized is laid out again,
        // at rest, before the next one carries on from it.
        layOutAgainIfNeeded()
        guard var player else {
            return WelcomePlayer.Turn(textTime: clock, settleTime: clock)
        }
        currentPage = index
        let picture = content.picture(at: index)
        let context = context(for: index)
        let turn = player.turn(
            at: clock,
            interaction: interaction,
            continues: picture.continues(from:),
            arrivesEmpty: picture.arrivesEmpty,
            build: { entry in picture.motion(entry: entry, context: context) }
        )
        self.player = player
        isMoving = true
        isInteractive = false
        return turn
    }

    /// Shows page `index`'s text once its picture brings it in, and lets the
    /// page be turned from then on.
    func settle(on index: Int, after turn: WelcomePlayer.Turn) async {
        let minimum = reducesMotion ? 0.3 : 0.35
        try? await Task.sleep(for: .seconds(max(turn.textTime - clock(at: .now), minimum)))
        guard !isFinishing else {
            return
        }
        revealedPage = index
        isBusy = false
        try? await Task.sleep(for: .seconds(max(turn.settleTime - clock(at: .now), 0) + 0.05))
        layOutAgainIfNeeded()
        updateMotion()
    }

    /// Pauses the clock once nothing moves, and lets a picture that can be
    /// turned by dragging be turned.
    func updateMotion() {
        guard let player else {
            return
        }
        let now = clock(at: .now)
        isMoving = player.isMoving(at: now, interaction: interaction)
        isInteractive = player.isInteractive(at: now)
    }

    /// Lays the picture out again for the window's new size once it stops
    /// changing; a picture still moving is laid out again when it comes to
    /// rest.
    func scheduleLayout() {
        resizeTask?.cancel()
        resizeTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled, let player, player.isAtRest(at: clock(at: .now)) else {
                return
            }
            layOutAgainIfNeeded()
            updateMotion()
        }
    }

    /// Lays the current picture out again, at rest, if it was laid out for
    /// a window of another size: pictures are laid out for the canvas they
    /// began on.
    func layOutAgainIfNeeded() {
        // Before the first page, the launch's mark rests where it is.
        guard var player, !isFinishing, currentPage >= 0 else {
            return
        }
        stageBottom = textTops.values.min()
        guard player.current.motion.context.canvas != canvas else {
            return
        }
        // A picture that carried on from the one before is laid out
        // carrying on from that one, itself laid out again, so the graph's
        // own nodes still fall, and the fallen nodes still become the icon.
        let continued: Bool
        if case .handoff = player.current.entry {
            continued = true
        } else {
            continued = false
        }
        let resting = content.restingMotion(
            for: currentPage,
            carriesOn: continued,
            interaction: interaction,
            context: context(for:)
        )
        player.rebuildAtRest(at: clock(at: .now), motion: resting.motion, entry: resting.entry)
        self.player = player
    }

    /// What page `index`'s picture is told.
    func context(for index: Int) -> IntroContext {
        content.context(page: index, canvas: canvas, outlines: outlines, textTop: textTops[index])
    }

    private func riseLight() {
        pictureOpacity = 1
        pictureScale = 1
        pictureBlur = 0
    }
}
