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
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(ScanTipModelContainer.shared)
                .environment(purchaseManager)
                .environmentObject(locationManager)
                .task {
                    await purchaseManager.start()
                }
        }
    }
}
