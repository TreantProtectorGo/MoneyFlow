//
//  MoneyFlowApp.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/2.
//

import SwiftUI
import SwiftData

@main
struct MoneyFlowApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
            User.self,
            Group.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Fetch exchange rates on launch
                    await ExchangeRateService.shared.fetchRates()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
