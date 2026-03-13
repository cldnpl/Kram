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
    @AppStorage("settings_language") private var language = "en"
    @AppStorage("session_logged_in") private var sessionLoggedIn = false
    @AppStorage("profile_username") private var profileUsername = ""
    @AppStorage("profile_name") private var profileName = ""
    @AppStorage("profile_level") private var profileLevel = ""
    @State private var showCarousel = false
    @State private var isHydratingProfile = false
    @State private var isLoadingSharedSolution = false
    @State private var sharedSolutionSheet: SharedSolutionSheet?
    @State private var sharedSolutionErrorMessage = ""
    @State private var showSharedSolutionError = false

    private var isProfileComplete: Bool {
        !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profileLevel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        TabView(selection: $tabSelection.selectedTab) {
            HomeView()
                .tabItem { Label(L10n.lessons, systemImage: "house.fill") }
                .tag(0)
            CommunityView()
                .tabItem { Label(L10n.communityTitle, systemImage: "person.2.fill") }
                .tag(1)
            NavigationStack {
                CameraView()
            }
            .tabItem { Label(L10n.camera, systemImage: "camera.fill") }
            .tag(2)
            NavigationStack {
                ProfileView()
            }
            .tabItem { Label(L10n.profileTab, systemImage: "person.fill") }
            .tag(3)
        }
        .id("tabs-\(language)")
        .environment(\.locale, Locale(identifier: language))
        .environmentObject(tabSelection)
        .onOpenURL { url in
            handleIncomingURL(url)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            guard let url = userActivity.webpageURL else { return }
            handleIncomingURL(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .appDidReceiveExternalURL)) { notification in
            guard let url = notification.object as? URL else { return }
            handleIncomingURL(url)
        }
        .sheet(item: $sharedSolutionSheet) { sheet in
            HistoryDetailView(
                detail: sheet.detail,
                shareLinkAction: {
                    AppLinks.webSharedSolutionURL(token: sheet.token)
                },
                onDelete: nil
            )
        }
        .alert(L10n.error, isPresented: $showSharedSolutionError) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(sharedSolutionErrorMessage)
        }
        .overlay {
            if isLoadingSharedSolution {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    ProgressView(L10n.loading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .fullScreenCover(isPresented: $showCarousel) {
            CarouselOnboardingView {
                hasSeenCarousel = true
                showCarousel = false
            }
        }
        .onChange(of: hasSeenCarousel) { _, seen in
            if seen {
                Task {
                    await hydrateProfileFromBackendIfNeeded()
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, _ in
            if hasSeenCarousel {
                Task {
                    await hydrateProfileFromBackendIfNeeded()
                }
            }
        }
        .onAppear {
            if !hasSeenCarousel {
                showCarousel = true
            } else {
                Task {
                    await hydrateProfileFromBackendIfNeeded()
                }
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard case let .sharedSolution(token) = AppLinks.route(from: url) else {
            return
        }
        Task {
            await openSharedSolution(token: token)
        }
    }

    private func openSharedSolution(token: String) async {
        guard !isLoadingSharedSolution else {
            return
        }
        isLoadingSharedSolution = true
        defer { isLoadingSharedSolution = false }

        do {
            let client = APIClient()
            let response: SharedSolutionResponse = try await client.request("camera/shared/\(token)")
            tabSelection.selectedTab = 2
            sharedSolutionSheet = SharedSolutionSheet(response: response)
        } catch {
            sharedSolutionErrorMessage = L10n.sharedSolutionLoadFailed
            showSharedSolutionError = true
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
            // Keep local values only.
        }
    }
}

private struct SharedSolutionSheet: Identifiable {
    let token: String
    let detail: HistoryDetailResponse

    var id: String { token }

    init(response: SharedSolutionResponse) {
        token = response.token
        detail = HistoryDetailResponse(
            id: 0,
            problem: response.problem,
            solution: response.solution,
            steps: response.steps,
            rawLatex: response.rawLatex,
            difficultyLevel: response.difficultyLevel,
            createdAt: response.createdAt
        )
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
