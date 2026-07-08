//
//  WeightEntry.swift
//  Weight Tracker
//
//  Created by Rodrigo Dauster on 20/02/2026.
//

import Foundation
import SwiftData

@Model
final class WeightEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var weightKg: Double   // stored canonically in kilograms
    var isKg: Bool         // last-used unit for display; true = kg, false = lb
    var date: Date

    init(weightKg: Double, isKg: Bool, date: Date) {
        self.id = UUID()
        self.weightKg = weightKg
        self.isKg = isKg
        self.date = date
    }
}

extension WeightEntry {
    static func kg(fromPounds pounds: Double) -> Double {
        pounds * 0.45359237
    }

    static func pounds(fromKg kg: Double) -> Double {
        kg / 0.45359237
    }
}
