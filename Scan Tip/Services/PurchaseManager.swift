import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class PurchaseManager {
    static let proProductID = "com.chiragkular.SwiftUI-TipEasy.pro"
    nonisolated private static let proUnlockedKey = "isTipEasyProUnlocked"

    nonisolated static func storedProUnlock(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: proUnlockedKey)
    }

    private let defaults: UserDefaults
    private var updatesTask: Task<Void, Never>?

    private(set) var proProduct: Product?
    private(set) var isLoadingProducts = false
    private(set) var purchaseError: String?
    private(set) var isProUnlocked: Bool {
        didSet {
            defaults.set(isProUnlocked, forKey: Self.proUnlockedKey)
        }
    }

    var proPriceText: String {
        proProduct?.displayPrice ?? "One-time purchase"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isProUnlocked = defaults.bool(forKey: Self.proUnlockedKey)
    }

    func start() async {
        observeTransactionUpdates()
        await loadProducts()
        await refreshPurchasedProducts()
    }

    func buyPro() async {
        purchaseError = nil

        if proProduct == nil {
            await loadProducts()
        }

        guard let proProduct else {
            purchaseError = "Scan Tip Pro is not available yet. Check the App Store product setup and try again."
            return
        }

        do {
            let result = try await proProduct.purchase()

            switch result {
            case .success(.verified(let transaction)):
                unlockPro()
                await transaction.finish()
                AnalyticsService.track(.proPurchaseCompleted)
            case .success(.unverified):
                purchaseError = "We could not verify this purchase."
                AnalyticsService.track(.proPurchaseFailed, properties: ["reason": "unverified"])
            case .pending:
                purchaseError = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                purchaseError = "Purchase could not be completed."
            }
        } catch {
            purchaseError = error.localizedDescription
            AnalyticsService.track(.proPurchaseFailed, properties: ["reason": "storekit_error"])
        }
    }

    func restorePurchases() async {
        purchaseError = nil

        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()

            if isProUnlocked {
                AnalyticsService.track(.proPurchaseRestored)
            } else {
                purchaseError = "No Scan Tip Pro purchase was found for this Apple ID."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func clearPurchaseError() {
        purchaseError = nil
    }

    #if DEBUG
    func unlockPreviewPro() {
        unlockPro()
    }

    func resetPreviewPro() {
        isProUnlocked = false
    }
    #endif

    private func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            proProduct = try await Product.products(for: [Self.proProductID]).first
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func refreshPurchasedProducts() async {
        var foundProEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.productID == Self.proProductID {
                foundProEntitlement = true
            }
        }

        if foundProEntitlement {
            unlockPro()
        }
    }

    private func observeTransactionUpdates() {
        guard updatesTask == nil else { return }

        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }

                if case .verified(let transaction) = result,
                   transaction.productID == Self.proProductID {
                    unlockPro()
                    await transaction.finish()
                }
            }
        }
    }

    private func unlockPro() {
        isProUnlocked = true
    }
}
