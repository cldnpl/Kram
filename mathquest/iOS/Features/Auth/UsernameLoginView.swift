import SwiftUI

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

private let usernameAlreadyExistsMessage = "Nome utente già esistente"

/// View per login/registrazione con username e password.
/// Titolo "Login" o "Register"; tap su "Don't you have an account? Create one" mostra la stessa view in modalità Register.
struct UsernameLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoginMode = true
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isRegistering = false

    var onDismiss: (() -> Void)?

    var body: some View {
        ZStack {
            Color(white: 0.95)
                .ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(appPurple.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .offset(x: -120, y: -80)

                Ellipse()
                    .fill(appPurple.opacity(0.1))
                    .frame(width: 280, height: 280)
                    .offset(x: geo.size.width - 100, y: geo.size.height * 0.5 - 100)
            }

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        (onDismiss ?? { dismiss() })()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.black.opacity(0.6))
                            .padding(10)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.06), radius: 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                Text(isLoginMode ? "Login" : "Register")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.black)
                        TextField("Insert username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 17))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: username) { _, newValue in
                                let lower = newValue.lowercased()
                                if newValue != lower { username = lower }
                            }
                            .cornerRadius(10)
                            .padding(.vertical, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Password")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.black)
                        SecureField("Insert password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 17))
                            .cornerRadius(10)
                            .padding(.vertical, 4)

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                    Button {
                        isLoginMode.toggle()
                    } label: {
                        Text(isLoginMode ? "Don't you have an account? Create one" : "Already have an account? Login")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                    }
                    .padding(.top, 8)

                    if let msg = errorMessage {
                        Text(msg)
                            .font(.system(size: 14))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }

                    Button {
                        let u = username.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !u.isEmpty else { return }
                        errorMessage = nil
                        if isLoginMode {
                            UserDefaults.standard.set(u, forKey: "profile_username")
                            (onDismiss ?? { dismiss() })()
                        } else {
                            Task { await registerUsername(u) }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isRegistering {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isLoginMode ? "Login" : "Register")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 300, height: 50)
                        .background(
                            LinearGradient(
                                colors: [appPurple, Color(red: 0.6, green: 0.4, blue: 0.95)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isRegistering)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(appPurple, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                .padding(.horizontal, 20)
            }
        }
        .onChange(of: username) { _, _ in
            errorMessage = nil
        }
    }

    @MainActor
    private func registerUsername(_ u: String) async {
        isRegistering = true
        defer { isRegistering = false }
        let url = APIConfig.baseURL.appendingPathComponent("auth/register-username")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["username": u])
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return }
            if http.statusCode == 409 {
                errorMessage = usernameAlreadyExistsMessage
                return
            }
            if (200...299).contains(http.statusCode) {
                UserDefaults.standard.set(u, forKey: "profile_username")
                (onDismiss ?? { dismiss() })()
                return
            }
            errorMessage = "This username is already taken."
        } catch {
            errorMessage = "This username is already taken."
        }
    }
}

#Preview {
    UsernameLoginView()
}
