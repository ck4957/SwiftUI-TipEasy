import Foundation

class AppVersionChecker: ObservableObject {
    @Published var isUpdateRequired = false
    @Published var isCheckingForUpdates = false
    @Published var latestVersion: String?
    @Published var releaseNotes: String?
    @Published var appStoreURL: URL?
    
    private let bundleId = Bundle.main.bundleIdentifier ?? "com.yourcompany.TipEasy"
    
    func checkForUpdates() {
        isCheckingForUpdates = true
        
        // Create iTunes lookup URL with your app's bundle ID
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            isCheckingForUpdates = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isCheckingForUpdates = false
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let results = json["results"] as? [[String: Any]],
                      let appInfo = results.first,
                      let latestVersion = appInfo["version"] as? String,
                      let appStoreUrl = appInfo["trackViewUrl"] as? String,
                      let url = URL(string: appStoreUrl)
                else { return }
                
                self.latestVersion = latestVersion
                self.appStoreURL = url
                self.releaseNotes = appInfo["releaseNotes"] as? String
                
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                
                // Compare versions to check if update is needed
                self.isUpdateRequired = self.compareVersions(currentVersion, latestVersion)
            }
        }.resume()
    }
    
    private func compareVersions(_ current: String, _ latest: String) -> Bool {
        let currentComponents = current.components(separatedBy: ".").map { Int($0) ?? 0 }
        let latestComponents = latest.components(separatedBy: ".").map { Int($0) ?? 0 }
        
        for i in 0 ..< min(currentComponents.count, latestComponents.count) {
            if currentComponents[i] < latestComponents[i] {
                return true // Update required
            } else if currentComponents[i] > latestComponents[i] {
                return false // Current version is newer (development)
            }
        }
        
        return latestComponents.count > currentComponents.count
    }
}
