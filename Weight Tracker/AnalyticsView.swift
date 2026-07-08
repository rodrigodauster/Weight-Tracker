//
//  AnalyticsView.swift
//  Weight Tracker
//
//  Created by Rodrigo Dauster on 20/02/2026.
//

import SwiftUI
import Charts
import SwiftData

enum TimeRange: String, CaseIterable, Identifiable {
    case all = "All"
    case oneYear = "1Y"
    case ytd = "YTD"
    case threeMonths = "3 Months"
    case month = "Month"

    var id: String { rawValue }
}

struct AnalyticsView: View {
    @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]
    @State private var range: TimeRange = .all

    private var filteredEntries: [WeightEntry] {
        let now = Date()
        let calendar = Calendar.current
        
        switch range {
        case .all:
            return entries
        case .oneYear:
            let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return entries.filter { $0.date >= start }
        case .ytd:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            return entries.filter { $0.date >= startOfYear }
        case .threeMonths:
            // Last three months inclusive
            // Get the first day of the month 2 months ago
            let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now) ?? now
            let startOfThreeMonthsAgo = calendar.date(from: calendar.dateComponents([.year, .month], from: twoMonthsAgo)) ?? now
            return entries.filter { $0.date >= startOfThreeMonthsAgo }
        case .month:
            // Current month only
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            return entries.filter { $0.date >= startOfMonth }
        }
    }

    private func valueForDisplay(_ entry: WeightEntry) -> Double {
        // Always display in kg now
        return entry.weightKg
    }
    
    // Calculate the stride for grid lines (5 kg)
    private var gridStride: Double {
        5.0
    }
    
    // Calculate min and max for the chart: data min-10, data max+10
    private var chartYRange: ClosedRange<Double>? {
        guard !filteredEntries.isEmpty else { return nil }
        let values = filteredEntries.map { valueForDisplay($0) }
        guard let minValue = values.min(), let maxValue = values.max() else { return nil }
        
        let minRounded = (minValue - 10.0)
        let maxRounded = (maxValue + 10.0)
        
        return minRounded...maxRounded
    }
    
    // Determine if we should use month labels (for All, 1Y, 3 Mo, YTD) or day numbers (for Month only)
    private var useMonthLabels: Bool {
        range == .all || range == .oneYear || range == .threeMonths || range == .ytd
    }
    
    // Generate day marks for "Month" view: 1, 8, 15, 22, 29
    private var monthDayMarks: [Date] {
        guard range == .month else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Get the start of the current month
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return []
        }
        
        // Get the number of days in the current month
        guard let rangeOfMonth = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        var dayMarks: [Date] = []
        
        // Generate marks at day 1, 8, 15, 22, 29
        for dayNumber in stride(from: 1, through: rangeOfMonth.count, by: 7) {
            if let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: startOfMonth) {
                dayMarks.append(date)
            }
        }
        
        return dayMarks
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Picker("Range", selection: $range) {
                    ForEach(TimeRange.allCases) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                if filteredEntries.isEmpty {
                    ContentUnavailableView(
                        "No data",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Add a weight entry to see your progress.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Chart(filteredEntries) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", valueForDisplay(entry))
                        )
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", valueForDisplay(entry))
                        )
                    }
                    // Y-axis (vertical) on the left with grid lines at 5 kg increments
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .stride(by: 5)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.gray.opacity(0.75))
                            AxisValueLabel()
                                .foregroundStyle(Color.black)
                        }
                    }
                    .chartYScale(domain: chartYRange ?? 0...100)
                    .chartYAxisLabel("kg", position: .leading)
                    // X-axis (horizontal) with conditional formatting
                    .chartXAxis {
                        if useMonthLabels {
                            // For All, 1Y, 3 Months, YTD: Show first 3 letters of month
                            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.gray.opacity(0.75))
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(date, format: .dateTime.month(.abbreviated))
                                    }
                                    .foregroundStyle(Color.black)
                                }
                            }
                        } else {
                            // For Month only: Show day numbers at +7 increments starting from 1
                            // We need to use the monthDayMarks array directly
                            if !monthDayMarks.isEmpty {
                                AxisMarks(values: monthDayMarks) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                        .foregroundStyle(Color.gray.opacity(0.75))
                                    if let date = value.as(Date.self) {
                                        AxisValueLabel {
                                            Text(date, format: .dateTime.day())
                                        }
                                        .foregroundStyle(Color.black)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ModelPreview(entries: [
        WeightEntry(weightKg: 70.0, isKg: true, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!),
        WeightEntry(weightKg: 70.4, isKg: true, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        WeightEntry(weightKg: 69.8, isKg: true, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    ]) {
        AnalyticsView()
    }
}
