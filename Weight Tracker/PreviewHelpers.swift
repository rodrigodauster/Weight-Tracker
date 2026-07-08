//
//  PreviewHelpers.swift
//  Weight Tracker
//
//  Created by Rodrigo Dauster on 20/02/2026.
//

import SwiftUI
import SwiftData

struct ModelPreview<Content: View>: View {
    let entries: [WeightEntry]
    let content: () -> Content

    var body: some View {
        content()
            .modelContainer(for: WeightEntry.self, inMemory: true)
            .overlay(Injector(entries: entries).allowsHitTesting(false))
    }

    private struct Injector: View {
        let entries: [WeightEntry]
        @Environment(\.modelContext) private var context
        @State private var didInsert = false

        var body: some View {
            Color.clear
                .onAppear {
                    guard !didInsert else { return }
                    entries.forEach { context.insert($0) }
                    do { try context.save() } catch { /* ignore in previews */ }
                    didInsert = true
                }
        }
    }
}
