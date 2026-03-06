import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        #if DEBUG
        print("[API] Base URL at launch: \(APIConfig.baseURLString)")
        #endif
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct MathQuestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
<<<<<<< HEAD
    @StateObject private var authManager = AuthManager()
    @StateObject private var subscriptionManager = SubscriptionManager()

    @AppStorage("hasSeenCarousel") private var hasSeenCarousel = false
    @AppStorage("hasCompletedProfile") private var hasCompletedProfile = false
    @AppStorage("settings_language") private var appLanguage = "en"

    /// Dopo il primo setup non si torna più alla schermata "Set your profile": nome e livello si modificano solo in Impostazioni.
    private var isProfileComplete: Bool {
        hasCompletedProfile
    }
=======
>>>>>>> fc0d863da90dc4edd125a225f5211d800566e104

    var body: some Scene {
        WindowGroup {
            BootstrapView()
        }
    }
}

private struct BootstrapView: View {
    @State private var didStart = false
    @State private var authManager: AuthManager?
    @State private var subscriptionManager: SubscriptionManager?

    var body: some View {
        Group {
            if let authManager, let subscriptionManager {
                AppFlowView()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
            } else {
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Starting...")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            guard !didStart else { return }
            didStart = true

            // Posticipa Firebase/Auth/StoreKit a dopo il primo frame per evitare watchdog/SIGKILL su device.
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }

            authManager = AuthManager()
            subscriptionManager = SubscriptionManager()
        }
    }
}

private struct AppFlowView: View {
    var body: some View {
        ContentView()
    }
}
