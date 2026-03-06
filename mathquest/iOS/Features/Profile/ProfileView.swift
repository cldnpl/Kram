import PhotosUI
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var tabSelection: TabSelection
    @State private var showLogin = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        let isAuthenticated = authManager.isAuthenticated
        let isLoggedIn = isAuthenticated || !viewModel.profileUsername.isEmpty

        ScrollView {
            VStack(spacing: 24) {
                // Profile header
                VStack(spacing: 16) {
                    // Avatar (tap per cambiare foto)
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

                    // Name, username (solo se loggato), email
                    VStack(spacing: 4) {
                        Text(viewModel.userName.isEmpty ? "User" : viewModel.userName)
                            .font(.system(size: 24, weight: .bold))

                        if isLoggedIn && !viewModel.profileUsername.isEmpty {
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

                    // Math level badge
                    HStack(spacing: 6) {
                        Image(systemName: levelIcon(for: viewModel.mathLevel))
                            .font(.system(size: 12, weight: .semibold))
                        Text(viewModel.mathLevel)
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
                .padding(.top, 20)

                // Stats cards
                HStack(spacing: 12) {
                    StatCard(
                        icon: "flame.fill",
                        value: "\(viewModel.streakDays)",
                        label: "Day Streak",
                        color: .orange
                    )

                    StatCard(
                        icon: "book.fill",
                        value: "\(viewModel.lessonsCompleted)",
                        label: "Lessons",
                        color: Color(red: 0.4, green: 0.3, blue: 0.9)
                    )
                }
                .padding(.horizontal, 20)

                // Menu items
                VStack(spacing: 12) {
                    MenuRow(icon: "gearshape.fill", title: L10n.settingsTitle, color: .gray) {
                        SettingsView()
                    }

                    MenuRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .blue) {
                        EmptyView()
                    }

                    MenuRow(icon: "star.fill", title: "Rate the App", color: .yellow) {
                        EmptyView()
                    }
                }
                .padding(.horizontal, 20)

                // Sign In / Sign Out
                Button {
                    if isLoggedIn {
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
        if let image = viewModel.profileImage {
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
        switch level {
        case "Beginner":
            return "leaf.fill"
        case "Intermediate":
            return "flame.fill"
        case "Advanced":
            return "bolt.fill"
        default:
            return "star.fill"
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
        .background(.white)
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
            .background(.white)
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
