import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var name = ""
    @Published var age: Int = 10
    @Published var mathLevel = "beginner"

    func submit() async {
        // TODO: POST /onboarding
    }
}
