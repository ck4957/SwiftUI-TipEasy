import Foundation
import Observation
import SwiftData
import SwiftUI

// MARK: - Error Types

enum VersionError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case dataError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid App Store URL"
        case .invalidResponse: return "Invalid response from App Store"
        case .dataError: return "Could not parse App Store data"
        }
    }
}

// MARK: - App Store Models

struct LookupResult: Decodable {
    let results: [AppInfo]?
}

struct AppInfo: Decodable {
    let version: String
    let trackViewUrl: String
    let trackName: String?
    let releaseNotes: String?
}

// MARK: - App Version Checker

@Observable
final class AppVersionChecker {
    // State properties (automatically observed)
    var isUpdateRequired = false
    var isCheckingForUpdates = false
    var latestVersion: String?
    var releaseNotes: String?
    var appStoreURL: URL?
    var appName: String?
    var error: VersionError?
    
    private let bundleId = Bundle.main.bundleIdentifier ?? "com.chiragkular.SwiftUI-TipEasy"
    private let countryCode = Locale.current.region?.identifier.lowercased() ?? "us"
    
    // Current app version
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // Modern async/await implementation
    @MainActor
    func checkForUpdates() async {
        isCheckingForUpdates = true
        error = nil
        
        do {
            // Create iTunes lookup URL with country code
            guard let url = URL(string: "https://itunes.apple.com/\(countryCode)/lookup?bundleId=\(bundleId)") else {
                error = .invalidURL
                isCheckingForUpdates = false
                return
            }
            
            // Perform request
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Verify response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                error = .invalidResponse
                isCheckingForUpdates = false
                return
            }
            
            // Parse response
            let lookup = try JSONDecoder().decode(LookupResult.self, from: data)
            
            guard let appInfo = lookup.results?.first else {
                error = .dataError
                isCheckingForUpdates = false
                return
            }
            
            // Update properties
            latestVersion = appInfo.version
            releaseNotes = appInfo.releaseNotes
            appName = appInfo.trackName
            
            if let url = URL(string: appInfo.trackViewUrl) {
                appStoreURL = url
            }
            
            // Compare versions
            isUpdateRequired = compareVersions(currentVersion, appInfo.version)
            
        } catch {
            self.error = .dataError
        }
        
        isCheckingForUpdates = false
    }
    
    // Helper for SwiftUI views to call async function
    func checkForUpdatesTask() {
        Task {
            await checkForUpdates()
        }
    }
    
    // Version comparison logic - more robust implementation
    private func compareVersions(_ current: String, _ latest: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let latestComponents = latest.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(currentComponents.count, latestComponents.count)
        let paddedCurrent = currentComponents + Array(repeating: 0, count: maxCount - currentComponents.count)
        let paddedLatest = latestComponents + Array(repeating: 0, count: maxCount - latestComponents.count)
        
        for i in 0 ..< maxCount {
            if paddedCurrent[i] < paddedLatest[i] {
                return true // Update required
            } else if paddedCurrent[i] > paddedLatest[i] {
                return false // Current version is newer
            }
        }
        
        return false // Versions are equal
    }
}

// MARK: - View Extension for SwiftUI Integration

extension View {
    func checkForAppUpdates(using versionChecker: AppVersionChecker) -> some View {
        modifier(UpdateAlertModifier(versionChecker: versionChecker))
    }
}

// MARK: - Update Alert Modifier

struct UpdateAlertModifier: ViewModifier {
    var versionChecker: AppVersionChecker
    @State private var showingUpdateAlert = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                Task {
                    await versionChecker.checkForUpdates()
                    if versionChecker.isUpdateRequired {
                        showingUpdateAlert = true
                    }
                }
            }
            .alert("Update Available", isPresented: $showingUpdateAlert) {
                Button("Update") {
                    if let url = versionChecker.appStoreURL {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Later", role: .cancel) {}
            } message: {
                Text("A new version of \(versionChecker.appName ?? "this app") is available. Would you like to update now?")
            }
    }
}
