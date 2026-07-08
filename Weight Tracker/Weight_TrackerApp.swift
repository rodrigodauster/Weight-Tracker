//
//  Weight_TrackerApp.swift
//  Weight Tracker
//
//  Created by Rodrigo Dauster on 20/02/2026.
//

import SwiftUI
import SwiftData

@main
struct Weight_TrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: WeightEntry.self)
    }
}
