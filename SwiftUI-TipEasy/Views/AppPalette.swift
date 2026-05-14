import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var iconName: String {
        switch self {
        case .system:
            "iphone"
        case .light:
            "sun.max"
        case .dark:
            "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case harvest
    case garden
    case berry

    var id: String { rawValue }

    var title: String {
        switch self {
        case .harvest:
            "Harvest"
        case .garden:
            "Garden"
        case .berry:
            "Berry"
        }
    }

    var subtitle: String {
        switch self {
        case .harvest:
            "Tomato, sage, and gold"
        case .garden:
            "Citrus, herb, and clay"
        case .berry:
            "Plum, rose, and apricot"
        }
    }

    var iconName: String {
        switch self {
        case .harvest:
            "fork.knife.circle"
        case .garden:
            "leaf.circle"
        case .berry:
            "sparkles"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .harvest:
            ThemePalette(
                accent: ThemePalette.dynamic(light: RGB(0.88, 0.27, 0.20), dark: RGB(1.00, 0.48, 0.38)),
                accentDeep: ThemePalette.dynamic(light: RGB(0.67, 0.20, 0.13), dark: RGB(1.00, 0.66, 0.48)),
                secondaryAccent: ThemePalette.dynamic(light: RGB(0.45, 0.58, 0.40), dark: RGB(0.66, 0.78, 0.55)),
                highlight: ThemePalette.dynamic(light: RGB(0.93, 0.64, 0.21), dark: RGB(1.00, 0.76, 0.32)),
                backgroundTop: ThemePalette.dynamic(light: RGB(1.00, 0.96, 0.89), dark: RGB(0.13, 0.10, 0.08)),
                backgroundMid: ThemePalette.dynamic(light: RGB(1.00, 0.86, 0.81, 0.62), dark: RGB(0.30, 0.13, 0.10, 0.62)),
                backgroundBottom: ThemePalette.dynamic(light: RGB(0.89, 0.95, 0.86), dark: RGB(0.08, 0.14, 0.11)),
                card: ThemePalette.dynamic(light: RGB(1.00, 0.93, 0.84, 0.70), dark: RGB(0.20, 0.17, 0.14, 0.72)),
                field: ThemePalette.dynamic(light: RGB(0.94, 0.98, 0.90, 0.72), dark: RGB(0.17, 0.22, 0.18, 0.76)),
                tile: ThemePalette.dynamic(light: RGB(0.98, 0.88, 0.74, 0.82), dark: RGB(0.24, 0.20, 0.16, 0.82)),
                selectedTile: ThemePalette.dynamic(light: RGB(1.00, 0.76, 0.63, 0.86), dark: RGB(0.39, 0.18, 0.14, 0.88))
            )
        case .garden:
            ThemePalette(
                accent: ThemePalette.dynamic(light: RGB(0.21, 0.56, 0.40), dark: RGB(0.44, 0.83, 0.62)),
                accentDeep: ThemePalette.dynamic(light: RGB(0.17, 0.38, 0.29), dark: RGB(0.70, 0.95, 0.75)),
                secondaryAccent: ThemePalette.dynamic(light: RGB(0.82, 0.51, 0.22), dark: RGB(0.94, 0.64, 0.34)),
                highlight: ThemePalette.dynamic(light: RGB(0.95, 0.77, 0.24), dark: RGB(1.00, 0.86, 0.36)),
                backgroundTop: ThemePalette.dynamic(light: RGB(0.94, 0.98, 0.84), dark: RGB(0.07, 0.14, 0.11)),
                backgroundMid: ThemePalette.dynamic(light: RGB(1.00, 0.91, 0.67, 0.55), dark: RGB(0.21, 0.27, 0.13, 0.58)),
                backgroundBottom: ThemePalette.dynamic(light: RGB(0.86, 0.94, 0.89), dark: RGB(0.13, 0.11, 0.08)),
                card: ThemePalette.dynamic(light: RGB(0.97, 0.93, 0.77, 0.70), dark: RGB(0.15, 0.22, 0.18, 0.74)),
                field: ThemePalette.dynamic(light: RGB(0.89, 0.97, 0.84, 0.74), dark: RGB(0.12, 0.25, 0.19, 0.76)),
                tile: ThemePalette.dynamic(light: RGB(0.96, 0.87, 0.62, 0.84), dark: RGB(0.22, 0.25, 0.16, 0.84)),
                selectedTile: ThemePalette.dynamic(light: RGB(0.72, 0.91, 0.63, 0.86), dark: RGB(0.12, 0.36, 0.25, 0.90))
            )
        case .berry:
            ThemePalette(
                accent: ThemePalette.dynamic(light: RGB(0.62, 0.25, 0.56), dark: RGB(0.92, 0.55, 0.85)),
                accentDeep: ThemePalette.dynamic(light: RGB(0.36, 0.16, 0.42), dark: RGB(0.82, 0.64, 1.00)),
                secondaryAccent: ThemePalette.dynamic(light: RGB(0.88, 0.39, 0.43), dark: RGB(1.00, 0.57, 0.62)),
                highlight: ThemePalette.dynamic(light: RGB(0.95, 0.62, 0.30), dark: RGB(1.00, 0.75, 0.42)),
                backgroundTop: ThemePalette.dynamic(light: RGB(0.99, 0.91, 0.95), dark: RGB(0.12, 0.08, 0.16)),
                backgroundMid: ThemePalette.dynamic(light: RGB(1.00, 0.81, 0.72, 0.58), dark: RGB(0.28, 0.11, 0.24, 0.60)),
                backgroundBottom: ThemePalette.dynamic(light: RGB(0.93, 0.89, 0.99), dark: RGB(0.16, 0.10, 0.10)),
                card: ThemePalette.dynamic(light: RGB(0.99, 0.88, 0.91, 0.72), dark: RGB(0.20, 0.14, 0.23, 0.76)),
                field: ThemePalette.dynamic(light: RGB(0.98, 0.91, 0.83, 0.75), dark: RGB(0.26, 0.17, 0.22, 0.76)),
                tile: ThemePalette.dynamic(light: RGB(0.98, 0.82, 0.76, 0.84), dark: RGB(0.27, 0.17, 0.24, 0.84)),
                selectedTile: ThemePalette.dynamic(light: RGB(0.90, 0.72, 0.95, 0.86), dark: RGB(0.39, 0.18, 0.42, 0.90))
            )
        }
    }
}

struct RGB {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

struct ThemePalette {
    let accent: Color
    let accentDeep: Color
    let secondaryAccent: Color
    let highlight: Color
    let backgroundTop: Color
    let backgroundMid: Color
    let backgroundBottom: Color
    let card: Color
    let field: Color
    let tile: Color
    let selectedTile: Color

    var stroke: Color {
        secondaryAccent.opacity(0.24)
    }

    var glassTint: Color {
        highlight.opacity(0.07)
    }

    static func dynamic(light: RGB, dark: RGB) -> Color {
        Color(uiColor: UIColor { traits in
            let color = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
        })
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .harvest
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }

    var appPalette: ThemePalette {
        appTheme.palette
    }
}
