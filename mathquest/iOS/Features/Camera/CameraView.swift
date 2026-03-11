import PhotosUI
import SwiftUI
import UIKit

struct CameraView: View {
    private let minFocusSize = CGSize(width: 120, height: 120)
    private let defaultFocusSideRatio: CGFloat = 0.64
    private let focusBoundsHorizontalInset: CGFloat = 16
    private let focusBoundsTopInset: CGFloat = 56
    private let focusCornerRadius: CGFloat = 28
    private let handleTouchSize: CGFloat = 44
    private let handleVisualSize: CGFloat = 18

    @StateObject private var viewModel = CameraViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedGalleryImage: UIImage?
    @State private var showGalleryCropper = false
    @State private var selectedSolution: SolveResponse?
    @State private var showSolutionPage = false
    @State private var focusRect: CGRect = .zero
    @State private var previewSize: CGSize = .zero
    @State private var resizeStartRect: CGRect?
    @State private var activeResizeHandle: FocusHandle?
    @State private var showLoginFromPrompt = false
    @State private var showReviewSheet = false
    @State private var reviewSolveId: Int = 0
    @State private var pendingLanguageChoice: PendingSolutionLanguageChoice?
    @State private var isPreparingLocalizedSolution = false
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Camera Preview
            cameraPreview
                .ignoresSafeArea(.container, edges: [.top, .bottom])

            // Overlays based on state
            overlayForState
                .ignoresSafeArea(.container, edges: [.top, .bottom])

