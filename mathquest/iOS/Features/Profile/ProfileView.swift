import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        List {
            Section {
                Button("Sign Out") {
                    authManager.signOut()
                    viewModel.signOut()
                }
                .foregroundStyle(.red)
            }
            Section("Stats") {
                Label("Streak: \(viewModel.streakDays) days", systemImage: "flame.fill")
                Label("Lessons: \(viewModel.lessonsCompleted)", systemImage: "book.fill")
            }
            Section {
                NavigationLink("Settings") {
                    SettingsView()
                }
            }
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthManager())
    }
}
