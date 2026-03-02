import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var streakDays = 0
    @Published var lessonsCompleted = 0

    func load() async {
        // TODO: GET /profile/stats
    }

    func signOut() {
        // Clear token / session when implemented
    }
}
