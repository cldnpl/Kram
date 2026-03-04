import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @State private var showLogin = false

    var body: some View {
        let isAuthenticated = authManager.isAuthenticated

        ScrollView {
            VStack(spacing: 24) {
                // Profile header
                VStack(spacing: 16) {
                    // Avatar
                    ZStack {
                        if let photoURL = viewModel.userPhotoURL {
                            AsyncImage(url: photoURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
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
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)

                    // Name and email
                    VStack(spacing: 4) {
                        Text(viewModel.userName.isEmpty ? "User" : viewModel.userName)
                            .font(.system(size: 24, weight: .bold))

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
                    MenuRow(icon: "gearshape.fill", title: "Settings", color: .gray) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            EmptyView()
                        }
                        .opacity(0)
                    }

                    MenuRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .blue) {
                        EmptyView()
                    }

                    MenuRow(icon: "star.fill", title: "Rate the App", color: .yellow) {
                        EmptyView()
                    }
                }
                .padding(.horizontal, 20)

                // Sign out button
                Button {
                    if isAuthenticated {
                        authManager.signOut()
                        viewModel.signOut()
                    } else {
                        showLogin = true
                    }
                } label: {
                    HStack {
                        Image(systemName: isAuthenticated ? "rectangle.portrait.and.arrow.right" : "person.badge.plus")
                        Text(isAuthenticated ? "Sign Out" : "Sign In")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isAuthenticated ? .red : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isAuthenticated ? Color.red.opacity(0.1) : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .onAppear {
            viewModel.load()
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(showCloseButton: true)
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                showLogin = false
            }
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
    }
}
