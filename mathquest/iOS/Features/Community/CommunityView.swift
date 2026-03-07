import SwiftUI

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

struct CommunityView: View {
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    /// Mock utenti per la ricerca (sostituire con API quando disponibile)
    private let mockUsers = ["nomeutete", "mario_rossi", "laura_math", "alex_solver"]
    private var filteredUsers: [String] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let query = searchText.lowercased()
        return mockUsers.filter { $0.lowercased().contains(query) }
    }

    /// URL avatar generato da username (sostituire con URL reale quando API disponibile)
    private func avatarURL(for username: String) -> URL? {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        return URL(string: "https://api.dicebear.com/7.x/initials/png?seed=\(encoded)&size=88")
    }

    private var homeGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: appPurple, location: 0),
                .init(color: Color(red: 0.85, green: 0.82, blue: 0.98), location: 0.25),
                .init(color: Color(red: 0.93, green: 0.91, blue: 0.99), location: 0.3),
                .init(color: Color(red: 0.97, green: 0.96, blue: 1.0), location: 0.4),
                .init(color: Color.white, location: 0.55)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            homeGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Community")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 56)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Add a friend", text: $searchText)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.secondary)
                            .focused($isSearchFocused)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()

                        if !filteredUsers.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(filteredUsers, id: \.self) { username in
                                    UserSearchRow(
                                        username: username,
                                        profileImageURL: avatarURL(for: username)
                                    ) {
                                        // TODO: invio richiesta amicizia
                                    }
                                    if username != filteredUsers.last {
                                        Divider()
                                            .padding(.leading, 56)
                                    }
                                }
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        CommunityCard(
                            title: "Global arena",
                            icon: "globe",
                            action: {}
                        )
                        .frame(maxWidth: .infinity, minHeight: 150)

                        CommunityCard(
                            title: "Challenge a friend",
                            icon: "person.2.wave.2.fill",
                            action: {}
                        )
                        .frame(maxWidth: .infinity, minHeight: 150)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
    }
}

private struct UserSearchRow: View {
    let username: String
    let profileImageURL: URL?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ProfileImageView(url: profileImageURL)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                Text("@\(username)")
                    .font(.body)
                    .foregroundStyle(.black)

                Spacer()

                Image(systemName: "person.fill.badge.plus")
                    .font(.title2)
                    .foregroundStyle(appPurple)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileImageView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        profilePlaceholder
                    case .empty:
                        profilePlaceholder
                    @unknown default:
                        profilePlaceholder
                    }
                }
            } else {
                profilePlaceholder
            }
        }
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundStyle(.gray.opacity(0.6))
            )
    }
}

private struct CommunityCard: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(appPurple)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(appPurple, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
  

#Preview {
    CommunityView()
}