            // Bottom controls
            VStack {
                Spacer()
                bottomControls
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .toolbarBackground(.hidden, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
        }
        .task {
            await viewModel.setupCamera()
        }
        .onAppear {
            Task {
                await viewModel.resumeCameraIfNeeded()
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            guard case .success(let response) = newState else { return }
            viewModel.stopCamera()
            handleSolveSuccess(response)
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task {
                await viewModel.resumeCameraIfNeeded()
            }
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .sheet(isPresented: $viewModel.showHistory) {
            CameraHistoryView(
                history: viewModel.history,
                loadDetailAction: { id in
                    await viewModel.loadHistoryDetail(id: id)
                },
                shareLinkAction: { detail in
                    await viewModel.shareURL(forDetail: detail)
                },
                deleteAction: { id in
                    await viewModel.deleteHistoryItem(id: id)
                }
            )
                .task {
                    await viewModel.fetchHistory()
                }
        }
        .sheet(isPresented: $viewModel.showCameraPermissionSheet) {
            cameraPermissionSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $viewModel.showLoginPrompt) {
            loginPromptSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $viewModel.showUpgradePrompt) {
            StoreView()
        }
        .sheet(item: $pendingLanguageChoice) { choice in
            SolutionLanguageSheet(
                appLanguageName: localizedLanguageName(for: choice.appLanguage),
                problemLanguageName: localizedLanguageName(for: choice.problemLanguage),
                subtitle: L10n.solutionLanguageSubtitle(localizedLanguageName(for: choice.problemLanguage)),
                onChooseAppLanguage: {
                    chooseSolutionLanguage(choice, targetLanguage: choice.appLanguage)
                },
                onChooseProblemLanguage: {
                    chooseSolutionLanguage(choice, targetLanguage: choice.problemLanguage)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
            .interactiveDismissDisabled()
        }
        .fullScreenCover(isPresented: $showGalleryCropper) {
            if let selectedGalleryImage {
                GalleryCropSheet(
                    image: selectedGalleryImage,
                    onCancel: {
                        showGalleryCropper = false
                        self.selectedGalleryImage = nil
                    },
                    onUseCrop: { croppedImage in
                        showGalleryCropper = false
                        self.selectedGalleryImage = nil
                        Task {
                            await viewModel.solveFromGalleryImage(croppedImage)
                        }
                    }
                )
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }

            Task {
                do {
                    let data = try await newItem.loadTransferable(type: Data.self)
                    guard let data,
                          let image = UIImage(data: data) else {
                        viewModel.setError(L10n.failedLoadImage)
                        return
                    }

                    await MainActor.run {
                        selectedGalleryImage = image
                        showGalleryCropper = true
                    }
                } catch {
                    viewModel.setError(L10n.failedLoadImage)
                }

                await MainActor.run {
                    selectedPhotoItem = nil
                }
            }
        }
        .fullScreenCover(isPresented: $showLoginFromPrompt) {
            LoginView(
                showCloseButton: true,
                onUsernameLoginSuccess: {
                    showLoginFromPrompt = false
                    Task {
                        await viewModel.refreshAfterLogin()
                    }
                }
            )
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuth in
            if isAuth {
                showLoginFromPrompt = false
                Task {
                    await viewModel.refreshAfterLogin()
                }
            }
        }
        .navigationDestination(isPresented: $showSolutionPage) {
            if let response = selectedSolution {
                CameraSolutionPage(
                    response: response,
                    capturedImage: viewModel.lastCapturedImage,
                    shareLinkAction: {
                        await viewModel.shareURL(forSolution: response)
                    },
                    deleteAction: response.id != 0
                        ? {
                            await viewModel.deleteHistoryItem(id: response.id)
                        }
                        : nil
                )
                    .onDisappear {
                        let solveId = response.id
                        showSolutionPage = false
                        selectedSolution = nil
                        viewModel.reset()
                        Task {
                            await viewModel.resumeCameraIfNeeded()
                        }
                        if SolveReviewSheet.shouldShowReview(for: solveId) {
                            reviewSolveId = solveId
                            showReviewSheet = true
                        }
                    }
            }
        }
        .sheet(isPresented: $showReviewSheet) {
            SolveReviewSheet(solveId: reviewSolveId, isPresented: $showReviewSheet)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Camera Preview

    @ViewBuilder
    private var cameraPreview: some View {
        if viewModel.cameraService.isAuthorized {
            GeometryReader { geometry in
                CameraPreviewView(session: viewModel.cameraService.session)
                    .onAppear {
                        syncFocusRect(with: geometry.size)
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        syncFocusRect(with: newSize)
                    }
                    .overlay(cameraOverlay(in: geometry.size))
            }
        } else {
            Color.black
                .overlay {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(L10n.cameraAccessRequired)
                            .foregroundColor(.white)
                        Button(L10n.openSettings) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
        }
    }

    @ViewBuilder
    private func cameraOverlay(in size: CGSize) -> some View {
        let focusRect = resolvedFocusRect(in: size)

        ZStack {
            Path { path in
                path.addRect(CGRect(origin: .zero, size: size))
                path.addRoundedRect(
                    in: focusRect,
                    cornerSize: CGSize(width: focusCornerRadius, height: focusCornerRadius)
                )
            }
            .fill(
                Color.black.opacity(0.35),
                style: FillStyle(eoFill: true)
            )
            .opacity(viewModel.state == .idle ? 1 : 0)

            if viewModel.state == .idle {
                focusFrameOverlay(in: size, focusRect: focusRect)
            }

        }
        .allowsHitTesting(viewModel.state == .idle)
    }

    // MARK: - State Overlays

    @ViewBuilder
    private var overlayForState: some View {
        if isPreparingLocalizedSolution {
            Color.black.opacity(0.6)
                .overlay {
                    ProcessingOverlay()
                }
        } else {
            switch viewModel.state {
            case .idle:
                EmptyView()

            case .scanning:
                if let focusRect = activeFocusRect {
                    ZStack {
                        RoundedRectangle(cornerRadius: focusCornerRadius)
                            .stroke(Color.green, lineWidth: 3)
                            .frame(width: focusRect.width, height: focusRect.height)
                            .position(x: focusRect.midX, y: focusRect.midY)

                        RoundedRectangle(cornerRadius: focusCornerRadius)
                            .fill(Color.black.opacity(0.3))
                            .frame(width: focusRect.width, height: focusRect.height)
                            .overlay {
                                ScanningLineView()
                                    .clipShape(RoundedRectangle(cornerRadius: focusCornerRadius))
                            }
                            .position(x: focusRect.midX, y: focusRect.midY)
                    }
                }

            case .processing:
                Color.black.opacity(0.6)
                    .overlay {
                        ProcessingOverlay()
                    }

            case .success:
                EmptyView()

            case .error(let message):
                Color.black.opacity(0.6)
                    .overlay {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)

                            Text(message)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(L10n.tryAgain) {
                                viewModel.reset()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
            }
        }
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Capture button
            if viewModel.state == .idle {
                HStack(spacing: 24) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title2)
                            Text(L10n.gallery)
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .frame(width: 72, height: 72)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                    }

                    Button {
                        let captureRect = activeFocusRect ?? resolvedFocusRect(in: previewSize)
                        Task {
                            await viewModel.capture(
                                focusRect: captureRect,
                                previewSize: previewSize
                            )
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 72, height: 72)

                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }
                    .disabled(!viewModel.cameraService.isAuthorized)
                    .opacity(viewModel.cameraService.isAuthorized ? 1 : 0.5)
                }
            }
        }
        .padding(.bottom, 40)
    }

    private func handleSolveSuccess(_ response: SolveResponse) {
        let appLanguage = normalizedSupportedLanguage(L10n.currentLanguage)
        let problemLanguage = normalizedSupportedLanguage(response.detectedLanguage)

        guard shouldPromptForLanguageChoice(problemLanguage: problemLanguage, appLanguage: appLanguage) else {
            presentSolution(response)
            return
        }

        pendingLanguageChoice = PendingSolutionLanguageChoice(
            response: response,
            appLanguage: appLanguage,
            problemLanguage: problemLanguage
        )
    }

    private func presentSolution(_ response: SolveResponse) {
        let shouldDismissLanguageSheet = pendingLanguageChoice != nil
        pendingLanguageChoice = nil

        if shouldDismissLanguageSheet {
            DispatchQueue.main.async {
                selectedSolution = response
                showSolutionPage = true
            }
        } else {
            selectedSolution = response
            showSolutionPage = true
        }
    }

    private func chooseSolutionLanguage(_ choice: PendingSolutionLanguageChoice, targetLanguage: String) {
        pendingLanguageChoice = nil
        isPreparingLocalizedSolution = true

        Task {
            let resolvedResponse: SolveResponse
            do {
                resolvedResponse = try await viewModel.translateSolution(choice.response, to: targetLanguage)
            } catch {
                resolvedResponse = choice.response
            }

            await MainActor.run {
                isPreparingLocalizedSolution = false
                presentSolution(resolvedResponse)
            }
        }
    }

    private func shouldPromptForLanguageChoice(problemLanguage: String, appLanguage: String) -> Bool {
        problemLanguage != "unknown" && appLanguage != "unknown" && problemLanguage != appLanguage
    }

    private func normalizedSupportedLanguage(_ raw: String) -> String {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "en":
            return "en"
        case "it":
            return "it"
        case "fr":
            return "fr"
        case "es":
            return "es"
        case "uz":
            return "uz"
        default:
            return "unknown"
        }
    }

    private func localizedLanguageName(for code: String) -> String {
        switch code {
        case "it":
            return L10n.languageItalian
        case "fr":
            return L10n.languageFrench
        case "es":
            return L10n.languageSpanish
        case "uz":
            return L10n.languageUzbek
        default:
            return L10n.languageEnglish
        }
    }
    private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

    private var cameraPermissionSheet: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [appPurple, Color(red: 0.6, green: 0.4, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "camera.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text(L10n.cameraPermissionTitle)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text(L10n.cameraPermissionSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                permissionFeatureRow(
                    icon: "camera.viewfinder",
                    text: L10n.cameraPermissionCaptureLabel
                )
                permissionFeatureRow(
                    icon: "text.viewfinder",
                    text: L10n.cameraPermissionPreviewLabel
                )
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Button {
                    Task {
                        await viewModel.requestCameraPermissionFromSheet()
                    }
                } label: {
                    Text(L10n.continue)
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(appPurple)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    viewModel.dismissCameraPermissionSheet()
                } label: {
                    Text(L10n.notNow)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func permissionFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(appPurple)
                .frame(width: 32, height: 32)
                .background(appPurple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
    }

    private var loginPromptSheet: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [appPurple, Color(red: 0.6, green: 0.4, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text(L10n.loginPromptTitle)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text(L10n.loginPromptSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                permissionFeatureRow(
                    icon: "camera.fill",
                    text: L10n.loginPromptMoreScans
                )
                permissionFeatureRow(
                    icon: "clock.arrow.circlepath",
                    text: L10n.loginPromptHistory
                )
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Button {
                    viewModel.showLoginPrompt = false
                    showLoginFromPrompt = true
                } label: {
                    Text(L10n.signIn)
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(appPurple)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    viewModel.showLoginPrompt = false
                } label: {
                    Text(L10n.maybeLater)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func focusFrameOverlay(in size: CGSize, focusRect: CGRect) -> some View {
        ZStack {
            ForEach(FocusHandle.allCases, id: \.self) { handle in
                FocusHandleView(handle: handle, size: handleVisualSize)
                    .frame(width: handleTouchSize, height: handleTouchSize)
                    .position(handle.point(in: focusRect))
                    .highPriorityGesture(resizeGesture(for: handle, in: size))
            }
        }
    }

    private func syncFocusRect(with size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            return
        }

        previewSize = size
        let modelRect = denormalizedRect(from: viewModel.focusRectNormalized, in: size)
        let candidate = modelRect ?? defaultFocusRect(in: size)
        applyFocusRect(candidate, in: size, updateModel: true)
    }

    private func applyFocusRect(_ rect: CGRect, in size: CGSize, updateModel: Bool) {
        guard size.width > 0, size.height > 0 else {
            return
        }

        let clamped = clampFocusRect(rect, in: size)
        guard clamped.width > 0, clamped.height > 0 else {
            return
        }

        focusRect = clamped
        previewSize = size

        if updateModel, let normalized = normalizedRect(from: clamped, in: size) {
            viewModel.updateFocusRect(normalizedRect: normalized)
        }
    }

    private func resolvedFocusRect(in size: CGSize) -> CGRect {
        if focusRect.width > 0, focusRect.height > 0 {
            return clampFocusRect(focusRect, in: size)
        }

        let fallback = denormalizedRect(from: viewModel.focusRectNormalized, in: size) ?? defaultFocusRect(in: size)
        return clampFocusRect(fallback, in: size)
    }

    private var activeFocusRect: CGRect? {
        guard previewSize.width > 0, previewSize.height > 0 else {
            return nil
        }

        guard focusRect.width > 0, focusRect.height > 0 else {
            return nil
        }

        return clampFocusRect(focusRect, in: previewSize)
    }

    private func normalizedRect(from rect: CGRect, in size: CGSize) -> CGRect? {
        guard size.width > 0, size.height > 0 else {
            return nil
        }

        let normalized = CGRect(
            x: rect.minX / size.width,
            y: rect.minY / size.height,
            width: rect.width / size.width,
            height: rect.height / size.height
        )
        .standardized
        .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))

        guard !normalized.isNull, normalized.width > 0, normalized.height > 0 else {
            return nil
        }

        return normalized
    }

    private func denormalizedRect(from normalizedRect: CGRect, in size: CGSize) -> CGRect? {
        let clamped = normalizedRect
            .standardized
            .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))

        guard !clamped.isNull, clamped.width > 0, clamped.height > 0 else {
            return nil
        }

        return CGRect(
            x: clamped.minX * size.width,
            y: clamped.minY * size.height,
            width: clamped.width * size.width,
            height: clamped.height * size.height
        )
    }

    /// Bottom controls height: capture button (80) + bottom padding (40) + gap to rect (16).
    private let bottomControlsReserved: CGFloat = 136

    private func focusBounds(in size: CGSize) -> CGRect {
        CGRect(
            x: focusBoundsHorizontalInset,
            y: focusBoundsTopInset,
            width: max(size.width - (focusBoundsHorizontalInset * 2), 1),
            height: max(size.height - focusBoundsTopInset - bottomControlsReserved, 1)
        )
    }

    /// Vertical center of the focus frame, shifted upward to clear the bottom controls.
    private func focusCenterY(in bounds: CGRect) -> CGFloat {
        bounds.midY - bounds.height * 0.12
    }

    private func defaultFocusRect(in size: CGSize) -> CGRect {
        let bounds = focusBounds(in: size)
        let maxWidth = bounds.width - 16
        let maxHeight = bounds.height * 0.55
        let width = maxWidth
        let height = min(width * 0.35, maxHeight)
        let centerY = focusCenterY(in: bounds)

        return CGRect(
            x: bounds.midX - (width / 2),
            y: centerY - (height / 2),
            width: width,
            height: height
        )
    }

    private func clampFocusRect(_ rect: CGRect, in size: CGSize) -> CGRect {
        let bounds = focusBounds(in: size)
        let minimumWidth = min(minFocusSize.width, bounds.width)
        let minimumHeight = min(minFocusSize.height, bounds.height)
        let maxHeight = bounds.height * 0.55
        let maxWidth = bounds.width - 16
        let width = min(max(rect.width, minimumWidth), maxWidth)
        let height = min(max(rect.height, minimumHeight), maxHeight)
        let centerY = focusCenterY(in: bounds)
        let originX = bounds.midX - (width / 2)
        let originY = max(bounds.minY, min(centerY - (height / 2), bounds.maxY - height))

        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    private func resizeGesture(for handle: FocusHandle, in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if activeResizeHandle == nil {
                    activeResizeHandle = handle
                    resizeStartRect = resolvedFocusRect(in: size)
                }

                guard activeResizeHandle == handle, let startRect = resizeStartRect else { return }
                let resizedRect = resizedRect(
                    from: startRect,
                    using: value.translation,
                    handle: handle,
                    in: size
                )
                applyFocusRect(resizedRect, in: size, updateModel: true)
            }
            .onEnded { _ in
                resizeStartRect = nil
                activeResizeHandle = nil
            }
    }

    private func resizedRect(from startRect: CGRect, using translation: CGSize, handle: FocusHandle, in size: CGSize) -> CGRect {
        let bounds = focusBounds(in: size)
        let minimumWidth = min(minFocusSize.width, bounds.width)
        let minimumHeight = min(minFocusSize.height, bounds.height)

        // Calculate how much to expand/contract based on which handle is dragged.
        // Each handle contributes a signed delta; we double it so the rect grows
        // symmetrically from the center.
        let dw: CGFloat
        let dh: CGFloat

        switch handle {
        case .topLeft:
            dw = -translation.width * 2
            dh = -translation.height * 2
        case .topRight:
            dw = translation.width * 2
            dh = -translation.height * 2
        case .bottomLeft:
            dw = -translation.width * 2
            dh = translation.height * 2
        case .bottomRight:
            dw = translation.width * 2
            dh = translation.height * 2
        }

        let newWidth = min(max(startRect.width + dw, minimumWidth), bounds.width)
        let newHeight = min(max(startRect.height + dh, minimumHeight), bounds.height)

        // clampFocusRect will re-center the rect
        return CGRect(
            x: bounds.midX - newWidth / 2,
            y: bounds.midY - newHeight / 2,
            width: newWidth,
            height: newHeight
        )
    }

    private func clamped(_ value: CGFloat, min minimum: CGFloat, max maximum: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minimum), maximum)
    }
}

private enum FocusHandle: CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    func point(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight:
            return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft:
            return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight:
            return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }
}

private struct FocusHandleView: View {
    let handle: FocusHandle
    let size: CGFloat

