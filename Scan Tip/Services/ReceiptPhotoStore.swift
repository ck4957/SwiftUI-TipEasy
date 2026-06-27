import Foundation
import UIKit

enum ReceiptPhotoStore {
    private static let directoryName = "ReceiptPhotos"

    static func save(_ data: Data) throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        let url = try photoDirectory().appendingPathComponent(filename)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return filename
    }

    static func image(named filename: String?) -> UIImage? {
        guard let filename,
              let directory = try? photoDirectory()
        else {
            return nil
        }

        let url = directory.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    static func delete(filename: String?) {
        guard let filename,
              let directory = try? photoDirectory()
        else {
            return
        }

        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }

    static func deleteAll() throws {
        let directory = try photoDirectory()
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    private static func photoDirectory() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = baseURL.appendingPathComponent(directoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
        }

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableDirectory = directory
        try? mutableDirectory.setResourceValues(resourceValues)

        return directory
    }
}
