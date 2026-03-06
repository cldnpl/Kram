import SwiftUI

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("profile_name") private var profileName = ""
    @AppStorage("profile_level") private var profileLevel = "Beginner"
    @AppStorage("settings_dark_mode") private var darkMode = false
    @AppStorage("settings_notifications") private var notificationsEnabled = true
    @AppStorage("settings_sound") private var soundEnabled = true
    @AppStorage("settings_language") private var language = "en"
    @AppStorage("settings_difficulty") private var difficulty = "medio"
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                settingsSection(title: L10n.profile) {
                    HStack(spacing: 12) {
                        Label(L10n.name, systemImage: "person.fill")
                            .foregroundStyle(.primary)
                        TextField(L10n.name, text: $profileName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 17))
                    }
                    .padding(.vertical, 4)
                }

                settingsSection(title: "Math Level") {
                    VStack(spacing: 10) {
                        ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) { level in
                            mathLevelCard(
                                level: level,
                                description: mathLevelDescription(for: level),
                                icon: mathLevelIcon(for: level),
                                isSelected: profileLevel == level
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    profileLevel = level
                                }
                            }
                        }
                    }
                }

                settingsSection(title: L10n.studyPreferences) {
                    VStack(spacing: 0) {

                        Toggle(isOn: $notificationsEnabled) {
                            Label(L10n.studyReminder, systemImage: "bell.fill")
                        }
                        .tint(appPurple)

                        Divider().padding(.vertical, 8)

                        Toggle(isOn: $soundEnabled) {
                            Label(L10n.sounds, systemImage: "speaker.wave.2.fill")
                        }
                        .tint(appPurple)
                    }
                }

                settingsSection(title: L10n.interface) {
                    VStack(spacing: 0) {
                        Toggle(isOn: $darkMode) {
                            Label(L10n.darkTheme, systemImage: "moon.fill")
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
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.settingsTitle)
        .navigationBarTitleDisplayMode(.large)
    }

    private func mathLevelDescription(for level: String) -> String {
        switch level {
        case "Beginner": return "Basic arithmetic, fractions, decimals"
        case "Intermediate": return "Algebra, geometry, basic equations"
        case "Advanced": return "Calculus, trigonometry, advanced algebra"
        default: return ""
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
