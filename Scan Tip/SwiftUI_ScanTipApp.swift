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
    @State private var purchaseManager: PurchaseManager
    @StateObject private var locationManager = LocationManager()
    private let modelContainer: ModelContainer
    private let isScreenshotAutomation: Bool

    @MainActor
    init() {
        isScreenshotAutomation = ScreenshotAutomation.isEnabled
        ScreenshotAutomation.configureUserDefaults()

        do {
            modelContainer = try ScanTipModelContainer.make(inMemory: isScreenshotAutomation)
            try ScreenshotAutomation.seedSampleData(in: modelContainer)
        } catch {
            fatalError("Unable to create Scan Tip model container: \(error)")
        }

        let manager = PurchaseManager()
        #if DEBUG
        if isScreenshotAutomation {
            manager.unlockPreviewPro()
        }
        #endif
        _purchaseManager = State(initialValue: manager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(purchaseManager)
                .environmentObject(locationManager)
                .task {
                    if !isScreenshotAutomation {
                        await purchaseManager.start()
                    }
                }
        }
    }
}
