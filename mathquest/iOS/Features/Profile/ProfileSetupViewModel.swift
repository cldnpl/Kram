import Foundation
import FirebaseAuth

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var level: String = "Beginner"
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    let levels = ["Beginner", "Intermediate", "Advanced"]

    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !level.isEmpty
    }

    init() {
        loadExistingData()
    }

    private func loadExistingData() {
        // First check if we have saved profile data
        let savedName = UserDefaults.standard.string(forKey: "profile_name") ?? ""
        let savedLevel = UserDefaults.standard.string(forKey: "profile_level") ?? ""

        if !savedName.isEmpty {
            name = savedName
        } else if let user = Auth.auth().currentUser, let displayName = user.displayName, !displayName.isEmpty {
            // Pre-populate from Firebase user
            name = displayName
        }

        if !savedLevel.isEmpty {
            level = savedLevel
        }
    }

    func submit(onComplete: () -> Void) async {
        guard canSubmit else {
            errorMessage = "Please enter your name and select a level."
            return
        }

        isSubmitting = true
        errorMessage = nil

        UserDefaults.standard.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "profile_name")
        UserDefaults.standard.set(level, forKey: "profile_level")

        isSubmitting = false
        onComplete()
    }
}
