import Foundation

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: String = ""
    @Published var level: String = "Beginner"
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    let levels = ["Beginner", "Intermediate", "Advanced"]

    var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(age) != nil &&
        !level.isEmpty
    }

    func submit(onComplete: () -> Void) async {
        guard canSubmit else {
            errorMessage = "Please complete all profile fields."
            return
        }

        guard let parsedAge = Int(age), (5...120).contains(parsedAge) else {
            errorMessage = "Please enter a valid age."
            return
        }

        isSubmitting = true
        errorMessage = nil

        UserDefaults.standard.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "profile_name")
        UserDefaults.standard.set(parsedAge, forKey: "profile_age")
        UserDefaults.standard.set(level, forKey: "profile_level")

        isSubmitting = false
        onComplete()
    }
}
