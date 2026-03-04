import SwiftUI

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("profile_name") private var profileName = ""
    @AppStorage("profile_level") private var profileLevel = "beginner"
    @AppStorage("settings_dark_mode") private var darkMode = false
    @AppStorage("settings_notifications") private var notificationsEnabled = true
    @AppStorage("settings_sound") private var soundEnabled = true
    @AppStorage("settings_language") private var language = "en"
    @AppStorage("settings_difficulty") private var difficulty = "medio"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                settingsSection(title: L10n.profile) {
                    HStack {
                        Label(L10n.name, systemImage: "person.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(profileName.isEmpty ? "—" : profileName)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                settingsSection(title: L10n.studyPreferences) {
                    VStack(spacing: 0) {
                        Picker(selection: $difficulty) {
                            Text(L10n.difficultyEasy).tag("facile")
                            Text(L10n.difficultyMedium).tag("medio")
                            Text(L10n.difficultyHard).tag("difficile")
                        } label: {
                            Label(L10n.difficulty, systemImage: "chart.bar.fill")
                        }
                        .pickerStyle(.menu)
                        .tint(appPurple)

                        Divider().padding(.vertical, 8)

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
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
            )
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
