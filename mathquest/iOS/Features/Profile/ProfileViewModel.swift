import Foundation
import FirebaseAuth
import UIKit

private let profilePhotoFilename = "profile_photo.jpg"
private let profilePhotoPathKey = "profile_photo_path"

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
        }
    }

    func setProfilePhoto(_ image: UIImage?) {
        if let path = UserDefaults.standard.string(forKey: profilePhotoPathKey),
           let url = profilePhotoFileURL(filename: path) {
            try? FileManager.default.removeItem(at: url)
        }
        UserDefaults.standard.removeObject(forKey: profilePhotoPathKey)
        profileImage = nil

        guard let image else { return }

        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        let filename = profilePhotoFilename
        guard let url = profilePhotoFileURL(filename: filename) else { return }
        do {
            try data.write(to: url)
            UserDefaults.standard.set(filename, forKey: profilePhotoPathKey)
            profileImage = image
        } catch {}
    }

    private func profilePhotoFileURL(filename: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename)
    }

    func signOut() {
        if let path = UserDefaults.standard.string(forKey: profilePhotoPathKey),
           let url = profilePhotoFileURL(filename: path) {
            try? FileManager.default.removeItem(at: url)
        }
        UserDefaults.standard.removeObject(forKey: profilePhotoPathKey)
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
