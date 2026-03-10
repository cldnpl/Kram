import Combine
import Foundation
import ImageIO
import UIKit
import FirebaseAuth

@MainActor
final class CameraViewModel: ObservableObject {
    private static let unlimitedValue = -1

    @Published var state: CameraState = .idle
    @Published var usesRemaining: Int
    @Published var dailyLimit: Int
    @Published var showHistory = false
    @Published var showCameraPermissionSheet = false
    @Published var showLoginPrompt = false
    @Published var history: [HistoryItem] = []
    @Published private(set) var focusRectNormalized = CGRect(x: 0.2, y: 0.35, width: 0.6, height: 0.3)

    let cameraService = CameraService()
    private let client = APIClient()
    private var cancellables = Set<AnyCancellable>()

    var isGuest: Bool {
        Auth.auth().currentUser == nil &&
        !UserDefaults.standard.bool(forKey: "session_logged_in")
    }

    init() {
        let limit = Self.resolvedDailyLimit()
        dailyLimit = limit
        usesRemaining = limit

        cameraService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        Task {
            if Auth.auth().currentUser != nil {
                await client.setToken("mock-dev-token")
            } else {
                await client.setToken(nil)
            }
        }
    }

    private static func resolvedDailyLimit() -> Int {
        let loggedIn = Auth.auth().currentUser != nil ||
            UserDefaults.standard.bool(forKey: "session_logged_in")
        if loggedIn {
            let tier = SubscriptionTier.current
            return tier.cameraDailyLimit ?? unlimitedValue
        } else {
            return SubscriptionTier.guestDailyLimit
        }
    }

    /// Call after a successful login to refresh limits without recreating the view model.
    func refreshAfterLogin() async {
        let limit = Self.resolvedDailyLimit()
        dailyLimit = limit
        usesRemaining = limit

        if Auth.auth().currentUser != nil {
            await client.setToken("mock-dev-token")
        }

        await fetchStatus()
    }

    func setupCamera() async {
        cameraService.refreshAuthorizationStatus()

        if cameraService.authorizationStatus == .notDetermined {
            showCameraPermissionSheet = true
        } else if cameraService.isAuthorized {
            await cameraService.setupCamera()
        }

        await fetchStatus()
    }

    func resumeCameraIfNeeded() async {
        cameraService.refreshAuthorizationStatus()
        guard cameraService.isAuthorized else {
            return
        }
        await cameraService.setupCamera()
    }

    func requestCameraPermissionFromSheet() async {
        let granted = await cameraService.requestCameraAccess()
        showCameraPermissionSheet = false

        guard granted else {
            return
        }

        await cameraService.setupCamera()
    }

    func dismissCameraPermissionSheet() {
        showCameraPermissionSheet = false
    }

    func fetchStatus() async {
        do {
            let response: StatusResponse = try await client.request("camera/status")
            applyStatus(response)
        } catch {
            print("Failed to fetch status: \(error)")
            applyFallbackFromTier()
        }
    }

    func capture() async {
        await capture(focusRectNormalized: focusRectNormalized)
    }

    func capture(focusRectNormalized: CGRect?) async {
        guard canStartSolve() else {
            return
        }

        state = .scanning

        do {
            // Small delay to show scanning animation
            try await Task.sleep(nanoseconds: 500_000_000)

            guard let image = try await cameraService.capturePhoto() else {
                state = .error("Failed to capture image")
                return
            }

            await solve(
                image: image,
                setProcessingState: true,
                cropRectNormalized: focusRectNormalized
            )
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func solveFromGalleryData(_ data: Data?) async {
        guard canStartSolve() else {
            return
        }

        guard let data,
              let image = downsampledImage(from: data, maxDimension: 1600) ?? UIImage(data: data) else {
            state = .error("Failed to load selected image")
            return
        }

        await solveFromGalleryImage(image)
    }

    func solveFromGalleryImage(_ image: UIImage) async {
        guard canStartSolve() else {
            return
        }

        await solve(image: image, setProcessingState: true, cropRectNormalized: nil)
    }

    func setError(_ message: String) {
        state = .error(message)
    }

    func updateFocusRect(normalizedRect: CGRect) {
        let clampedRect = normalizedRect
            .standardized
            .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))

        guard !clampedRect.isNull, clampedRect.width > 0, clampedRect.height > 0 else {
            return
        }

        focusRectNormalized = clampedRect
        cameraService.setFocusRegion(clampedRect)
    }

