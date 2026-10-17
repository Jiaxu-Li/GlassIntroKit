//===--- WelcomeContent.swift - GlassIntroKit -------------------------------===//
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

/// What the welcome shows, resolved from an intro: its pages, the last page
/// that asks to begin, and how each picture is told what it needs.
struct WelcomeContent {
    let pages: [GlassIntroPage]
    let mark: GlassIntroMark
    let finale: [String]
    let startTitle: Text
    let startButton: Text
    let continueButton: Text

    init(_ intro: GlassIntro) {
        pages = intro.pages
        mark = intro.mark
        finale = Array(intro.finale.prefix(FinaleReveal.maximumWordCount))
        startTitle = intro.startTitle
        startButton = intro.startButton
        continueButton = intro.continueButton
    }

    /// The index of the last page, the one that asks to begin.
    var readyIndex: Int {
        pages.count
    }

    var pageCount: Int {
        pages.count + 1
    }

    /// The picture page `index` turns to; past the pages, the last page's.
    func picture(at index: Int) -> IntroPicture {
        index < pages.count ? .page(pages[index].visual) : .rest
    }

    /// The symbol the mark melts into on page `index`: the page's own, or
    /// the mark's.
    func centerSymbol(at index: Int) -> String? {
        guard index < pages.count, pages[index].visual == .symbols else {
            return nil
        }
        return pages[index].centerSymbol ?? mark.symbolName
    }

    /// What page `index` shows if it is a scene page.
    func sceneLook(at index: Int) -> SceneLook {
        guard index < pages.count, pages[index].visual == .scene else {
            return .standard
        }
        let page = pages[index]
        return SceneLook(page.scene, customPage: page.customContent == nil ? nil : index)
    }

    /// What the picture for page `index` is told.
    func context(
        page index: Int,
        canvas: IntroCanvas,
        outlines: [String: Path],
        textTop: CGFloat?
    ) -> IntroContext {
        IntroContext(
            canvas: canvas,
            markOutline: mark.outline,
            outlines: outlines,
            page: index,
            symbols: index < pages.count ? pages[index].symbols : [],
            centerSymbol: centerSymbol(at: index),
            graph: index < pages.count ? pages[index].graph : nil,
            scene: sceneLook(at: index),
            markSymbol: mark.symbolName,
            words: finale,
            textTop: textTop ?? canvas.size.height * 0.7
        )
    }

    /// Every symbol traced into an outline for glass: the mark's own, and
    /// each symbols page's center and scattered symbols.
    var tracedSymbols: [String] {
        var names: [String] = []
        if let symbol = mark.symbolName {
            names.append(symbol)
        }
        for index in pages.indices where pages[index].visual == .symbols {
            if let center = centerSymbol(at: index) {
                names.append(center)
            }
            names.append(contentsOf: pages[index].symbols)
        }
        var seen = Set<String>()
        return names.filter { seen.insert($0).inserted }
    }
}
