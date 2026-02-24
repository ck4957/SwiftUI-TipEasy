import GoogleMobileAds

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            TipCalculatorView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            TipPresetSettingsView()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .symbolRenderingMode(.hierarchical)
                        }
                        .glassEffect(.regular.interactive())
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
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
