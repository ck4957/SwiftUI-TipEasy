import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            TipCalculatorView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: TipPresetSettingsView()) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            // .modelContainer(ModelContainer(for: [TipPreset.self])) // Inject model container for SwiftData
            .preferredColorScheme(.light)
    }
}
