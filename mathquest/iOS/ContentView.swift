import SwiftUI

/// Permette di cambiare tab da figli (es. dopo login username → andare alla Home).
final class TabSelection: ObservableObject {
    @Published var selectedTab: Int = 0
}

struct ContentView: View {
    @StateObject private var tabSelection = TabSelection()
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("profile_username") private var profileUsername = ""

    /// Camera disponibile se loggato con Firebase (Apple/Google) oppure con username/password.
    private var canUseCamera: Bool {
        authManager.isAuthenticated || !profileUsername.isEmpty
    }

    var body: some View {
        TabView(selection: $tabSelection.selectedTab) {
            HomeView()
                .tabItem { Label(L10n.lessons, systemImage: "house.fill") }
                .tag(0)
            NavigationStack {
                if canUseCamera {
                    CameraView()
                } else {
                    CameraLoginRequiredView()
                }
            }
                .tabItem { Label(L10n.camera, systemImage: "camera.fill") }
                .tag(1)
            NavigationStack {
                ProfileView()
            }
                .tabItem { Label(L10n.profileTab, systemImage: "person.fill") }
                .tag(2)
        }
        .environmentObject(tabSelection)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
}

private struct CameraLoginRequiredView: View {
    @EnvironmentObject private var tabSelection: TabSelection
    @State private var showLogin = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(L10n.signInRequired)
                .font(.title3)
                .fontWeight(.semibold)

            Text(L10n.signInCamera)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(L10n.signIn) {
                showLogin = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle(L10n.camera)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(
                showCloseButton: true,
                onUsernameLoginSuccess: {
                    showLogin = false
                    tabSelection.selectedTab = 0
                }
            )
        }
        .onChange(of: tabSelection.selectedTab) { _, newTab in
            if newTab != 1 { showLogin = false }
        }
    }
}
