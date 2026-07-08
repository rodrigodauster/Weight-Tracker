//
//  DataView.swift
//  Weight Tracker
//
//  Created by Rodrigo Dauster on 21/02/2026.
//

import SwiftUI
import SwiftData

struct DataView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    
    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No entries",
                        systemImage: "list.bullet",
                        description: Text("Add a weight entry to see it here.")
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            DataRowView(entry: entry)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("Data")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = entries[index]
            context.delete(entry)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }
}

struct DataRowView: View {
    let entry: WeightEntry
    
    private var displayWeight: String {
        // Always display in kg (convert if needed)
        return String(format: "%.1f kg", entry.weightKg)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayWeight)
                    .font(.headline)
                Text(entry.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.date, style: .time)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ModelPreview(entries: [
        WeightEntry(weightKg: 70.0, isKg: true, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!),
        WeightEntry(weightKg: 70.4, isKg: true, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        WeightEntry(weightKg: 69.8, isKg: true, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    ]) {
        DataView()
    }
}
