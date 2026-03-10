import SwiftUI

/// Register page: stesso layout del Login (sfondo bianco, viola dell'app, card bianca) con titolo "Register".
struct UsernamePasswordRegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    var onDismiss: (() -> Void)?

    /// Viola dell'app (stesso usato in onboarding e profile).
    private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Forme viola chiare (viola dell'app)
            GeometryReader { geo in
                Circle()
                    .fill(appPurple.opacity(0.18))
                    .frame(width: 280, height: 280)
                    .blur(radius: 60)
                    .offset(x: -80, y: -20)
                Circle()
                    .fill(appPurple.opacity(0.12))
                    .frame(width: 220, height: 220)
                    .blur(radius: 50)
                    .offset(x: geo.size.width - 100, y: geo.size.height * 0.4)
                Circle()
                    .fill(appPurple.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .blur(radius: 40)
                    .offset(x: geo.size.width * 0.1, y: geo.size.height - 120)
            }

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                        onDismiss?()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(10)
                    }
                    .padding(.leading, 8)
                    .padding(.top, 8)
                    Spacer()
                }

                ScrollView {
                    VStack(spacing: 24) {
                        Text(L10n.register)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.primary)
                            .padding(.top, 8)

                        // Card bianca
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(L10n.usernameLabel)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                TextField(L10n.usernameLabel, text: $username)
                                    .textContentType(.username)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .font(.system(size: 17))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)

                            Divider()
                                .background(Color(.separator))
                                .padding(.leading, 20)

                            VStack(alignment: .leading, spacing: 12) {
                                Text(L10n.passwordLabel)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                SecureField(L10n.passwordLabel, text: $password)
                                    .textContentType(.newPassword)
                                    .font(.system(size: 17))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)

                            Divider()
                                .background(Color(.separator))
                                .padding(.leading, 20)

                            VStack(alignment: .leading, spacing: 12) {
                                Text(L10n.confirmPassword)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                SecureField(L10n.confirmPassword, text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .font(.system(size: 17))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)

                            Divider()
                                .background(Color(.separator))
                                .padding(.leading, 20)

                            Button {
                                dismiss()
                                onDismiss?()
                            } label: {
                                HStack(spacing: 4) {
                                    Text(L10n.alreadyHaveAccount)
                                        .foregroundStyle(.secondary)
                                    Text(L10n.signIn)
                                        .foregroundStyle(appPurple)
                                        .fontWeight(.semibold)
                                }
                                .font(.system(size: 15))
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 20)
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            submitRegister()
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(L10n.register)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(appPurple)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading || username.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func submitRegister() {
        errorMessage = nil
        guard password == confirmPassword else {
            errorMessage = L10n.passwordsNotMatch
            return
        }
        isLoading = true
        Task {
            // TODO: integrate Firebase createUser or backend registration
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                isLoading = false
                errorMessage = L10n.registerNotConnected
            }
        }
    }
}

#Preview {
    UsernamePasswordRegisterView()
}
