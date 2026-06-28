//
//  SwiftUI_ScanTipApp.swift
//  Scan Tip
//
//  Created by Chirag Kular on 2/8/25.
//

import SwiftData
import SwiftUI

@main
struct ScanTipApp: App {
    @State private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [TipPreset.self, TipTransaction.self])
                .environment(purchaseManager)
                .task {
                    await purchaseManager.start()
                }
        }
    }
}
