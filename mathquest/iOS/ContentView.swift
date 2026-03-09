import SwiftUI

/// Permette di cambiare tab da figli (es. dopo login username → andare alla Home).
final class TabSelection: ObservableObject {
    @Published var selectedTab: Int = 0
}

struct ContentView: View {
    @StateObject private var tabSelection = TabSelection()
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("profile_username") private var profileUsername = ""
    @AppStorage("profile_name") private var profileName = ""
    @State private var showProfileSetup = false

    private var isLoggedIn: Bool {
        authManager.isAuthenticated || !profileUsername.isEmpty
    }

    /// Show profile setup after Google/Apple sign-in if name or username is missing
    private var needsProfileSetup: Bool {
        authManager.isAuthenticated && (profileName.isEmpty || profileUsername.isEmpty)
    }

    /// Camera available only if logged in.
    private var canUseCamera: Bool {
        isLoggedIn
    }

    var body: some View {
        TabView(selection: $tabSelection.selectedTab) {
            HomeView()
                .tabItem { Label("Lessons", systemImage: "house.fill") }
                .tag(0)
            CommunityView()
                .tabItem { Label("Community", systemImage: "person.2.fill") }
                .tag(1)
            NavigationStack {
                if canUseCamera {
                    CameraView()
                } else {
                    CameraLoginRequiredView()
                }
            }
            .tabItem { Label("Camera", systemImage: "camera.fill") }
            .tag(2)
            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(3)
        }
        .environmentObject(tabSelection)
        .fullScreenCover(isPresented: $showProfileSetup) {
            ProfileSetupView {
                showProfileSetup = false
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuth in
            if isAuth && (profileName.isEmpty || profileUsername.isEmpty) {
                showProfileSetup = true
            }
        }
        .onAppear {
            if needsProfileSetup {
                showProfileSetup = true
            }
        }
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

            Text("Sign in required")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Sign in to use camera solving.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Sign In") {
                showLogin = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Camera")
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
            if newTab != 2 { showLogin = false }
        }
    }
}
