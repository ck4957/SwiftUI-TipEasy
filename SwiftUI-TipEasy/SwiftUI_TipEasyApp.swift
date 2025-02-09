//
//  SwiftUI_TipEasyApp.swift
//  SwiftUI-TipEasy
//
//  Created by Chirag Kular on 2/8/25.
//

import SwiftData
import SwiftUI

@main
struct TipEasyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [TipPreset.self])
        }
    }
}
