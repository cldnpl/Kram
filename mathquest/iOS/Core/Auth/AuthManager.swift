import Foundation

@MainActor
final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var firebaseUID: String?

    func signInWithGoogle() async {
        // TODO: Firebase Google Sign-In
        isAuthenticated = true
    }

    func signInWithApple() async {
        // TODO: Firebase Apple Sign-In
        isAuthenticated = true
    }

    func signOut() {
        isAuthenticated = false
        firebaseUID = nil
    }
}
