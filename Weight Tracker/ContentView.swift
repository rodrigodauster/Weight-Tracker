//
//  ContentView.swift
//  Weight Tracker
//
//  Created by Rodrigo Dauster on 20/02/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            LogView()
                .tabItem {
                    Label("Log", systemImage: "square.and.pencil")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            DataView()
                .tabItem {
                    Label("Data", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