    var body: some View {
        CornerBracketShape(handle: handle)
            .stroke(
                Color.white,
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            .frame(width: size, height: size)
            .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
    }
}

private struct CornerBracketShape: Shape {
    let handle: FocusHandle

    func path(in rect: CGRect) -> Path {
        let inset: CGFloat = 1
        let minX = rect.minX + inset
        let minY = rect.minY + inset
        let maxX = rect.maxX - inset
        let maxY = rect.maxY - inset
        let radius = min(rect.width, rect.height) * 0.45

        var path = Path()
        switch handle {
        case .topLeft:
            path.move(to: CGPoint(x: maxX, y: minY))
            path.addLine(to: CGPoint(x: minX + radius, y: minY))
            path.addQuadCurve(
                to: CGPoint(x: minX, y: minY + radius),
                control: CGPoint(x: minX, y: minY)
            )
            path.addLine(to: CGPoint(x: minX, y: maxY))

        case .topRight:
            path.move(to: CGPoint(x: minX, y: minY))
            path.addLine(to: CGPoint(x: maxX - radius, y: minY))
            path.addQuadCurve(
                to: CGPoint(x: maxX, y: minY + radius),
                control: CGPoint(x: maxX, y: minY)
            )
            path.addLine(to: CGPoint(x: maxX, y: maxY))

        case .bottomLeft:
            path.move(to: CGPoint(x: minX, y: minY))
            path.addLine(to: CGPoint(x: minX, y: maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: minX + radius, y: maxY),
                control: CGPoint(x: minX, y: maxY)
            )
            path.addLine(to: CGPoint(x: maxX, y: maxY))

        case .bottomRight:
            path.move(to: CGPoint(x: minX, y: maxY))
            path.addLine(to: CGPoint(x: maxX - radius, y: maxY))
            path.addQuadCurve(
                to: CGPoint(x: maxX, y: maxY - radius),
                control: CGPoint(x: maxX, y: maxY)
            )
            path.addLine(to: CGPoint(x: maxX, y: minY))
        }
        return path
    }
}

private struct GalleryCropSheet: View {
    let image: UIImage
    let onCancel: () -> Void
    let onUseCrop: (UIImage) -> Void

