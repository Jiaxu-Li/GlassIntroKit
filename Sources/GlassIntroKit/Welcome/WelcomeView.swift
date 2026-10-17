//===--- WelcomeView.swift - GlassIntroKit ----------------------------------===//
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

/// The welcome, played over the launch once the mark has formed, a page at
/// a time.
///
/// Black closes in behind the mark and the first page's picture grows out
/// of it while the page's light rises out of the black. Each Continue turns
/// to the next page's picture: straight on, when the two belong together,
/// or through a drop of glass the one gathers into and the next grows out
/// of. The last page asks to begin; beginning plays the ending, which
/// leaves the mark in colour exactly where the launch takes it from.
///
/// The view keeps the clock and the text; `WelcomePlayer` decides what the
/// picture is at each moment, and `IntroFrameView` draws it.
struct WelcomeView: View {
    let content: WelcomeContent
    let canvasSize: CGSize
    let reducesMotion: Bool
    let onFinish: @MainActor () -> Void

    @State var player: WelcomePlayer?
    /// When the welcome's clock reads zero.
    @State var clockOrigin = Date.now
    @State var revealedPage: Int?
    @State var isBusy = true
    @State var isMoving = true
    @State var isInteractive = false
    @State var backdropPage = 0
    @State var blackOpacity = 0.0
    @State var pictureOpacity = 0.0
    @State var pictureScale: CGFloat = 1.08
    @State var pictureBlur: CGFloat = 24
    /// Every traced symbol glass takes the shape of.
    @State var outlines: [String: Path] = [:]
    /// The top of each page's text, where pictures keep clear of it.
    @State var textTops: [Int: CGFloat] = [:]
    /// The highest of the text tops, taken when the pictures are laid out,
    /// so every picture shares one center.
    @State var stageBottom: CGFloat?
    /// The cube's turn added by dragging it.
    @State var yawOffset = 0.0
    @State var yawAtDragStart = 0.0
    @State var isFinishing = false
    /// The page whose picture was turned to last; -1 before the first.
    @State var currentPage = -1
    /// Lays the picture out again once the window stops changing size.
    @State var resizeTask: Task<Void, Never>?

    nonisolated static let coordinateSpace = "welcome"

    var body: some View {
        ZStack {
            Color.black
                .opacity(blackOpacity)

            backdrop

            TimelineView(.animation(paused: !isMoving)) { context in
                if let player {
                    let time = clock(at: context.date)
                    // A picture is drawn on the canvas it was laid out for,
                    // fitted to the window, so a window resized mid-turn
                    // never leaves part of it outside. It is laid out again
                    // once it is at rest.
                    let laidOut = player.canvas(at: time).size
                    IntroFrameView(
                        frame: player.frame(at: time, interaction: interaction),
                        canvasSize: laidOut,
                        content: content
                    )
                    .scaleEffect(min(canvasSize.width / laidOut.width, canvasSize.height / laidOut.height))
                    .frame(width: canvasSize.width, height: canvasSize.height)
                }
            }
            .allowsHitTesting(false)

            dragSurface

            ZStack(alignment: .bottom) {
                ForEach(content.pages.indices, id: \.self) { index in
                    WelcomePageText(
                        page: content.pages[index],
                        index: index,
                        pageCount: content.pageCount,
                        continueButton: content.continueButton,
                        isRevealed: revealedPage == index,
                        isEnabled: !isBusy,
                        isCompact: isCompact,
                        onContinue: { advance(from: index) },
                        onTopChange: { textTops[index] = $0 }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, isCompact ? 36 : 56)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            WelcomeReadyText(
                index: content.readyIndex,
                pageCount: content.pageCount,
                title: content.startTitle,
                button: content.startButton,
                isRevealed: revealedPage == content.readyIndex,
                isEnabled: !isBusy,
                isCompact: isCompact,
                onBegin: beginFinale
            )
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .coordinateSpace(.named(Self.coordinateSpace))
        .clipped()
        .task {
            await start()
        }
        .onChange(of: canvasSize) {
            scheduleLayout()
        }
    }

    /// Each page's light, the picture rising out of the black at the start.
    private var backdrop: some View {
        let styles = content.backdropStyles
        return ZStack {
            WelcomeBackdrop(styles: styles, page: backdropPage, reducesMotion: reducesMotion)
                .scaleEffect(pictureScale)
                .blur(radius: reducesMotion ? 0 : pictureBlur)
            BottomSoftening {
                WelcomeBackdrop(styles: styles, page: backdropPage, reducesMotion: reducesMotion)
                    .scaleEffect(pictureScale)
            }
            .blur(radius: reducesMotion ? 0 : pictureBlur)
        }
        .opacity(pictureOpacity)
    }

    /// Dragging across a picture that can be turned turns it.
    @ViewBuilder
    private var dragSurface: some View {
        #if !os(tvOS)
        if isInteractive, !reducesMotion {
            Color.clear
                .contentShape(.rect)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            yawOffset = yawAtDragStart + value.translation.width * 0.01
                        }
                        .onEnded { _ in
                            yawAtDragStart = yawOffset
                        }
                )
        }
        #endif
    }

    var isCompact: Bool {
        canvasSize.width < 640
    }

    var interaction: IntroInteraction {
        IntroInteraction(yawOffset: yawOffset, reducesMotion: reducesMotion)
    }

    var canvas: IntroCanvas {
        IntroCanvas(size: canvasSize, bodyDiameterRatio: content.mark.bodyDiameterRatio, stageBottom: stageBottom)
    }

    /// The welcome's clock at `date`.
    func clock(at date: Date) -> Double {
        date.timeIntervalSince(clockOrigin)
    }
}

extension WelcomeContent {
    /// What each page shows behind its picture, the last page included.
    var backdropStyles: [BackdropStyle] {
        pages.map { BackdropStyle($0.background, picture: .page($0.visual)) }
            + [BackdropStyle(.automatic, picture: .rest)]
    }
}
