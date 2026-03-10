import SwiftUI
import FirebaseAuth

/// Permette di cambiare tab da figli (es. dopo login username → andare alla Home).
final class TabSelection: ObservableObject {
    @Published var selectedTab: Int = 0
}

struct ContentView: View {
    @StateObject private var tabSelection = TabSelection()
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("hasSeenCarousel") private var hasSeenCarousel = false
    @AppStorage("profile_username") private var profileUsername = ""
    @AppStorage("profile_name") private var profileName = ""
    @AppStorage("profile_level") private var profileLevel = ""
    @State private var showCarousel = false
    @State private var showProfileSetup = false
    @State private var isHydratingProfile = false

    private var isLoggedIn: Bool {
        authManager.isAuthenticated || !profileUsername.isEmpty
    }

    private var isProfileComplete: Bool {
        !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileLevel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        .fullScreenCover(isPresented: $showCarousel) {
            CarouselOnboardingView {
                hasSeenCarousel = true
                showCarousel = false
            }
        }
        .fullScreenCover(isPresented: $showProfileSetup) {
            ProfileSetupView {
                showProfileSetup = false
            }
        }
        .onChange(of: hasSeenCarousel) { _, seen in
            if seen {
                Task {
                    await hydrateProfileFromBackendIfNeeded()
                    if !isProfileComplete {
                        showProfileSetup = true
                    }
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, _ in
            if hasSeenCarousel {
                Task {
                    await hydrateProfileFromBackendIfNeeded()
                    if !isProfileComplete {
                        showProfileSetup = true
                    }
                }
            }
        }
        .onAppear {
            if !hasSeenCarousel {
                showCarousel = true
            } else {
                Task {
                    await hydrateProfileFromBackendIfNeeded()
                    if !isProfileComplete {
                        showProfileSetup = true
                    }
                }
            }
        }
    }

    private func resolvedAuthToken() -> String? {
        if let uid = Auth.auth().currentUser?.uid, !uid.isEmpty {
            return uid
        }
        let username = profileUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !username.isEmpty {
            return "username:\(username)"
        }
        return nil
    }

    private func hydrateProfileFromBackendIfNeeded() async {
        if isProfileComplete || isHydratingProfile {
            return
        }
        guard let token = resolvedAuthToken() else { return }
        isHydratingProfile = true
        defer { isHydratingProfile = false }

        do {
            let client = APIClient()
            await client.setToken(token)
            let remote: BootstrapProfileResponse = try await client.request("profile")

            if let remoteNameRaw = remote.name?.trimmingCharacters(in: .whitespacesAndNewlines) {
                let isPlaceholder = remoteNameRaw.caseInsensitiveCompare("Mock User") == .orderedSame ||
                    remoteNameRaw.caseInsensitiveCompare("MathQuest User") == .orderedSame
                if !remoteNameRaw.isEmpty && !isPlaceholder {
                    profileName = remoteNameRaw
                }
            }
            if let remoteUsername = remote.username?.trimmingCharacters(in: .whitespacesAndNewlines), !remoteUsername.isEmpty {
                profileUsername = remoteUsername
            }
            if let remoteLevel = remote.math_level?.trimmingCharacters(in: .whitespacesAndNewlines), !remoteLevel.isEmpty {
                profileLevel = remoteLevel
            }
        } catch {
            // Keep local values only; profile setup fallback will handle missing data.
        }
    }
}

private struct BootstrapProfileResponse: Decodable {
    let name: String?
    let username: String?
    let math_level: String?
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
