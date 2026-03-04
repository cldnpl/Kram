import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
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
    @StateObject private var authManager = AuthManager()
    @StateObject private var subscriptionManager = SubscriptionManager()

    @AppStorage("hasSeenCarousel") private var hasSeenCarousel = false
    @AppStorage("hasCompletedProfile") private var hasCompletedProfile = false
    @AppStorage("profile_name") private var profileName = ""
    @AppStorage("profile_level") private var profileLevel = ""
    @AppStorage("settings_language") private var appLanguage = "en"

    private var isProfileComplete: Bool {
        hasCompletedProfile && !profileName.isEmpty && !profileLevel.isEmpty
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenCarousel {
                    CarouselOnboardingView(onComplete: {
                        hasSeenCarousel = true
                    })
                } else if !isProfileComplete {
                    ProfileSetupView(onComplete: {
                        hasCompletedProfile = true
                    })
                } else {
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(subscriptionManager)
                }
            }
        }
    }
}
