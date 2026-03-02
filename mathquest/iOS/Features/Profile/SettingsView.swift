import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("darkMode") private var darkMode = false

    var body: some View {
        Form {
            Toggle("Dark Mode", isOn: $darkMode)
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
