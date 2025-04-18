//
//  SwiftUI_TipEasyApp.swift
//  SwiftUI-TipEasy
//
//  Created by Chirag Kular on 2/8/25.
//

import GoogleMobileAds
import SwiftData
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        MobileAds.shared.start(completionHandler: nil)

        return true
    }
}

@main
struct TipEasyApp: App {
    // Use AppDelegate for Google Mobile Ads
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // App Version
    @State private var versionChecker = AppVersionChecker()

    let modelContainer: ModelContainer

    init() {
        // Add schema migration options
        let configuration = ModelConfiguration(
            schema: Schema([
                TipPreset.self,
                CalculationHistory.self,
                LocationCoordinate.self
            ]),
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        modelContainer = try! ModelContainer(for:
            TipPreset.self,
            CalculationHistory.self,
            LocationCoordinate.self,
            configurations: configuration)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .modelContainer(modelContainer)
                    .checkForAppUpdates(using: versionChecker)
            }
        }
    }
}
