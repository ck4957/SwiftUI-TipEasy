import SwiftUI

enum AppTheme {
    case standard

    var palette: ThemePalette {
        ThemePalette(
            accent: ThemePalette.dynamic(light: RGB(0.00, 0.34, 0.78), dark: RGB(0.42, 0.68, 1.00)),
            accentDeep: ThemePalette.dynamic(light: RGB(0.00, 0.22, 0.52), dark: RGB(0.74, 0.86, 1.00)),
            secondaryAccent: ThemePalette.dynamic(light: RGB(0.36, 0.38, 0.42), dark: RGB(0.72, 0.74, 0.78)),
            highlight: ThemePalette.dynamic(light: RGB(0.86, 0.45, 0.08), dark: RGB(1.00, 0.66, 0.28)),
            backgroundTop: ThemePalette.dynamic(light: RGB(0.97, 0.97, 0.98), dark: RGB(0.06, 0.06, 0.07)),
            backgroundMid: ThemePalette.dynamic(light: RGB(0.95, 0.96, 0.97), dark: RGB(0.08, 0.08, 0.09)),
            backgroundBottom: ThemePalette.dynamic(light: RGB(0.94, 0.95, 0.96), dark: RGB(0.05, 0.05, 0.06)),
            card: ThemePalette.dynamic(light: RGB(1.00, 1.00, 1.00, 0.82), dark: RGB(0.13, 0.13, 0.15, 0.78)),
            field: ThemePalette.dynamic(light: RGB(1.00, 1.00, 1.00, 0.74), dark: RGB(0.18, 0.18, 0.20, 0.76)),
            tile: ThemePalette.dynamic(light: RGB(0.96, 0.96, 0.97, 0.86), dark: RGB(0.18, 0.18, 0.20, 0.86)),
            selectedTile: ThemePalette.dynamic(light: RGB(0.88, 0.93, 1.00, 0.92), dark: RGB(0.12, 0.22, 0.36, 0.92))
        )
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
        secondaryAccent.opacity(0.20)
    }

    var glassTint: Color {
        accent.opacity(0.04)
    }

    static func dynamic(light: RGB, dark: RGB) -> Color {
        Color(uiColor: UIColor { traits in
            let color = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
        })
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .standard
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
