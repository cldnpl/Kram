import SwiftUI

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

/// View for login with username and password.
struct UsernameLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?

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

                Text(L10n.login)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.usernameLabel)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.black)
                        TextField(L10n.insertUsername, text: $username)
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
                        Text(L10n.passwordLabel)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.black)
                        SecureField(L10n.insertPassword, text: $password)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 17))
                            .cornerRadius(10)
                            .padding(.vertical, 4)

                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

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
                        UserDefaults.standard.set(u, forKey: "profile_username")
                        (onDismiss ?? { dismiss() })()
                    } label: {
                        Text(L10n.login)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
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

}

#Preview {
    UsernameLoginView()
}
