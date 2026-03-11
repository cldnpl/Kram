import PhotosUI
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var tabSelection: TabSelection
    @AppStorage("session_logged_in") private var sessionLoggedIn = false
    @AppStorage("profile_level") private var storedProfileLevel = "Beginner"
    @State private var showLogin = false
    @State private var showStreak = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var isLoggedIn: Bool {
        authManager.isAuthenticated || sessionLoggedIn
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile header
                VStack(spacing: 16) {
                    // Avatar (tap per cambiare foto)
                    if isLoggedIn {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            ZStack {
                                avatarContent
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                                    .offset(x: 38, y: 38)
                            }
                        }
                        .buttonStyle(.plain)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    } else {
                        avatarContent
                    }

                    // Name, username (solo se loggato), email
                    if isLoggedIn {
                        VStack(spacing: 4) {
                            Text(viewModel.userName.isEmpty ? L10n.userFallback : viewModel.userName)
                                .font(.system(size: 24, weight: .bold))

                            if !viewModel.profileUsername.isEmpty {
                                Text("@\(viewModel.profileUsername)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }

                            if !viewModel.userEmail.isEmpty {
                                Text(viewModel.userEmail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text(L10n.userFallback)
                            .font(.system(size: 24, weight: .bold))
                    }

                    // Math level badge
                    if isLoggedIn {
                        HStack(spacing: 6) {
                            Image(systemName: levelIcon(for: viewModel.mathLevel))
                                .font(.system(size: 12, weight: .semibold))
                            Text(localizedLevelName(viewModel.mathLevel))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.95)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 20)

                // Stats cards
                HStack(spacing: 12) {
                    Button {
                        showStreak = true
                    } label: {
                        StatCard(
                            icon: "flame.fill",
                            value: "\(viewModel.streakDays)",
                            label: L10n.dayStreak,
                            color: .orange
                        )
                    }
                    .buttonStyle(.plain)

                    StatCard(
                        icon: "book.fill",
                        value: "\(viewModel.lessonsCompleted)",
                        label: L10n.lessonsCompleted,
                        color: Color(red: 0.4, green: 0.3, blue: 0.9)
                    )
                }
                .padding(.horizontal, 20)
                .sheet(isPresented: $showStreak) {
                    NavigationStack {
                        StreakCalendarView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        showStreak = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                    }
                }

                // Menu items
                VStack(spacing: 12) {
                    MenuRow(icon: "gearshape.fill", title: L10n.settingsTitle, color: .gray) {
                        SettingsView()
                    }

                    MenuRow(icon: "questionmark.circle.fill", title: L10n.helpSupport, color: .blue) {
                        EmptyView()
                    }

                    MenuRow(icon: "star.fill", title: L10n.rateApp, color: .yellow) {
                        EmptyView()
                    }
                }
                .padding(.horizontal, 20)

                // Sign In / Sign Out
                Button {
                    if isLoggedIn {
                        sessionLoggedIn = false
                        authManager.signOut()
                        viewModel.signOut()
                    } else {
                        showLogin = true
                    }
                } label: {
                    HStack {
                        Image(systemName: isLoggedIn ? "rectangle.portrait.and.arrow.right" : "person.badge.plus")
                        Text(isLoggedIn ? L10n.signOut : L10n.signIn)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isLoggedIn ? .red : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isLoggedIn ? Color.red.opacity(0.1) : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.profileTab)
        .onAppear {
            viewModel.load()
            viewModel.applyStoredMathLevel(storedProfileLevel)
        }
        .onChange(of: authManager.isAuthenticated) { _, _ in
            viewModel.load()
        }
        .onChange(of: storedProfileLevel) { _, newValue in
            viewModel.applyStoredMathLevel(newValue)
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(
                showCloseButton: true,
                onUsernameLoginSuccess: {
                    showLogin = false
                    tabSelection.selectedTab = 0
                }
            )
        }
        .onChange(of: authManager.isAuthenticated) { _, authenticated in
            if authenticated {
                showLogin = false
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                do {
                    let data = try await newItem.loadTransferable(type: Data.self)
                    await MainActor.run {
                        selectedPhotoItem = nil
                    }
                    guard let data, let image = UIImage(data: data) else { return }
                    await MainActor.run {
                        viewModel.setProfilePhoto(image)
                    }
                } catch {}
            }
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if !isLoggedIn {
            anonymousAvatar
        } else if let image = viewModel.profileImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        } else if let photoURL = viewModel.userPhotoURL {
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    initialsView
                case .empty:
                    ProgressView()
                @unknown default:
                    initialsView
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var anonymousAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 100, height: 100)
            Image(systemName: "person.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)

            Text(viewModel.userInitials)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func levelIcon(for level: String) -> String {
        switch normalizedLevel(level) {
        case "Beginner":
            return "leaf.fill"
        case "Intermediate":
            return "flame.fill"
        case "Advanced":
            return "bolt.fill"
        default:
            return "leaf.fill"
        }
    }

    private func localizedLevelName(_ level: String) -> String {
        switch normalizedLevel(level) {
        case "Beginner":
            return L10n.levelBeginner
        case "Intermediate":
            return L10n.levelIntermediate
        case "Advanced":
            return L10n.levelAdvanced
        default:
            return L10n.levelBeginner
        }
    }

    private func normalizedLevel(_ raw: String) -> String {
        let normalized = raw
            .folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        switch normalized {
        case "beginner", "principiante", "debutant", "debutante", "basico", "boshlangich", "boshlang'ich":
            return "Beginner"
        case "intermediate", "intermedio", "intermediaire", "orta", "o'rta":
            return "Intermediate"
        case "advanced", "avanzato", "avance", "avanzado", "yuqori":
            return "Advanced"
        default:
            return "Beginner"
        }
    }
}

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 28, weight: .bold))
            }
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

private struct MenuRow<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthManager())
            .environmentObject(TabSelection())
    }
}
