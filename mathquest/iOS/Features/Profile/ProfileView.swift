import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some View {
        List {
            Section {
                Button(isLoggedIn ? "Sign Out" : "Sign In") {
                    isLoggedIn.toggle()
                    if !isLoggedIn { viewModel.signOut() }
                }
                .foregroundStyle(isLoggedIn ? .red : .accentColor)
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
    NavigationStack { ProfileView() }
}
