import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(L10n.lessons, systemImage: "house.fill") }
                .tag(0)
            NavigationStack {
                if authManager.isAuthenticated {
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
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
}

private struct CameraLoginRequiredView: View {
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
            LoginView(showCloseButton: true)
        }
    }
}
