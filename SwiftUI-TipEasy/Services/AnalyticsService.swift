import Foundation

enum AnalyticsEvent: String {
    case appOpened = "app_opened"
    case tabSelected = "tab_selected"
    case onboardingCompleted = "onboarding_completed"
    case calculatorCleared = "calculator_cleared"
    case transactionSaved = "transaction_saved"
    case presetSelected = "preset_selected"
    case customTipEntered = "custom_tip_entered"
    case receiptScanStarted = "receipt_scan_started"
    case receiptScanCompleted = "receipt_scan_completed"
    case receiptScanUsed = "receipt_scan_used"
    case presetCreated = "preset_created"
    case presetEdited = "preset_edited"
    case presetDeleted = "preset_deleted"
    case themeChanged = "theme_changed"
    case appearanceChanged = "appearance_changed"
}

enum AnalyticsService {
    static func track(_ event: AnalyticsEvent, properties: [String: String] = [:]) {
        #if DEBUG
        let detail = properties.isEmpty ? "" : " \(properties)"
        print("[Analytics] \(event.rawValue)\(detail)")
        #else
        // Connect a production analytics provider here.
        #endif
    }

    static func billBucket(for amount: Double) -> String {
        switch amount {
        case 0..<25:
            "under_25"
        case 25..<50:
            "25_50"
        case 50..<100:
            "50_100"
        case 100..<200:
            "100_200"
        default:
            "200_plus"
        }
    }

    static func percentBucket(for percentage: Double) -> String {
        let wholePercent = Int((percentage * 100).rounded())

        switch wholePercent {
        case ..<15:
            "under_15"
        case 15:
            "15"
        case 16...18:
            "16_18"
        case 19...20:
            "19_20"
        case 21...25:
            "21_25"
        default:
            "over_25"
        }
    }
}
