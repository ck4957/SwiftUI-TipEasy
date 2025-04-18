import SwiftUI

struct AppUpdateView: View {
    let currentVersion: String
    let latestVersion: String
    let releaseNotes: String?
    let updateAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 30)
            
            Text("Update Required")
                .font(.title)
                .fontWeight(.bold)
            
            Text("A new version of Tip Easy is available. Please update to continue using the app.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 4) {
                Text("Current version:")
                    .foregroundColor(.secondary)
                Text(currentVersion)
                    .fontWeight(.medium)
                
                Text("•")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                Text("Latest version:")
                    .foregroundColor(.secondary)
                Text(latestVersion)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            
            if let notes = releaseNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's New:")
                        .font(.headline)
                        .padding(.bottom, 2)
                    
                    ScrollView {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: 120)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            Button(action: updateAction) {
                Text("Update Now")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)
            
            Text("This update is required to ensure you have the latest features and security improvements.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AppUpdateView(
        currentVersion: "1.0.0",
        latestVersion: "1.1.0",
        releaseNotes: "• Improved tip calculation accuracy\n• Added new category options\n• Fixed keyboard issue\n• Performance improvements",
        updateAction: {}
    )
}
