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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [TipPreset.self])
        }
    }
}
