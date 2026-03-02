import Foundation

@MainActor
final class CameraViewModel: ObservableObject {
    @Published var usesRemaining = 3
    @Published var solution: String?

    func capture() async {
        // TODO: capture image, POST /camera/solve
    }
}
