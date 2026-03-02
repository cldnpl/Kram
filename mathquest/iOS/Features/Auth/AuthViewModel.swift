import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signInWithGoogle() async {
        isLoading = true
        defer { isLoading = false }
        // TODO: integrate Firebase
    }

    func signInWithApple() async {
        isLoading = true
        defer { isLoading = false }
        // TODO: integrate Firebase
    }
}