    private let minCropSize: CGFloat = 100
    private let cropCornerRadius: CGFloat = 28
    private let cropHandleSize: CGFloat = 18
    private let cropHandleTouchSize: CGFloat = 44

    @State private var imageFrame: CGRect = .zero
    @State private var cropRect: CGRect = .zero
    @State private var dragStartRect: CGRect?
    @State private var resizeStartRect: CGRect?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let fittedFrame = fittedImageFrame(in: geometry.size)

                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: fittedFrame.width, height: fittedFrame.height)
                        .position(x: fittedFrame.midX, y: fittedFrame.midY)

                    cropOverlay(in: fittedFrame)

                    VStack {
                        Spacer()
                        Text(L10n.dragMoveCrop)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Capsule())
                            .padding(.bottom, 28)
                    }
                }
                .onAppear {
                    syncLayout(with: fittedFrame)
                }
                .onChange(of: geometry.size) { _, newSize in
                    syncLayout(with: fittedImageFrame(in: newSize))
                }
            }
            .navigationTitle(L10n.crop)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel, action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.useCrop) {
                        onUseCrop(croppedImage() ?? image)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cropOverlay(in fittedFrame: CGRect) -> some View {
        let activeCropRect = resolvedCropRect(in: fittedFrame)

        ZStack {
            Path { path in
                path.addRect(fittedFrame)
                path.addRoundedRect(
                    in: activeCropRect,
                    cornerSize: CGSize(width: cropCornerRadius, height: cropCornerRadius)
                )
            }
            .fill(
                Color.black.opacity(0.45),
                style: FillStyle(eoFill: true)
            )

            ForEach(FocusHandle.allCases, id: \.self) { handle in
                FocusHandleView(handle: handle, size: cropHandleSize)
                    .frame(width: cropHandleTouchSize, height: cropHandleTouchSize)
                    .position(handle.point(in: activeCropRect))
            }

            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: activeCropRect.width, height: activeCropRect.height)
                .position(x: activeCropRect.midX, y: activeCropRect.midY)
                .gesture(moveGesture(in: fittedFrame))
                .simultaneousGesture(scaleGesture(in: fittedFrame))
        }
    }

    private func fittedImageFrame(in size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0, image.size.width > 0, image.size.height > 0 else {
            return .zero
        }

        let imageAspect = image.size.width / image.size.height
        let containerAspect = size.width / size.height

        if imageAspect > containerAspect {
            let width = size.width
            let height = width / imageAspect
            return CGRect(
                x: 0,
                y: (size.height - height) / 2,
                width: width,
                height: height
            )
        }

        let height = size.height
        let width = height * imageAspect
        return CGRect(
            x: (size.width - width) / 2,
            y: 0,
            width: width,
            height: height
        )
    }

    private func syncLayout(with fittedFrame: CGRect) {
        guard fittedFrame.width > 0, fittedFrame.height > 0 else {
            return
        }

        if imageFrame == .zero || cropRect == .zero {
            imageFrame = fittedFrame
            cropRect = defaultCropRect(in: fittedFrame)
            return
        }

        let normalized = normalizedRect(cropRect, in: imageFrame)
        imageFrame = fittedFrame
        cropRect = clampCropRect(denormalizedRect(normalized, in: fittedFrame), in: fittedFrame)
    }

    private func defaultCropRect(in frame: CGRect) -> CGRect {
        let maxWidth = frame.width * 0.8
        let maxHeight = frame.height * 0.8
        let width = max(minCropSize, maxWidth)
        let height = max(minCropSize, min(maxHeight, width * 0.75))
        let rect = CGRect(
            x: frame.midX - (width / 2),
            y: frame.midY - (height / 2),
            width: width,
            height: height
        )
        return clampCropRect(rect, in: frame)
    }

    private func resolvedCropRect(in frame: CGRect) -> CGRect {
        if cropRect.width > 0, cropRect.height > 0 {
            return clampCropRect(cropRect, in: frame)
        }
        return defaultCropRect(in: frame)
    }

    private func clampCropRect(_ rect: CGRect, in bounds: CGRect) -> CGRect {
        guard bounds.width > 0, bounds.height > 0 else {
            return rect
        }

        let width = min(max(rect.width, minCropSize), bounds.width)
        let height = min(max(rect.height, minCropSize), bounds.height)
        let minX = bounds.minX
        let maxX = bounds.maxX - width
        let minY = bounds.minY
        let maxY = bounds.maxY - height

        return CGRect(
            x: min(max(rect.minX, minX), maxX),
            y: min(max(rect.minY, minY), maxY),
            width: width,
            height: height
        )
    }

    private func moveGesture(in frame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStartRect == nil {
                    dragStartRect = resolvedCropRect(in: frame)
                }

                guard let startRect = dragStartRect else { return }
                let translated = startRect.offsetBy(
                    dx: value.translation.width,
                    dy: value.translation.height
                )
                cropRect = clampCropRect(translated, in: frame)
            }
            .onEnded { _ in
                dragStartRect = nil
            }
    }

    private func scaleGesture(in frame: CGRect) -> some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                if resizeStartRect == nil {
                    resizeStartRect = resolvedCropRect(in: frame)
                }

                guard let startRect = resizeStartRect else { return }

                let width = startRect.width * scale
                let height = startRect.height * scale
                let resized = CGRect(
                    x: startRect.midX - (width / 2),
                    y: startRect.midY - (height / 2),
                    width: width,
                    height: height
                )

                cropRect = clampCropRect(resized, in: frame)
            }
            .onEnded { _ in
                resizeStartRect = nil
            }
    }

    private func normalizedRect(_ rect: CGRect, in frame: CGRect) -> CGRect {
        guard frame.width > 0, frame.height > 0 else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }

        return CGRect(
            x: (rect.minX - frame.minX) / frame.width,
            y: (rect.minY - frame.minY) / frame.height,
            width: rect.width / frame.width,
            height: rect.height / frame.height
        )
    }

    private func denormalizedRect(_ normalizedRect: CGRect, in frame: CGRect) -> CGRect {
        CGRect(
            x: frame.minX + (normalizedRect.minX * frame.width),
            y: frame.minY + (normalizedRect.minY * frame.height),
            width: normalizedRect.width * frame.width,
            height: normalizedRect.height * frame.height
        )
    }

    private func croppedImage() -> UIImage? {
        guard imageFrame.width > 0, imageFrame.height > 0 else {
            return nil
        }

        let normalized = normalizedRect(cropRect, in: imageFrame)
        let clamped = normalized
            .standardized
            .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))

        guard !clamped.isNull, clamped.width > 0, clamped.height > 0 else {
            return nil
        }

        let normalizedImage = normalizedOrientationImage(image)
        guard let cgImage = normalizedImage.cgImage else {
            return nil
        }

        let cropRectInPixels = CGRect(
            x: clamped.minX * CGFloat(cgImage.width),
            y: clamped.minY * CGFloat(cgImage.height),
            width: clamped.width * CGFloat(cgImage.width),
            height: clamped.height * CGFloat(cgImage.height)
        ).integral

        guard cropRectInPixels.width > 1,
              cropRectInPixels.height > 1,
              let croppedCGImage = cgImage.cropping(to: cropRectInPixels) else {
            return nil
        }

        return UIImage(cgImage: croppedCGImage, scale: 1, orientation: .up)
    }

    private func normalizedOrientationImage(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

private struct PendingSolutionLanguageChoice: Identifiable {
    let id = UUID()
    let response: SolveResponse
    let appLanguage: String
    let problemLanguage: String
}

private struct SolutionLanguageSheet: View {
    let appLanguageName: String
    let problemLanguageName: String
    let subtitle: String
    let onChooseAppLanguage: () -> Void
    let onChooseProblemLanguage: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text(L10n.solutionLanguageTitle)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            VStack(spacing: 10) {
                languageOption(
                    title: appLanguageName,
                    subtitle: L10n.solutionLanguageAppLabel,
                    action: onChooseAppLanguage
                )

                languageOption(
                    title: problemLanguageName,
                    subtitle: L10n.solutionLanguageProblemLabel,
                    action: onChooseProblemLanguage
                )
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    private func languageOption(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CameraView()
    }
}

private struct CameraSolutionPage: View {
    let response: SolveResponse
    var capturedImage: UIImage?
    let shareLinkAction: (() async -> URL?)?
    let deleteAction: (() async -> Bool)?
    @Environment(\.dismiss) private var dismiss
    @State private var visibleSteps: Set<Int> = []
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var isPreparingShare = false
    @State private var showDeleteFailed = false
    @State private var showShareFailed = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    
    private var hasShareAction: Bool {
        shareLinkAction != nil
    }
    
    private var hasAnyBottomAction: Bool {
        hasShareAction || deleteAction != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text(L10n.solution)
                        .font(.title2.bold())
                    Spacer()
                    DifficultyBadge(level: response.difficultyLevel)
                }

                if let capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.problem)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(response.problem)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AnswerCardView(answer: response.solution, isVisible: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.steps)
                        .font(.headline)

                    ForEach(Array(response.steps.enumerated()), id: \.offset) { index, step in
                        StepCardView(
                            stepNumber: index + 1,
                            content: step,
                            isVisible: visibleSteps.contains(index)
                        )
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.72).delay(Double(index) * 0.1),
                            value: visibleSteps.contains(index)
                        )
                    }
                }

            }
            .padding()
        }
        .navigationTitle(L10n.solved)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if hasAnyBottomAction {
                actionBar
            }
        }
        .alert(L10n.deleteSolution, isPresented: $showDeleteConfirmation) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.deleteSolution, role: .destructive) {
                Task {
                    await deleteSolution()
                }
            }
        } message: {
            Text(L10n.deleteSolutionMessage)
        }
        .alert(L10n.error, isPresented: $showDeleteFailed) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(L10n.deleteSolutionFailed)
        }
        .alert(L10n.error, isPresented: $showShareFailed) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(L10n.shareLinkFailed)
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(items: shareItems)
        }
        .task {
            await animateSteps()
        }
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            if hasShareAction {
                Button {
                    Task {
                        await shareSolution()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isPreparingShare {
                            ProgressView()
                                .tint(.white)
                            Text(L10n.preparingShare)
                        } else {
                            Label(L10n.share, systemImage: "square.and.arrow.up")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isPreparingShare || isDeleting)
            }

            if deleteAction != nil {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(L10n.deleteSolution, systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isPreparingShare || isDeleting)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func animateSteps() async {
        visibleSteps.removeAll()
        for i in 0..<response.steps.count {
            try? await Task.sleep(nanoseconds: 220_000_000)
            visibleSteps.insert(i)
        }
    }

    private func shareSolution() async {
        guard !isPreparingShare else { return }
        isPreparingShare = true
        let shareURL = await resolvedShareURL()
        isPreparingShare = false

        guard let shareURL, isTokenShareURL(shareURL) else {
            if let shareURL {
                print("[ShareLink] Rejected URL in solution page: \(shareURL.absoluteString)")
            } else {
                print("[ShareLink] No URL returned in solution page")
            }
            showShareFailed = true
            return
        }

        print("[ShareLink] Presenting share sheet URL: \(shareURL.absoluteString)")
        shareItems = [shareURL]
        showShareSheet = true
    }

    private func resolvedShareURL() async -> URL? {
        guard let shareLinkAction else { return nil }
        return await shareLinkAction()
    }

    private func isTokenShareURL(_ url: URL) -> Bool {
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return path.starts(with: "s/")
    }

    private func deleteSolution() async {
        guard let deleteAction else { return }
        isDeleting = true
        let success = await deleteAction()
        isDeleting = false
        if success {
            dismiss()
        } else {
            showDeleteFailed = true
        }
    }
}