    private func solve(image: UIImage, setProcessingState: Bool, cropRectNormalized: CGRect?) async {
        if setProcessingState {
            state = .processing
        }

        do {
            let croppedImage = croppedImageIfNeeded(image, normalizedRect: cropRectNormalized)
            let optimizedImage = downscaledImageIfNeeded(croppedImage, maxDimension: 1600)

            guard let imageData = optimizedImage.jpegData(compressionQuality: 0.8) else {
                state = .error("Failed to process image")
                return
            }
            let base64 = imageData.base64EncodedString()

            let request = SolveRequest(imageBase64: base64, mediaType: "image/jpeg")
            let body = try JSONEncoder().encode(request)
            let response: SolveResponse = try await client.request("camera/solve", method: "POST", body: body)

            state = .success(response)
            if response.usesRemainingToday < 0 {
                usesRemaining = Self.unlimitedValue
                dailyLimit = Self.unlimitedValue
            } else {
                usesRemaining = response.usesRemainingToday
            }
            Task {
                await fetchHistory()
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func croppedImageIfNeeded(_ image: UIImage, normalizedRect: CGRect?) -> UIImage {
        guard let normalizedRect else {
            return image
        }

        let imageForCropping = normalizedOrientationImage(image)
        let bounds = CGRect(origin: .zero, size: imageForCropping.size)
        let cropRect = CGRect(
            x: normalizedRect.minX * bounds.width,
            y: normalizedRect.minY * bounds.height,
            width: normalizedRect.width * bounds.width,
            height: normalizedRect.height * bounds.height
        )
        .standardized
        .intersection(bounds)

        guard !cropRect.isNull, cropRect.width > 1, cropRect.height > 1 else {
            return imageForCropping
        }

        let renderer = UIGraphicsImageRenderer(size: cropRect.size)
        return renderer.image { _ in
            imageForCropping.draw(at: CGPoint(x: -cropRect.origin.x, y: -cropRect.origin.y))
        }
    }

    private func normalizedOrientationImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private func canStartSolve() -> Bool {
        guard !isBusy else {
            return false
        }

        guard usesRemaining == Self.unlimitedValue || usesRemaining > 0 else {
            if isGuest {
                showLoginPrompt = true
            } else {
                state = .error("Daily limit reached. Come back tomorrow!")
            }
            return false
        }

        return true
    }

    private func applyStatus(_ response: StatusResponse) {
        let tier = SubscriptionTier.current
        if tier == .max || response.dailyLimit < 0 || response.remaining < 0 {
            dailyLimit = Self.unlimitedValue
            usesRemaining = Self.unlimitedValue
            return
        }

        dailyLimit = response.dailyLimit
        usesRemaining = response.remaining
    }

    private func applyFallbackFromTier() {
        let limit = Self.resolvedDailyLimit()
        dailyLimit = limit
        usesRemaining = limit
    }

    private var isBusy: Bool {
        switch state {
        case .scanning, .processing:
            return true
        default:
            return false
        }
    }

    private func downscaledImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let largestDimension = max(size.width, size.height)
        guard largestDimension > maxDimension else {
            return image
        }

        let ratio = maxDimension / largestDimension
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func downsampledImage(from data: Data, maxDimension: CGFloat) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension)
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    func reset() {
        state = .idle
    }

    func fetchHistory() async {
        do {
            let response: HistoryResponse = try await client.request("camera/history")
            history = response.history
        } catch {
            print("Failed to fetch history: \(error)")
        }
    }

    func stopCamera() {
        cameraService.stopSession()
    }
}
