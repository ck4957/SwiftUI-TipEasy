import GoogleMobileAds

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedAppTheme") private var selectedThemeRawValue = AppTheme.harvest.rawValue
    @AppStorage("appAppearance") private var appAppearanceRawValue = AppAppearance.system.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: AppTab = .calculator

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRawValue) ?? .harvest
    }

    private var appAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRawValue) ?? .system
    }

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
        .environment(\.appTheme, selectedTheme)
        .preferredColorScheme(appAppearance.colorScheme)
        .tint(selectedTheme.palette.accent)
        .fullScreenCover(isPresented: onboardingPresentation) {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environment(\.appTheme, selectedTheme)
                .preferredColorScheme(appAppearance.colorScheme)
        }
        .onAppear {
            routePendingDestination()
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                routePendingDestination()
            }
        }
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
        guard let rawValue = UserDefaults.standard.string(forKey: "pendingTipEasyDestination"),
              let destination = TipEasyDestination(rawValue: rawValue)
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

        UserDefaults.standard.removeObject(forKey: "pendingTipEasyDestination")
    }
}

private enum AppTab: Hashable {
    case calculator
    case history
    case settings
}

#Preview {
    ContentView()
}

// UIViewRepresentable wrapper for AdMob banner view
struct AdBannerView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController
        {
            bannerView.rootViewController = rootViewController
        }
        bannerView.load(Request())

        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
