import SwiftUI
import AuthenticationServices

/// Viola scuro per pulsante "Continue with username" (diverso dallo Shop #3D2468).
private let loginButtonDarkPurple = Color(red: 30/255, green: 18/255, blue: 52/255) // #1E1234

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenCarousel") private var hasSeenCarousel = true
    @State private var showUsernamePasswordAuth = false
    var showCloseButton = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.3, blue: 0.9),
                    Color(red: 0.6, green: 0.4, blue: 0.95),
                    Color(red: 0.5, green: 0.35, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles
            GeometryReader { geo in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -50)

                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width - 80, y: geo.size.height - 200)

                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .offset(x: geo.size.width - 120, y: 100)
            }

            VStack(spacing: 0) {
                if showCloseButton {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.25))
                                .clipShape(Circle())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                }

                Spacer()

                // Logo and title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 100, height: 100)
                            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)

                        Image(systemName: "function")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("Kram")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Master math, one step at a time")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                // Sign in buttons
                VStack(spacing: 14) {
                    // Continue with username → open username/password auth page
                    Button {
                        showUsernamePasswordAuth = true
                    } label: {
                        Text("Continue with username")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(loginButtonDarkPurple)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    // Google Sign-In Button
                    Button {
                        Task { await authManager.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 22))
                            Text("Continue with Google")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.black.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                    }
                    .disabled(authManager.isLoading)

                    // Apple Sign-In Button
                    SignInWithAppleButton(.continue) { request in
                        authManager.prepareAppleSignInRequest(request)
                    } onCompletion: { result in
                        Task { await authManager.signInWithApple(result: result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .disabled(authManager.isLoading)

                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 8)
                    }

                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                if showCloseButton {
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue as guest")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .disabled(authManager.isLoading)
                    .padding(.bottom, 12)
                }

                // Footer
                Button {
                    hasSeenCarousel = false
                } label: {
                    Text("View onboarding again")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .disabled(authManager.isLoading)
                .padding(.bottom, 32)
            }
        }
        .fullScreenCover(isPresented: $showUsernamePasswordAuth) {
            UsernamePasswordAuthView(onDismiss: { showUsernamePasswordAuth = false })
                .environmentObject(authManager)
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if showCloseButton && isAuthenticated {
                dismiss()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
