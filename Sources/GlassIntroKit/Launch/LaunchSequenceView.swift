//===--- LaunchSequenceView.swift - GlassIntroKit ---------------------------===//
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
#if os(macOS)
import AppKit
#endif

/// The launch, drawn over the app's content: the cover that hides the
/// content until the stage closes, the frosted glass the mark rests on,
/// the stage itself, and the welcome when it plays.
///
/// The sequence reports its phase through `phase`, and the content takes
/// its part from it, so the content is never rebuilt by the launch.
struct LaunchSequenceView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let intro: GlassIntro
    let mode: LaunchSequenceMode
    /// The window the launch plays in.
    let canvasSize: CGSize
    /// Plays the welcome once the mark has formed, before the mark dissolves
    /// over the app.
    let presentsWelcome: Bool
    /// Incremented to skip the launch.
    let skipRequest: Int
    @Binding var phase: LaunchPresentationPhase
    let onCompletion: @MainActor () -> Void

    @State private var stage: OpeningStageProperties
    @State private var sequenceGeneration = 0
    @State private var hasCompleted = false
    @State private var isPresentingWelcome = false
    @State private var welcomeContinuation: CheckedContinuation<Void, Never>?
    /// Whether the mark has come up, when the launch opens straight from it.
    @State private var isMarkShown: Bool

    init(
        intro: GlassIntro,
        mode: LaunchSequenceMode,
        canvasSize: CGSize,
        presentsWelcome: Bool,
        skipRequest: Int,
        phase: Binding<LaunchPresentationPhase>,
        onCompletion: @escaping @MainActor () -> Void
    ) {
        self.intro = intro
        self.mode = mode
        self.canvasSize = canvasSize
        self.presentsWelcome = presentsWelcome
        self.skipRequest = skipRequest
        _phase = phase
        self.onCompletion = onCompletion
        // Opening on the mark, the very first frame is already the closed
        // stage, with the mark still to come up: the launch colour never
        // shows.
        let opensOnMark = intro.opening == .mark
        _stage = State(initialValue: opensOnMark ? .settled(at: .logo) : OpeningStageProperties())
        _isMarkShown = State(initialValue: !opensOnMark)
    }

    var body: some View {
        let presentation = LaunchWorkspacePresentation(
            phase: phase,
            reducesMotion: accessibilityReduceMotion
        )

        ZStack {
            if !accessibilityReduceMotion, phase != .complete {
                coverAndGlass(presentation)
                OpeningStage(
                    properties: stage,
                    canvasSize: canvasSize,
                    mark: intro.mark,
                    tint: intro.tint
                )
                // The welcome draws the mark itself while it plays.
                .opacity(isPresentingWelcome || !isMarkShown ? 0 : 1)
                .scaleEffect(isMarkShown ? 1 : 0.86)
            }
            if isPresentingWelcome {
                WelcomeView(
                    content: WelcomeContent(intro),
                    canvasSize: canvasSize,
                    reducesMotion: accessibilityReduceMotion,
                    onFinish: finishWelcome
                )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .task(id: sequenceGeneration) {
            guard !hasCompleted else {
                return
            }
            await runSequence()
        }
        .onChange(of: skipRequest) {
            skipSequence()
        }
    }

    @ViewBuilder
    private func coverAndGlass(_ presentation: LaunchWorkspacePresentation) -> some View {
        // Clicks are held back here rather than with allowsHitTesting(false)
        // on the content, which would keep a split view from receiving the
        // title bar's safe area until the launch ends.
        if !presentation.isWorkspaceAvailable {
            Color.clear
                .contentShape(.rect)
        }

        Rectangle()
            .fill(intro.background)
            .opacity(presentation.workspaceCoverOpacity)
            .animation(.easeInOut(duration: 0.35), value: presentation.workspaceCoverOpacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

        LaunchFrostedGlass()
            .opacity(presentation.frostedGlassOpacity)
            .animation(.smooth(duration: 0.50), value: presentation.frostedGlassOpacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func runSequence() async {
        switch mode {
        case .immediate:
            phase = .complete
            await Task.yield()
            completeSequence()
        case .full:
            if accessibilityReduceMotion {
                await runReducedMotionSequence()
            } else {
                await runFullSequence()
            }
        }
    }

    private func runFullSequence() async {
        do {
            switch intro.opening {
            case .stage:
                _ = advance(to: .construction)
                for step in OpeningTimeline.construction {
                    try await animateStage(after: step.delay, step.animation, step.change)
                }
                _ = advance(to: .logo)
            case .mark:
                try await openOnMark()
            }

            // The mark rests on frosted glass for a moment before anything
            // carries on.
            try await Task.sleep(for: .milliseconds(900))
            try Task.checkCancellation()
            // The welcome plays here, over the full window, and hands the
            // mark back where it found it.
            await presentWelcomeIfNeeded()
            try Task.checkCancellation()
            _ = advance(to: .settling)

            try await Task.sleep(for: .milliseconds(220))
            try Task.checkCancellation()
            _ = advance(to: .handoffApproach)
            // The mark and the frosted glass clear together, softly, and the
            // app is handed over once they have actually gone.
            await animateStageUntilSettled(.timingCurve(0.3, 0, 0.15, 1, duration: 0.62)) {
                $0.dissolvesMark = true
            }
            try Task.checkCancellation()

            _ = advance(to: .handoff)
            try await Task.sleep(for: .milliseconds(120))
            try Task.checkCancellation()

            settleAtCompletePhase()
            completeSequence()
        } catch {
            return
        }
    }

    /// Starts on the closed stage: the mark comes up on the frosted glass,
    /// the app already in place beneath it.
    private func openOnMark() async throws {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            _ = advance(to: .logo)
        }
        try await Task.sleep(for: .milliseconds(150))
        try Task.checkCancellation()
        withAnimation(.smooth(duration: 0.55)) {
            isMarkShown = true
        }
        try await Task.sleep(for: .milliseconds(450))
        try Task.checkCancellation()
    }

    private func animateStage(
        after delay: Double,
        _ animation: Animation,
        _ change: (inout OpeningStageProperties) -> Void
    ) async throws {
        try await Task.sleep(for: .seconds(delay))
        try Task.checkCancellation()
        withAnimation(animation) {
            change(&stage)
        }
    }

    private func animateStageUntilSettled(
        _ animation: Animation,
        _ change: (inout OpeningStageProperties) -> Void
    ) async {
        await withCheckedContinuation { continuation in
            withAnimation(animation, completionCriteria: .logicallyComplete) {
                change(&stage)
            } completion: {
                continuation.resume()
            }
        }
    }

    private func runReducedMotionSequence() async {
        await presentWelcomeIfNeeded()
        guard !Task.isCancelled else {
            return
        }
        withAnimation(.easeOut(duration: 0.14)) {
            _ = advance(to: .handoff)
        }
        do {
            try await Task.sleep(for: .milliseconds(140))
            try Task.checkCancellation()
        } catch {
            return
        }
        settleAtCompletePhase()
        completeSequence()
    }

    /// Plays the welcome and returns once it has been continued past.
    private func presentWelcomeIfNeeded() async {
        guard presentsWelcome, !Task.isCancelled else {
            return
        }
        await withCheckedContinuation { continuation in
            welcomeContinuation = continuation
            isPresentingWelcome = true
        }
    }

    /// Records the welcome as shown, whether it was continued past or
    /// skipped while it played, so it does not return.
    private func finishWelcome() {
        guard isPresentingWelcome else {
            return
        }
        intro.storage.hasSeenWelcome = true
        isPresentingWelcome = false
        welcomeContinuation?.resume()
        welcomeContinuation = nil
    }

    private func skipSequence() {
        guard !hasCompleted else {
            return
        }
        finishWelcome()
        sequenceGeneration &+= 1
        settleAtCompletePhase()
        completeSequence()
    }

    private func advance(to nextPhase: LaunchPresentationPhase) -> Bool {
        guard phase.rawValue < nextPhase.rawValue else {
            return false
        }
        phase = nextPhase
        return true
    }

    private func settleAtCompletePhase() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            phase = .complete
            stage = .settled(at: .complete)
        }
    }

    private func completeSequence() {
        guard !hasCompleted else {
            return
        }
        hasCompleted = true
        onCompletion()
    }
}

#if os(macOS)
/// Frosted glass that blurs the desktop behind the window.
private struct LaunchBehindWindowGlass: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#endif

/// The frosted layer the mark rests on: the blurred desktop behind the
/// window on macOS, and blurred content elsewhere.
private struct LaunchFrostedGlass: View {
    var body: some View {
        #if os(macOS)
        LaunchBehindWindowGlass()
        #else
        Rectangle()
            .fill(.regularMaterial)
        #endif
    }
}
