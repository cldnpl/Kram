import SwiftUI
import FirebaseAuth

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("profile_name") private var profileName = ""
    @AppStorage("profile_level") private var profileLevel = "Beginner"
    @AppStorage("settings_sound") private var soundEnabled = true
    @AppStorage("settings_language") private var language = "en"
    @AppStorage("settings_difficulty") private var difficulty = "medio"
    @AppStorage("profile_username") private var profileUsername = ""
    @State private var showDeleteConfirmation = false
    @State private var editingUsername = ""
    @State private var isUsernameAvailable: Bool?
    @State private var isCheckingUsername = false
    @State private var profileSyncTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                settingsSection(title: L10n.profile) {
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Label(L10n.name, systemImage: "person.fill")
                                .foregroundStyle(.primary)
                            TextField(L10n.name, text: $profileName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 17))
                                .onChange(of: profileName) { _, newValue in
                                    Task {
                                        await _setProfileName(newValue)
                                    }
                                }
                        }
                        .padding(.vertical, 4)

                        Divider()
                            .padding(.vertical, 8)

                        HStack(spacing: 12) {
                            Label(L10n.usernameLabel, systemImage: "at")
                                .foregroundStyle(.primary)
                            TextField(L10n.usernameLabel, text: $editingUsername)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(size: 17))
                                .onChange(of: editingUsername) { _, newValue in
                                    checkUsernameDebounced(newValue)
                                }

                            if isCheckingUsername {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else if let available = isUsernameAvailable {
                                Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(available ? .green : .red)
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onAppear {
                    editingUsername = profileUsername
                }

                settingsSection(title: L10n.mathLevel) {
                    VStack(spacing: 10) {
                        ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) { level in
                            mathLevelCard(
                                level: localizedLevelName(for: level),
                                description: mathLevelDescription(for: level),
                                icon: mathLevelIcon(for: level),
                                isSelected: profileLevel == level
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    profileLevel = level
                                }
                                scheduleProfileSync()
                            }
                        }
                    }
                }

                settingsSection(title: L10n.studyPreferences) {
                    VStack(spacing: 0) {
                        Toggle(isOn: $soundEnabled) {
                            Label(L10n.sounds, systemImage: "speaker.wave.2.fill")
                        }
                        .tint(appPurple)
                    }
                }

                settingsSection(title: L10n.accountLanguage) {
                    VStack(spacing: 0) {
                        Picker(selection: $language) {
                            Text(L10n.languageItalian).tag("it")
                            Text(L10n.languageEnglish).tag("en")
                            Text(L10n.languageFrench).tag("fr")
                            Text(L10n.languageSpanish).tag("es")
                            Text(L10n.languageUzbek).tag("uz")
                        } label: {
                            Label(L10n.language, systemImage: "globe")
                        }
                        .pickerStyle(.menu)
                        .tint(appPurple)
                    }
                }

                if authManager.isAuthenticated || !profileUsername.isEmpty {
                    settingsSection(title: L10n.account) {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label(L10n.deleteAccount, systemImage: "trash.fill")
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.settingsTitle)
        .navigationBarTitleDisplayMode(.large)
        .alert(L10n.deleteAccount, isPresented: $showDeleteConfirmation) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.deleteAccount, role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(L10n.deleteAccountMessage)
        }
    }

    @State private var _usernameCheckTask: Task<Void, Never>?

    private func checkUsernameDebounced(_ newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // If same as current saved username, no check needed
        if trimmed == profileUsername.lowercased() {
            isUsernameAvailable = nil
            isCheckingUsername = false
            return
        }

        guard !trimmed.isEmpty else {
            isUsernameAvailable = nil
            isCheckingUsername = false
            return
        }

        isCheckingUsername = true
        isUsernameAvailable = nil

        _usernameCheckTask?.cancel()
        _usernameCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }

            guard let url = URL(string: "\(APIConfig.baseURLString)/auth/check-username?username=\(trimmed)") else {
                await MainActor.run { isCheckingUsername = false }
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let available = json["available"] as? Bool {
                    await MainActor.run {
                        isUsernameAvailable = available
                        isCheckingUsername = false
                        if available {
                            saveUsername(trimmed)
                        }
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { isCheckingUsername = false }
            }
        }
    }

    private func saveUsername(_ username: String) {
        profileUsername = username
        scheduleProfileSync()
    }

    private func _setProfileName(_ name: String) async {
        UserDefaults.standard.set(name, forKey: "profile_name")
        scheduleProfileSync()
    }

    private func resolveAuthToken() -> String? {
        if let uid = Auth.auth().currentUser?.uid, !uid.isEmpty {
            return uid
        }
        let username = profileUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !username.isEmpty {
            return "username:\(username)"
        }
        return nil
    }

    private func scheduleProfileSync() {
        profileSyncTask?.cancel()
        profileSyncTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await syncProfileToBackend()
        }
    }

    private func syncProfileToBackend() async {
        guard let token = resolveAuthToken() else { return }
        guard let url = URL(string: "\(APIConfig.baseURLString)/profile") else { return }

        let payload: [String: Any] = [
            "name": profileName.trimmingCharacters(in: .whitespacesAndNewlines),
            "username": profileUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            "math_level": profileLevel.trimmingCharacters(in: .whitespacesAndNewlines),
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        _ = try? await URLSession.shared.data(for: request)
    }

    private func deleteAccount() {
        // Clear all local data
        profileName = ""
        profileUsername = ""
        UserDefaults.standard.removeObject(forKey: "profile_username")
        UserDefaults.standard.removeObject(forKey: "profile_name")
        UserDefaults.standard.removeObject(forKey: "profile_level")
        UserDefaults.standard.removeObject(forKey: "profile_photo_path")
        CoinWallet.resetLocalBonus()

        // Sign out from Firebase if authenticated
        if authManager.isAuthenticated {
            authManager.signOut()
        }

        // Pop back to profile
        dismiss()
    }

    private func mathLevelDescription(for level: String) -> String {
        switch level {
        case "Beginner": return L10n.levelDescBeginner
        case "Intermediate": return L10n.levelDescIntermediate
        case "Advanced": return L10n.levelDescAdvanced
        default: return ""
        }
    }

    private func localizedLevelName(for level: String) -> String {
        switch level {
        case "Beginner": return L10n.levelBeginner
        case "Intermediate": return L10n.levelIntermediate
        case "Advanced": return L10n.levelAdvanced
        default: return level
        }
    }

    private func mathLevelIcon(for level: String) -> String {
        switch level {
        case "Beginner": return "leaf.fill"
        case "Intermediate": return "flame.fill"
        case "Advanced": return "bolt.fill"
        default: return "star.fill"
        }
    }

    private func mathLevelCard(level: String, description: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [appPurple, Color(red: 0.6, green: 0.4, blue: 0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .gray)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(level)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? appPurple : Color.gray.opacity(0.3))
            }
            .padding(14)
            .background(colorScheme == .dark ? Color(.tertiarySystemBackground) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? appPurple : .clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
            )
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
