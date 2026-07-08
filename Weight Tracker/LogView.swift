//
//  LogView.swift
//  Weight Tracker
//
//  Created by Rodrigo Dauster on 20/02/2026.
//

import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]

    @State private var isKg: Bool = true  // Always use kg now
    @State private var integerPart: Int = 70
    @State private var decimalPart: Int = 0
    @State private var date: Date = Date()
    @State private var showDatePicker: Bool = false
    @State private var justSaved: Bool = false

    private var weightValueInCurrentUnit: Double {
        Double(integerPart) + Double(decimalPart) / 10.0
    }

    private var weightValueInKg: Double {
        // Always kg now, no conversion needed
        weightValueInCurrentUnit
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Two blank lines (vertical space)
                Spacer().frame(height: 24)
                Spacer().frame(height: 24)

                // Title Row
                HStack(alignment: .center) {
                    Text("Weight (kg)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    
                    // COMMENTED OUT: Custom unit toggle with stronger contrast
//                    HStack(spacing: 0) {
//                        Button(action: { isKg = true }) {
//                            Text("kg")
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                                .foregroundStyle(isKg ? .black : .gray.opacity(0.7))
//                                .frame(width: 70, height: 32)
//                                .background(isKg ? Color.white : Color.gray.opacity(0.2))
//                                .clipShape(UnevenRoundedRectangle(cornerRadii: .init(
//                                    topLeading: 8,
//                                    bottomLeading: 8,
//                                    bottomTrailing: 0,
//                                    topTrailing: 0
//                                )))
//                        }
//                        .buttonStyle(.plain)
//                        
//                        Button(action: { isKg = false }) {
//                            Text("lb")
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                                .foregroundStyle(!isKg ? .black : .gray.opacity(0.7))
//                                .frame(width: 70, height: 32)
//                                .background(!isKg ? Color.white : Color.gray.opacity(0.2))
//                                .clipShape(UnevenRoundedRectangle(cornerRadii: .init(
//                                    topLeading: 0,
//                                    bottomLeading: 0,
//                                    bottomTrailing: 8,
//                                    topTrailing: 8
//                                )))
//                        }
//                        .buttonStyle(.plain)
//                    }
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
//                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Rollers (wheel pickers)
                HStack(spacing: 0) {
                    Picker("Integer", selection: $integerPart) {
                        ForEach((50...100).reversed(), id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 28, weight: .regular, design: .rounded))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    Text(".")
                        .font(.system(size: 28, weight: .regular, design: .rounded))

                    Picker("Decimal", selection: $decimalPart) {
                        ForEach((0...9).reversed(), id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 28, weight: .regular, design: .rounded))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .frame(height: 160)
                .padding(.horizontal)

                // Two lines down (extra spacing)
                Spacer().frame(height: 16)
                Spacer().frame(height: 16)

                // Date row (tap to change)
                HStack {
                    Button(action: { withAnimation { showDatePicker.toggle() } }) {
                        HStack {
                            Text(date, style: .date)
                                .font(.headline)
                            Image(systemName: "chevron.down")
                                .font(.subheadline)
                                .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                                .animation(.easeInOut(duration: 0.2), value: showDatePicker)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)

                if showDatePicker {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                // Save button (only show if not just saved)
                if !justSaved {
                    Button(action: saveEntry) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.tint)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { syncUIToLastEntryIfAny() }
            .onChange(of: integerPart) { _, _ in justSaved = false }
            .onChange(of: decimalPart) { _, _ in justSaved = false }
            .onChange(of: date) { _, _ in justSaved = false }
        }
    }

    private func syncUIToLastEntryIfAny() {
        guard let last = entries.first else { return }
        isKg = last.isKg
        let valueInCurrentUnit = isKg ? last.weightKg : WeightEntry.pounds(fromKg: last.weightKg)
        let rounded = (valueInCurrentUnit * 10).rounded() / 10
        integerPart = Int(rounded)
        decimalPart = Int((rounded - Double(integerPart)) * 10)
        date = Date()
    }

    private func saveEntry() {
        // Snap to one decimal place
        let oneDecimal = (weightValueInKg * 10).rounded() / 10
        let entry = WeightEntry(weightKg: oneDecimal, isKg: isKg, date: date)
        context.insert(entry)
        do {
            try context.save()
            // Hide the Save button after successful save and reset date to current
            withAnimation {
                justSaved = true
                showDatePicker = false
                date = Date()  // Reset to current date
            }
        } catch {
            // In a production app, present an error to the user
            print("Failed to save entry: \(error)")
        }
    }
}

#Preview {
    LogView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
