import GoogleMobileAds
import SwiftUI

struct ContentView: View {
    init() {
        // Start Google Mobile Ads
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some View {
        NavigationStack {
            TipCalculatorView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: TipPresetSettingsView()) {
                            Image(systemName: "gear")
                        }
                    }
                }
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
