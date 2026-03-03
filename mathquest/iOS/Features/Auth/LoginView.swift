import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("hasSeenCarousel") private var hasSeenCarousel = true

    var body: some View {
        VStack(spacing: 20) {
            Text("Kram")
                .font(.system(size: 40, weight: .heavy))
                .padding(.top, 40)

            Text("Sign in to continue")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                Task { await authManager.signInWithGoogle() }
            } label: {
                Label("Google Sign-In", systemImage: "person.circle.fill")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(authManager.isLoading)

            SignInWithAppleButton(.signIn) { request in
                authManager.prepareAppleSignInRequest(request)
            } onCompletion: { result in
                Task { await authManager.signInWithApple(result: result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .disabled(authManager.isLoading)

            Button("View onboarding") {
                hasSeenCarousel = false
            }
            .buttonStyle(.borderless)
            .disabled(authManager.isLoading)

            if authManager.isLoading {
                ProgressView()
            }

            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
