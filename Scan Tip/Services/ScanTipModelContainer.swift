import SwiftData

enum ScanTipModelContainer {
    static let cloudKitContainerIdentifier = "iCloud.com.chiragkular.SwiftUI-TipEasy"

    static let shared: ModelContainer = {
        do {
            return try make()
        } catch {
            fatalError("Unable to create Scan Tip model container: \(error)")
        }
    }()

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            TipPreset.self,
            TipTransaction.self
        ])
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = PurchaseManager.storedProUnlock()
            ? .private(cloudKitContainerIdentifier)
            : .none
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : cloudKitDatabase
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
