import SwiftUI

struct OnboardingView: View {
    @Environment(\.appPalette) private var palette
    @Binding var hasCompletedOnboarding: Bool
    @State private var selectedPage = 0

    private let pages = OnboardingPage.allCases

    var body: some View {
        VStack(spacing: .spacingLarge) {
            HStack {
                Text("Scan Tip")
                    .font(.headline)
                Spacer()
                Button("Skip") {
                    completeOnboarding()
                }
                .buttonStyle(.glass)
            }
            .padding(.horizontal)
            .padding(.top, 18)

            TabView(selection: $selectedPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                        .padding(.horizontal)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                advance()
            } label: {
                Label(selectedPage == pages.count - 1 ? "Start Calculating" : "Next", systemImage: selectedPage == pages.count - 1 ? "checkmark" : "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [
                    palette.backgroundTop,
                    palette.backgroundMid,
                    palette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .tint(palette.accent)
    }

    private func advance() {
        guard selectedPage < pages.count - 1 else {
            completeOnboarding()
            return
        }

        withAnimation(.snappy) {
            selectedPage += 1
        }
    }

    private func completeOnboarding() {
        AnalyticsService.track(
            .onboardingCompleted,
            properties: ["completed_page": pages[selectedPage].id]
        )
        hasCompletedOnboarding = true
    }
}

private struct OnboardingPageView: View {
    @Environment(\.appPalette) private var palette
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            Image(systemName: page.iconName)
                .font(.system(size: 62, weight: .semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 118, height: 118)
                .background(palette.selectedTile, in: Circle())
                .glassEffect(.regular.tint(palette.accent.opacity(0.12)), in: .circle)

            VStack(spacing: 10) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)

                Text(page.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 8)

            pagePreview

            Spacer()
        }
    }

    private var pagePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(page.previewItems, id: \.self) { item in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.secondaryAccent)
                    Text(item)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card, in: RoundedRectangle(cornerRadius: .cornerRadiusLarge))
        .glassEffect(.regular.tint(palette.glassTint), in: .rect(cornerRadius: .cornerRadiusLarge))
    }
}

private enum OnboardingPage: String, CaseIterable, Identifiable {
    case calculate
    case scan
    case save

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .calculate:
            "percent"
        case .scan:
            "camera.viewfinder"
        case .save:
            "tray.and.arrow.down"
        }
    }

    var title: String {
        switch self {
        case .calculate:
            "Compare Tips Fast"
        case .scan:
            "Scan a Receipt"
        case .save:
            "Save the Visit"
        }
    }

    var message: String {
        switch self {
        case .calculate:
            "Enter the bill total and choose from quick suggestions like 15%, 18%, 20%, and 25%."
        case .scan:
            "Use the camera button to read a receipt total and see tip suggestions over the scanner."
        case .save:
            "Add the place name, save the result, and review your local history by month."
        }
    }

    var previewItems: [String] {
        switch self {
        case .calculate:
            ["Bill total", "Tip options", "Final total"]
        case .scan:
            ["Receipt total", "Suggested tips", "Use detected amount"]
        case .save:
            ["Restaurant name", "Monthly history", "Local totals"]
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(\.appTheme, .standard)
}
