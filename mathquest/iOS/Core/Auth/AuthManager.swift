import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import GoogleSignIn
import UIKit

@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published private(set) var isAuthenticated: Bool
    @Published private(set) var firebaseUID: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    override init() {
        isAuthenticated = false
        firebaseUID = nil
        super.init()
        // Setup Firebase Auth in background per evitare blocco del main thread (watchdog/SIGKILL su device).
        Task { @MainActor in
            self.setupAuthStateListener()
        }
    }

    private func setupAuthStateListener() {
        let currentUser = Auth.auth().currentUser
        isAuthenticated = currentUser != nil
        firebaseUID = currentUser?.uid
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                self?.firebaseUID = user?.uid
            }
        }
    }

    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let rootViewController = Self.rootViewController else {
                throw AuthManagerError.unableToFindPresentingController
            }

            let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = signInResult.user.idToken?.tokenString else {
                throw AuthManagerError.missingGoogleIdToken
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: signInResult.user.accessToken.tokenString
            )
            _ = try await Auth.auth().signIn(with: credential)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        isLoading = true
        errorMessage = nil
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func signInWithApple(result: Result<ASAuthorization, Error>) async {
        defer { isLoading = false }

        do {
            guard case let .success(authorization) = result else {
                if case let .failure(error) = result {
                    throw error
                }
                throw AuthManagerError.invalidAppleCredential
            }

            guard let appleIdCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthManagerError.invalidAppleCredential
            }
            guard let nonce = currentNonce else {
                throw AuthManagerError.missingNonce
            }
            guard
                let appleTokenData = appleIdCredential.identityToken,
                let appleToken = String(data: appleTokenData, encoding: .utf8)
            else {
                throw AuthManagerError.missingAppleIdToken
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: appleToken,
                rawNonce: nonce,
                fullName: appleIdCredential.fullName
            )
            _ = try await Auth.auth().signIn(with: credential)
            currentNonce = nil
        } catch {
            currentNonce = nil
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                UInt8.random(in: 0...255)
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

private enum AuthManagerError: LocalizedError {
    case unableToFindPresentingController
    case missingGoogleIdToken
    case invalidAppleCredential
    case missingNonce
    case missingAppleIdToken

    var errorDescription: String? {
        switch self {
        case .unableToFindPresentingController:
            return "Unable to find a valid screen to present Google sign-in."
        case .missingGoogleIdToken:
            return "Google sign-in did not return an ID token."
        case .invalidAppleCredential:
            return "Unable to read Apple sign-in credentials."
        case .missingNonce:
            return "Apple sign-in security nonce is missing."
        case .missingAppleIdToken:
            return "Apple sign-in did not return an ID token."
        }
    }
}
