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
    @Published var showUpgradePrompt = false
    @Published var lastCapturedImage: UIImage?
    @Published var history: [HistoryItem] = []
    @Published private(set) var focusRectNormalized = CGRect(x: 0.05, y: 0.3, width: 0.9, height: 0.25)

    let cameraService = CameraService()
    private let client = APIClient()
    private var cancellables = Set<AnyCancellable>()
    private var historyDetailsByID: [Int: HistoryDetailResponse] = [:]
    private var shareURLByID: [Int: URL] = [:]

    var isGuest: Bool {
        Auth.auth().currentUser == nil &&
        !UserDefaults.standard.bool(forKey: "session_logged_in")
    }

    init() {
        let limit = Self.resolvedDailyLimit()
        dailyLimit = limit
        usesRemaining = Self.isGuestStatic() ? Self.guestUsesRemaining() : limit

        cameraService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        Task {
            await client.setToken(Self.resolvedToken())
        }
    }

    // MARK: - Guest local usage tracking

    private static let guestUsesKey = "guest_camera_uses_today"
    private static let guestUsesDateKey = "guest_camera_uses_date"

    private static func isGuestStatic() -> Bool {
        Auth.auth().currentUser == nil &&
        !UserDefaults.standard.bool(forKey: "session_logged_in")
    }

    private static func guestUsesToday() -> Int {
        let saved = UserDefaults.standard.string(forKey: guestUsesDateKey) ?? ""
        let today = Self.todayString()
        if saved != today {
            return 0
        }
        return UserDefaults.standard.integer(forKey: guestUsesKey)
    }

    private static func guestUsesRemaining() -> Int {
        max(SubscriptionTier.guestDailyLimit - guestUsesToday(), 0)
    }

    private func recordGuestUse() {
        let today = Self.todayString()
        UserDefaults.standard.set(today, forKey: Self.guestUsesDateKey)
        let current = Self.guestUsesToday()
        UserDefaults.standard.set(current + 1, forKey: Self.guestUsesKey)
        usesRemaining = max(SubscriptionTier.guestDailyLimit - (current + 1), 0)
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private static func resolvedToken() -> String {
        if UserDefaults.standard.bool(forKey: "session_logged_in"),
           let username = UserDefaults.standard.string(forKey: "profile_username"),
           !username.isEmpty {
            return "username:\(username.lowercased())"
        }

        if let user = Auth.auth().currentUser {
            return user.uid
        }
        // Guest: use a stable device identifier so the backend can track daily usage
        return "guest:\(guestDeviceID())"
    }

    private static func guestDeviceID() -> String {
        let key = "guest_device_id"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
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

        await syncClientToken()
        await fetchStatus()
        await fetchHistory()
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
        guard !isGuest else {
            applyFallbackFromTier()
            return
        }

        do {
            await syncClientToken()
            let response: StatusResponse = try await client.request("camera/status")
            applyStatus(response)
        } catch {
            print("Failed to fetch status: \(error)")
            applyFallbackFromTier()
        }
    }

    func capture(focusRect: CGRect, previewSize: CGSize) async {
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
                cropRectInPreview: focusRect,
                previewSize: previewSize
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

        await solve(
            image: image,
            setProcessingState: true,
            cropRectInPreview: nil,
            previewSize: nil
        )
    }

    func translateSolution(_ response: SolveResponse, to targetLanguage: String) async throws -> SolveResponse {
        await syncClientToken()
        let request = TranslateSolutionRequest(
            problem: response.problem,
            solution: response.solution,
            steps: response.steps,
            rawLatex: response.rawLatex,
            difficultyLevel: response.difficultyLevel,
            detectedLanguage: response.detectedLanguage,
            shouldSaveToHistory: response.shouldSaveToHistory,
            targetLanguage: targetLanguage
        )
        let body = try JSONEncoder().encode(request)
        let translated: TranslateSolutionResponse = try await client.request(
            "camera/translate",
            method: "POST",
            body: body
        )
        return response.replacingContent(with: translated)
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
    }

    private func solve(
        image: UIImage,
        setProcessingState: Bool,
        cropRectInPreview: CGRect?,
        previewSize: CGSize?
    ) async {
        if setProcessingState {
            state = .processing
        }

        do {
            let croppedImage = croppedImageIfNeeded(
                image,
                focusRect: cropRectInPreview,
                previewSize: previewSize
            )
            lastCapturedImage = croppedImage
            let optimizedImage = downscaledImageIfNeeded(croppedImage, maxDimension: 1600)

            guard let imageData = optimizedImage.jpegData(compressionQuality: 0.8) else {
                state = .error("Failed to process image")
                return
            }
            let base64 = imageData.base64EncodedString()

            let request = SolveRequest(imageBase64: base64, mediaType: "image/jpeg")
            let body = try JSONEncoder().encode(request)
            await syncClientToken()
            let response: SolveResponse = try await client.request("camera/solve", method: "POST", body: body)

            persistSolvedHistory(response)
            state = .success(response)
            if isGuest {
                recordGuestUse()
            } else if response.usesRemainingToday < 0 {
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

    private func croppedImageIfNeeded(_ image: UIImage, focusRect: CGRect?, previewSize: CGSize?) -> UIImage {
        guard let focusRect,
              let previewSize,
              previewSize.width > 0,
              previewSize.height > 0 else {
            return image
        }

        let imageForCropping = normalizedOrientationImage(image)
        guard let cropRect = cropRectInImageSpace(
            focusRect: focusRect,
            previewSize: previewSize,
            imageSize: imageForCropping.size
        ) else {
            return imageForCropping
        }

        let renderer = UIGraphicsImageRenderer(size: cropRect.size)
        return renderer.image { _ in
            imageForCropping.draw(at: CGPoint(x: -cropRect.origin.x, y: -cropRect.origin.y))
        }
    }

    // Maps the user-selected preview rect back through the preview's aspect-fill transform.
    private func cropRectInImageSpace(
        focusRect: CGRect,
        previewSize: CGSize,
        imageSize: CGSize
    ) -> CGRect? {
        guard imageSize.width > 0,
              imageSize.height > 0,
              previewSize.width > 0,
              previewSize.height > 0 else {
            return nil
        }

        let previewBounds = CGRect(origin: .zero, size: previewSize)
        let clampedFocusRect = focusRect
            .standardized
            .intersection(previewBounds)

        guard !clampedFocusRect.isNull,
              clampedFocusRect.width > 1,
              clampedFocusRect.height > 1 else {
            return nil
        }

        let imageFrameInPreview = aspectFillFrame(for: imageSize, in: previewBounds)
        let scale = imageFrameInPreview.width / imageSize.width
        guard scale > 0 else {
            return nil
        }

        let cropRect = CGRect(
            x: (clampedFocusRect.minX - imageFrameInPreview.minX) / scale,
            y: (clampedFocusRect.minY - imageFrameInPreview.minY) / scale,
            width: clampedFocusRect.width / scale,
            height: clampedFocusRect.height / scale
        )
        .standardized
        .intersection(CGRect(origin: .zero, size: imageSize))

        guard !cropRect.isNull, cropRect.width > 1, cropRect.height > 1 else {
            return nil
        }

        return cropRect
    }

    private func aspectFillFrame(for contentSize: CGSize, in bounds: CGRect) -> CGRect {
        guard contentSize.width > 0, contentSize.height > 0 else {
            return bounds
        }

        let scale = max(bounds.width / contentSize.width, bounds.height / contentSize.height)
        let fittedSize = CGSize(
            width: contentSize.width * scale,
            height: contentSize.height * scale
        )

        return CGRect(
            x: bounds.midX - (fittedSize.width / 2),
            y: bounds.midY - (fittedSize.height / 2),
            width: fittedSize.width,
            height: fittedSize.height
        )
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
            } else if SubscriptionTier.current != .max {
                showUpgradePrompt = true
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
        usesRemaining = isGuest ? Self.guestUsesRemaining() : limit
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
        lastCapturedImage = nil
    }

    func fetchHistory() async {
        let scope = currentHistoryScope()
        let localEntries = LocalHistoryStore.load(scope: scope)
        historyDetailsByID = Dictionary(uniqueKeysWithValues: localEntries.map { ($0.id, $0.detail) })

        guard !isGuest else {
            history = localEntries.map(\.historyItem)
            return
        }

        do {
            await syncClientToken()
            let response: HistoryResponse = try await client.request("camera/history")
            history = mergeHistory(remote: response.history, local: localEntries.map(\.historyItem))
        } catch {
            print("Failed to fetch history: \(error)")
            history = localEntries.map(\.historyItem)
        }
    }

    func loadHistoryDetail(id: Int) async -> HistoryDetailResponse? {
        if let cached = historyDetailsByID[id] {
            return cached
        }

        let scope = currentHistoryScope()
        let localEntries = LocalHistoryStore.load(scope: scope)
        if let localDetail = localEntries.first(where: { $0.id == id })?.detail {
            historyDetailsByID[id] = localDetail
            return localDetail
        }

        guard !isGuest else {
            return nil
        }

        do {
            await syncClientToken()
            let detail: HistoryDetailResponse = try await client.request("camera/history/\(id)")
            historyDetailsByID[id] = detail
            LocalHistoryStore.upsert(LocalHistoryEntry(detail: detail), scope: scope)
            return detail
        } catch {
            print("Failed to load history detail: \(error)")
            return nil
        }
    }

    func deleteHistoryItem(id: Int) async -> Bool {
        let scope = currentHistoryScope()
        historyDetailsByID[id] = nil
        shareURLByID[id] = nil
        LocalHistoryStore.delete(id: id, scope: scope)
        history.removeAll { $0.id == id }

        guard !isGuest, id > 0 else {
            return true
        }

        do {
            await syncClientToken()
            let response: DeleteHistoryResponse = try await client.request("camera/history/\(id)", method: "DELETE")
            guard response.deleted else {
                await fetchHistory()
                return false
            }
            return true
        } catch {
            print("Failed to delete history detail: \(error)")
            await fetchHistory()
            return false
        }
    }

    func shareURL(forHistoryID id: Int) async -> URL? {
        let endpoint = "camera/history/\(id)/share"

        print("[ShareLink] Requested share URL for history id=\(id)")

        guard id > 0 else {
            print("[ShareLink] Aborting: invalid history id=\(id)")
            return nil
        }

        if let cached = shareURLByID[id] {
            if Self.isValidShareURL(cached) {
                print("[ShareLink] Using cached URL for id=\(id): \(cached.absoluteString)")
                return cached
            }
            print("[ShareLink] Dropping invalid cached URL for id=\(id): \(cached.absoluteString)")
            shareURLByID[id] = nil
        }

        do {
            let currentUID = Auth.auth().currentUser?.uid ?? "nil"
            let isSessionLoggedIn = UserDefaults.standard.bool(forKey: "session_logged_in")
            print("[ShareLink] POST \(APIConfig.baseURLString)/\(endpoint)")
            print("[ShareLink] Context isGuest=\(isGuest) session_logged_in=\(isSessionLoggedIn) firebase_uid=\(currentUID)")
            await syncClientToken()
            let response: ShareHistoryResponse = try await client.request(
                endpoint,
                method: "POST"
            )
            let token = response.token.trimmingCharacters(in: .whitespacesAndNewlines)
            print("[ShareLink] Response token=\(token)")

            guard !token.isEmpty else {
                print("[ShareLink] Empty token received for id=\(id)")
                return nil
            }
            guard let url = AppLinks.webSharedSolutionURL(token: token) else {
                print("[ShareLink] Failed to build web URL from token=\(token)")
                return nil
            }
            guard Self.isValidShareURL(url) else {
                print("[ShareLink] Rejecting non-token URL for id=\(id): \(url.absoluteString)")
                return nil
            }
            print("[ShareLink] Final share URL=\(url.absoluteString)")
            shareURLByID[id] = url
            return url
        } catch let apiError as APIClient.APIError {
            switch apiError {
            case .httpStatus(let code, let body):
                print("[ShareLink] HTTP error for \(endpoint): status=\(code) body=\(body)")
            case .decodingFailed(let underlying, let body):
                print("[ShareLink] Decoding error for \(endpoint): \(underlying.localizedDescription) body=\(body)")
            }
            return nil
        } catch {
            print("[ShareLink] Request failed for \(endpoint): \(error)")
            return nil
        }
    }

    func shareURL(forDetail detail: HistoryDetailResponse) async -> URL? {
        if detail.id > 0 {
            return await shareURL(forHistoryID: detail.id)
        }

        print("[ShareLink] Local history item detected (id=\(detail.id)); creating server share entry")
        return await createShareURL(
            problem: detail.problem,
            solution: detail.solution,
            steps: detail.steps,
            rawLatex: detail.rawLatex,
            difficultyLevel: detail.difficultyLevel
        )
    }

    func shareURL(forSolution response: SolveResponse) async -> URL? {
        if response.id > 0 {
            return await shareURL(forHistoryID: response.id)
        }

        print("[ShareLink] Unsaved solution detected (id=\(response.id)); creating server share entry")
        return await createShareURL(
            problem: response.problem,
            solution: response.solution,
            steps: response.steps,
            rawLatex: response.rawLatex,
            difficultyLevel: response.difficultyLevel
        )
    }

    private func createShareURL(
        problem: String,
        solution: String,
        steps: [String],
        rawLatex: String,
        difficultyLevel: String
    ) async -> URL? {
        let endpoint = "camera/share"
        let request = ShareCreateRequest(
            problem: problem,
            solution: solution,
            steps: steps,
            rawLatex: rawLatex,
            difficultyLevel: difficultyLevel
        )

        do {
            let authToken = Self.resolvedToken()
            let tokenPreview = String(authToken.prefix(18))
            let isSessionLoggedIn = UserDefaults.standard.bool(forKey: "session_logged_in")
            let username = UserDefaults.standard.string(forKey: "profile_username") ?? ""
            print("[ShareLink] Auth context isGuest=\(isGuest) session_logged_in=\(isSessionLoggedIn) username=\(username)")
            print("[ShareLink] Setting bearer token preview=\(tokenPreview)...")
            await client.setToken(authToken)
            let body = try JSONEncoder().encode(request)
            print("[ShareLink] POST \(APIConfig.baseURLString)/\(endpoint) (local-item upload)")
            let response: ShareHistoryResponse = try await client.request(
                endpoint,
                method: "POST",
                body: body
            )
            let token = response.token.trimmingCharacters(in: .whitespacesAndNewlines)
            print("[ShareLink] Local upload response token=\(token) id=\(response.id ?? -1)")

            guard !token.isEmpty,
                  let url = AppLinks.webSharedSolutionURL(token: token),
                  Self.isValidShareURL(url) else {
                print("[ShareLink] Invalid token URL after local upload")
                return nil
            }
            print("[ShareLink] Final share URL=\(url.absoluteString)")
            return url
        } catch let apiError as APIClient.APIError {
            switch apiError {
            case .httpStatus(let code, let body):
                print("[ShareLink] HTTP error for \(endpoint): status=\(code) body=\(body)")
            case .decodingFailed(let underlying, let body):
                print("[ShareLink] Decoding error for \(endpoint): \(underlying.localizedDescription) body=\(body)")
            }
            return nil
        } catch {
            print("[ShareLink] Request failed for \(endpoint): \(error)")
            return nil
        }
    }

    private static func isValidShareURL(_ url: URL) -> Bool {
        guard let host = URL(string: APIConfig.serverBaseURLString)?.host?.lowercased(),
              url.host?.lowercased() == host else {
            return false
        }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return path.starts(with: "s/")
    }

    func stopCamera() {
        cameraService.stopSession()
    }

    private func syncClientToken() async {
        await client.setToken(Self.resolvedToken())
    }

    private func currentHistoryScope() -> String {
        Self.resolvedToken()
    }

    private func persistSolvedHistory(_ response: SolveResponse) {
        guard response.shouldSaveToHistory else {
            return
        }

        let entry = LocalHistoryEntry(
            response: response,
            createdAt: Date(),
            fallbackID: LocalHistoryStore.nextFallbackID(scope: currentHistoryScope())
        )
        LocalHistoryStore.upsert(entry, scope: currentHistoryScope())
        historyDetailsByID[entry.id] = entry.detail
    }

    private func mergeHistory(remote: [HistoryItem], local: [HistoryItem]) -> [HistoryItem] {
        var seen = Set<Int>()
        let merged = (remote + local).filter { item in
            seen.insert(item.id).inserted
        }
        return merged.sorted { $0.createdAt > $1.createdAt }
    }
}

private struct LocalHistoryEntry: Codable {
    let id: Int
    let problem: String
    let solution: String
    let steps: [String]
    let rawLatex: String
    let difficultyLevel: String
    let createdAt: Date

    init(response: SolveResponse, createdAt: Date, fallbackID: Int) {
        id = response.id > 0 ? response.id : fallbackID
        problem = response.problem
        solution = response.solution
        steps = response.steps
        rawLatex = response.rawLatex
        difficultyLevel = response.difficultyLevel
        self.createdAt = createdAt
    }

    init(detail: HistoryDetailResponse) {
        id = detail.id
        problem = detail.problem
        solution = detail.solution
        steps = detail.steps
        rawLatex = detail.rawLatex
        difficultyLevel = detail.difficultyLevel
        createdAt = detail.createdAt
    }

    var historyItem: HistoryItem {
        HistoryItem(
            id: id,
            problem: problem,
            solution: solution,
            difficultyLevel: difficultyLevel,
            createdAt: createdAt
        )
    }

    var detail: HistoryDetailResponse {
        HistoryDetailResponse(
            id: id,
            problem: problem,
            solution: solution,
            steps: steps,
            rawLatex: rawLatex,
            difficultyLevel: difficultyLevel,
            createdAt: createdAt
        )
    }
}

private enum LocalHistoryStore {
    private static let historyKeyPrefix = "camera_history_entries"
    private static let fallbackIDKeyPrefix = "camera_history_fallback_id"

    static func load(scope: String) -> [LocalHistoryEntry] {
        let key = "\(historyKeyPrefix):\(scope)"
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        do {
            return try JSONDecoder().decode([LocalHistoryEntry].self, from: data)
        } catch {
            return []
        }
    }

    static func upsert(_ entry: LocalHistoryEntry, scope: String) {
        var entries = load(scope: scope)
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        entries.sort { $0.createdAt > $1.createdAt }

        let key = "\(historyKeyPrefix):\(scope)"
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func delete(id: Int, scope: String) {
        var entries = load(scope: scope)
        entries.removeAll { $0.id == id }
        let key = "\(historyKeyPrefix):\(scope)"
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func nextFallbackID(scope: String) -> Int {
        let key = "\(fallbackIDKeyPrefix):\(scope)"
        let current = UserDefaults.standard.object(forKey: key) as? Int ?? 0
        let next = current >= 0 ? -1 : current - 1
        UserDefaults.standard.set(next, forKey: key)
        return next
    }
}
