import Foundation
import FirebaseAuth

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var username: String = ""
    @Published var level: String = "Beginner"
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var isUsernameAvailable: Bool?
    @Published var isCheckingUsername = false

    let levels = ["Beginner", "Intermediate", "Advanced"]

    private var usernameCheckTask: Task<Void, Never>?

    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isUsernameAvailable == true
    }

    init() {
        Task { @MainActor in
            loadExistingData()
        }
    }

    private func loadExistingData() {
        let savedName = UserDefaults.standard.string(forKey: "profile_name") ?? ""
        let savedLevel = UserDefaults.standard.string(forKey: "profile_level") ?? ""
        let savedUsername = UserDefaults.standard.string(forKey: "profile_username") ?? ""

        if !savedName.isEmpty {
            name = savedName
        } else if let user = Auth.auth().currentUser, let displayName = user.displayName, !displayName.isEmpty {
            name = displayName
        }

        if !savedLevel.isEmpty {
            level = savedLevel
        }

        if !savedUsername.isEmpty {
            username = savedUsername
        }
    }

    func onUsernameChanged() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        print("[ProfileSetup] onUsernameChanged: raw='\(username)' trimmed='\(trimmed)'")
        guard !trimmed.isEmpty else {
            print("[ProfileSetup] username empty — resetting state")
            isUsernameAvailable = nil
            isCheckingUsername = false
            usernameCheckTask?.cancel()
            return
        }

        isCheckingUsername = true
        isUsernameAvailable = nil

        usernameCheckTask?.cancel()
        usernameCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            guard !Task.isCancelled else {
                print("[ProfileSetup] debounce task cancelled for '\(trimmed)'")
                return
            }
            await checkUsernameAvailability(trimmed)
        }
    }

    private func checkUsernameAvailability(_ username: String) async {
        let urlString = "\(APIConfig.baseURLString)/auth/check-username?username=\(username)"
        print("[ProfileSetup] checking availability: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("[ProfileSetup] invalid URL")
            isCheckingUsername = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            print("[ProfileSetup] response status=\(statusCode) body=\(body)")
            guard !Task.isCancelled else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let available = json["available"] as? Bool {
                print("[ProfileSetup] available=\(available)")
                isUsernameAvailable = available
            } else {
                print("[ProfileSetup] failed to parse 'available' from response")
                isUsernameAvailable = nil
            }
        } catch {
            print("[ProfileSetup] network error: \(error)")
            guard !Task.isCancelled else { return }
            isUsernameAvailable = nil
        }
        isCheckingUsername = false
        print("[ProfileSetup] canSubmit=\(canSubmit) name='\(name)' username='\(username)' isUsernameAvailable=\(String(describing: isUsernameAvailable))")
    }

    func submit(onComplete: () -> Void) async {
        guard canSubmit else {
            errorMessage = "Please enter your name, username, and select a level."
            return
        }

        isSubmitting = true
        errorMessage = nil

        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Register the username on the server
        do {
            guard let url = URL(string: "\(APIConfig.baseURLString)/auth/register-username") else {
                errorMessage = "Invalid server URL"
                isSubmitting = false
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = try JSONSerialization.data(withJSONObject: ["username": trimmedUsername])
            request.httpBody = body

            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 409 {
                errorMessage = "Username is already taken. Please choose another."
                isUsernameAvailable = false
                isSubmitting = false
                return
            }
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                errorMessage = "Failed to register username: \(body)"
                isSubmitting = false
                return
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            isSubmitting = false
            return
        }

        UserDefaults.standard.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "profile_name")
        UserDefaults.standard.set(trimmedUsername, forKey: "profile_username")
        UserDefaults.standard.set(level, forKey: "profile_level")

        isSubmitting = false
        onComplete()
    }
}
