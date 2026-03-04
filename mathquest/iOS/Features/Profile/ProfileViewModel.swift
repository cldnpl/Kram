import Foundation
import FirebaseAuth

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userPhotoURL: URL?
    @Published var mathLevel: String = ""
    @Published var streakDays = 0
    @Published var lessonsCompleted = 0

    var userInitials: String {
        let components = userName.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    func load() {
        // Load from UserDefaults
        userName = UserDefaults.standard.string(forKey: "profile_name") ?? ""
        mathLevel = UserDefaults.standard.string(forKey: "profile_level") ?? "Beginner"

        // Try to get info from Firebase Auth
        if let currentUser = Auth.auth().currentUser {
            if userName.isEmpty {
                userName = currentUser.displayName ?? ""
            }
            userEmail = currentUser.email ?? ""
            userPhotoURL = currentUser.photoURL
        }
    }

    func signOut() {
        // Clear local profile data on sign out
        UserDefaults.standard.removeObject(forKey: "profile_name")
        UserDefaults.standard.removeObject(forKey: "profile_level")
        CoinWallet.resetLocalBonus()
    }
}
