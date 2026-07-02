import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var locationManager: LocationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: AppTab = .calculator
    @State private var hasTrackedAppOpen = false

    private let appTheme = AppTheme.standard

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TipCalculatorView()
            }
            .tabItem {
                Label("Calculator", systemImage: "percent")
            }
            .tag(AppTab.calculator)

            NavigationStack {
                TipHistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(AppTab.history)

            NavigationStack {
                TipPresetSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            .tag(AppTab.settings)
        }
        .background {
            appTheme.palette.backgroundBottom
                .ignoresSafeArea()
        }
        .toolbarBackground(.hidden, for: .tabBar)
        .environment(\.appTheme, appTheme)
        .tint(appTheme.palette.accent)
        .fullScreenCover(isPresented: onboardingPresentation) {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environment(\.appTheme, appTheme)
        }
        .onAppear {
            trackAppOpenIfNeeded()
            routePendingDestination()
            if !ScreenshotAutomation.isEnabled {
                locationManager.requestPermissionOnFirstLaunch()
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            AnalyticsService.track(.tabSelected, properties: ["tab": newValue.analyticsName])
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                routePendingDestination()
                locationManager.refreshLocationIfAllowed()
            }
        }
    }

    private func trackAppOpenIfNeeded() {
        guard !hasTrackedAppOpen else { return }
        hasTrackedAppOpen = true
        AnalyticsService.track(.appOpened)
    }

    private var onboardingPresentation: Binding<Bool> {
        Binding {
            !hasCompletedOnboarding
        } set: { isPresented in
            if !isPresented {
                hasCompletedOnboarding = true
            }
        }
    }

    private func routePendingDestination() {
        guard let rawValue = UserDefaults.standard.string(forKey: "pendingScanTipDestination"),
              let destination = ScanTipDestination(rawValue: rawValue)
        else {
            return
        }

        switch destination {
        case .calculator, .scanner:
            selectedTab = .calculator
        case .history:
            selectedTab = .history
        case .settings:
            selectedTab = .settings
        }

        UserDefaults.standard.removeObject(forKey: "pendingScanTipDestination")
    }
}

private enum AppTab: Hashable {
    case calculator
    case history
    case settings

    var analyticsName: String {
        switch self {
        case .calculator:
            "calculator"
        case .history:
            "history"
        case .settings:
            "settings"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TipPreset.self, TipTransaction.self], inMemory: true)
        .environment(PurchaseManager())
        .environmentObject(LocationManager())
}
