//===--- CardViews.swift - GlassIntroKit ------------------------------------===//
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

/// A card page's view: a trip, day by day.
struct ItineraryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Lisbon", systemImage: "airplane.departure")
                .font(.title2.weight(.semibold))
            Divider()
            row("Fri", "Alfama walk", systemImage: "figure.walk")
            row("Sat", "Sintra day trip", systemImage: "tram.fill")
            row("Sun", "Time Out Market", systemImage: "fork.knife")
        }
        .padding(24)
        .foregroundStyle(.white)
    }

    private func row(_ day: LocalizedStringKey, _ plan: LocalizedStringKey, systemImage: String) -> some View {
        HStack {
            Text(day)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
            Label(plan, systemImage: systemImage)
            Spacer()
        }
    }
}

/// A card page's view: a week in numbers, as bars.
struct StatsCard: View {
    private let days: [(String, Double)] = [
        ("M", 0.4), ("T", 0.7), ("W", 0.55), ("T", 0.9), ("F", 0.65), ("S", 1), ("S", 0.8),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
            Text("42 km walked")
                .font(.title.weight(.bold))
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days.indices, id: \.self) { index in
                    VStack(spacing: 6) {
                        Capsule()
                            .fill(.white.opacity(index == 5 ? 1 : 0.55))
                            .frame(height: 70 * days[index].1)
                        Text(verbatim: days[index].0)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 92, alignment: .bottom)
        }
        .padding(24)
        .foregroundStyle(.white)
    }
}

/// A card page's view: a packing list.
struct ChecklistCard: View {
    private let items: [(LocalizedStringKey, Bool)] = [
        ("Passport", true), ("Chargers", true), ("Walking shoes", false), ("Sunscreen", false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Packing", systemImage: "suitcase.rolling.fill")
                .font(.title2.weight(.semibold))
            Divider()
            ForEach(items.indices, id: \.self) { index in
                Label {
                    Text(items[index].0)
                        .strikethrough(items[index].1)
                        .foregroundStyle(items[index].1 ? .secondary : .primary)
                } icon: {
                    Image(systemName: items[index].1 ? "checkmark.circle.fill" : "circle")
                }
            }
        }
        .padding(24)
        .foregroundStyle(.white)
    }
}
