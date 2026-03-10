import Foundation
import FirebaseAuth
import UIKit

private let profilePhotoFilename = "profile_photo.jpg"
private let profilePhotoPathKey = "profile_photo_path"

private struct StreakResponse: Decodable {
    let streak_days: Int
    let active_today: Bool
}

private struct RemoteProfileResponse: Decodable {
    let id: Int?
    let name: String?
    let username: String?
    let age: Int?
    let math_level: String?
    let coin_balance: Int?
    let streak_days: Int?
    let avatar_url: String?
}

private struct UpdateProfileRequestBody: Encodable {
    let name: String
    let username: String
    let math_level: String
    let avatar_url: String
}

private struct UpdateProfileResponse: Decodable {
    let ok: Bool?
    let message: String?
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var profileUsername: String = ""
    @Published var userEmail: String = ""
    @Published var userPhotoURL: URL?
    @Published var profileImage: UIImage?
    @Published var mathLevel: String = ""
    @Published var streakDays = 0
    @Published var lessonsCompleted = 0

    private let client = APIClient()

    var userInitials: String {
        let components = userName.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    func load() {
        userName = UserDefaults.standard.string(forKey: "profile_name") ?? ""
        profileUsername = UserDefaults.standard.string(forKey: "profile_username") ?? ""
        mathLevel = UserDefaults.standard.string(forKey: "profile_level") ?? "Beginner"

        if let path = UserDefaults.standard.string(forKey: profilePhotoPathKey),
           let url = profilePhotoFileURL(filename: path),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            profileImage = image
        } else {
            profileImage = nil
        }

        if let currentUser = Auth.auth().currentUser {
            if userName.isEmpty {
                userName = currentUser.displayName ?? ""
            }
            userEmail = currentUser.email ?? ""
            userPhotoURL = currentUser.photoURL
        } else {
            userEmail = ""
            userPhotoURL = nil
        }

        Task {
            await fetchRemoteProfile()
            await fetchStreak()
        }
    }

    private func resolvedAuthToken() -> String? {
        if let uid = Auth.auth().currentUser?.uid, !uid.isEmpty {
            return uid
        }

        let username = (profileUsername.isEmpty
                        ? (UserDefaults.standard.string(forKey: "profile_username") ?? "")
                        : profileUsername)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if !username.isEmpty {
            return "username:\(username)"
        }

        return nil
    }

    private func fetchRemoteProfile() async {
        guard let token = resolvedAuthToken() else { return }
        do {
            await client.setToken(token)
            let remote: RemoteProfileResponse = try await client.request("profile")

            if let remoteNameRaw = remote.name?.trimmingCharacters(in: .whitespacesAndNewlines) {
                let remoteName = remoteNameRaw
                let isPlaceholder = remoteName.caseInsensitiveCompare("Mock User") == .orderedSame ||
                    remoteName.caseInsensitiveCompare("MathQuest User") == .orderedSame
                if !remoteName.isEmpty && !isPlaceholder {
                    userName = remoteName
                    UserDefaults.standard.set(remoteName, forKey: "profile_name")
                }
            }
            if let remoteUsername = remote.username?.trimmingCharacters(in: .whitespacesAndNewlines), !remoteUsername.isEmpty {
                profileUsername = remoteUsername
                UserDefaults.standard.set(remoteUsername, forKey: "profile_username")
            }
            if let remoteLevel = remote.math_level?.trimmingCharacters(in: .whitespacesAndNewlines), !remoteLevel.isEmpty {
                mathLevel = remoteLevel
                UserDefaults.standard.set(remoteLevel, forKey: "profile_level")
            }
            if let remoteStreak = remote.streak_days {
                streakDays = remoteStreak
            }

            let avatarRaw = remote.avatar_url?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !avatarRaw.isEmpty, let avatarData = avatarDataFromString(avatarRaw), let image = UIImage(data: avatarData) {
                profileImage = image
                cacheProfilePhoto(data: avatarData)
            }
        } catch {
            print("[Profile] remote profile fetch error: \(error)")
        }
    }

    private func fetchStreak() async {
        guard let token = resolvedAuthToken() else { return }
        do {
            await client.setToken(token)
            let res: StreakResponse = try await client.request("streak")
            streakDays = res.streak_days
        } catch {
            print("[Profile] streak fetch error: \(error)")
        }
    }

    func setProfilePhoto(_ image: UIImage?) {
        removeLocalProfilePhoto()
        profileImage = nil

        guard let image else {
            Task { await syncProfileToBackend(avatarURL: "") }
            return
        }

        let normalized = resizedImageIfNeeded(image, maxDimension: 640)
        guard let data = normalized.jpegData(compressionQuality: 0.82) else { return }

        cacheProfilePhoto(data: data)
        profileImage = UIImage(data: data)

        let avatarURL = "data:image/jpeg;base64,\(data.base64EncodedString())"
        Task { await syncProfileToBackend(avatarURL: avatarURL) }
    }

    private func syncProfileToBackend(avatarURL: String) async {
        guard let token = resolvedAuthToken() else { return }
        let payload = UpdateProfileRequestBody(
            name: userName.trimmingCharacters(in: .whitespacesAndNewlines),
            username: profileUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            math_level: mathLevel.trimmingCharacters(in: .whitespacesAndNewlines),
            avatar_url: avatarURL
        )
        do {
            let body = try JSONEncoder().encode(payload)
            await client.setToken(token)
            let _: UpdateProfileResponse = try await client.request(
                "profile",
                method: "PUT",
                body: body
            )
        } catch {
            print("[Profile] avatar sync error: \(error)")
        }
    }

    private func removeLocalProfilePhoto() {
        if let path = UserDefaults.standard.string(forKey: profilePhotoPathKey),
           let url = profilePhotoFileURL(filename: path) {
            try? FileManager.default.removeItem(at: url)
        }
        UserDefaults.standard.removeObject(forKey: profilePhotoPathKey)
    }

    private func cacheProfilePhoto(data: Data) {
        guard let url = profilePhotoFileURL(filename: profilePhotoFilename) else { return }
        do {
            try data.write(to: url)
            UserDefaults.standard.set(profilePhotoFilename, forKey: profilePhotoPathKey)
        } catch {}
    }

    private func avatarDataFromString(_ raw: String) -> Data? {
        if raw.hasPrefix("data:image"), let commaIndex = raw.firstIndex(of: ",") {
            let b64 = String(raw[raw.index(after: commaIndex)...])
            return Data(base64Encoded: b64)
        }
        return Data(base64Encoded: raw)
    }

    private func resizedImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        if maxSide <= maxDimension {
            return image
        }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func profilePhotoFileURL(filename: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename)
    }

    func signOut() {
        removeLocalProfilePhoto()
        UserDefaults.standard.removeObject(forKey: "profile_name")
        UserDefaults.standard.removeObject(forKey: "profile_username")
        UserDefaults.standard.removeObject(forKey: "profile_level")
        CoinWallet.resetLocalBonus()
        userName = ""
        profileUsername = ""
        userEmail = ""
        userPhotoURL = nil
        profileImage = nil
        mathLevel = "Beginner"
    }
}
