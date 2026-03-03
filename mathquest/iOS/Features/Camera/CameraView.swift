import PhotosUI
import SwiftUI
import UIKit
import AVFoundation

struct CameraView: View {
    private let minFocusSize = CGSize(width: 120, height: 120)
    private let defaultFocusSideRatio: CGFloat = 0.64
    private let focusBoundsInset: CGFloat = 12
    private let focusCornerRadius: CGFloat = 16
    private let handleTouchSize: CGFloat = 44
    private let handleVisualSize: CGFloat = 18

    @StateObject private var viewModel = CameraViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedSolution: SolveResponse?
    @State private var showSolutionPage = false
    @State private var focusRect: CGRect = .zero
    @State private var previewSize: CGSize = .zero
    @State private var previewLayer: AVCaptureVideoPreviewLayer?
    @State private var dragStartRect: CGRect?
    @State private var resizeStartRect: CGRect?
    @State private var activeResizeHandle: FocusHandle?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Camera Preview
            cameraPreview

            // Overlays based on state
            overlayForState

            // Bottom controls
            VStack {
                Spacer()
                bottomControls
            }
        }
        .ignoresSafeArea(.container, edges: .top)
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
        .onChange(of: viewModel.state) { _, newState in
            guard case .success(let response) = newState else { return }
            selectedSolution = response
            showSolutionPage = true
            viewModel.stopCamera()
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
            CameraHistoryView(history: viewModel.history)
                .task {
                    await viewModel.fetchHistory()
                }
        }
        .sheet(isPresented: $viewModel.showCameraPermissionSheet) {
            cameraPermissionSheet
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }

            Task {
                do {
                    let data = try await newItem.loadTransferable(type: Data.self)
                    await viewModel.solveFromGalleryData(data)
                } catch {
                    viewModel.setError("Failed to load selected image")
                }

                await MainActor.run {
                    selectedPhotoItem = nil
                }
            }
        }
        .navigationDestination(isPresented: $showSolutionPage) {
            if let response = selectedSolution {
                CameraSolutionPage(response: response)
                    .onDisappear {
                        selectedSolution = nil
                        viewModel.reset()
                        Task {
                            await viewModel.resumeCameraIfNeeded()
                        }
                    }
            }
        }
    }

    // MARK: - Camera Preview

    @ViewBuilder
    private var cameraPreview: some View {
        if viewModel.cameraService.isAuthorized {
            GeometryReader { geometry in
                CameraPreviewView(session: viewModel.cameraService.session) { layer in
                    guard previewLayer !== layer else { return }
                    previewLayer = layer
                    DispatchQueue.main.async {
                        syncFocusRect(with: geometry.size)
                    }
                }
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
                        Text("Camera access required")
                            .foregroundColor(.white)
                        Button("Open Settings") {
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

            if viewModel.state == .idle && !viewModel.cameraService.liveDetectedText.isEmpty {
                VStack {
                    Text(viewModel.cameraService.liveDetectedText)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.black.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 20)
                        .padding(.top, 70)
                    Spacer()
                }
            }
        }
        .allowsHitTesting(viewModel.state == .idle)
    }

    // MARK: - State Overlays

    @ViewBuilder
    private var overlayForState: some View {
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

                        Button("Try Again") {
                            viewModel.reset()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
        }
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Uses remaining
            HStack {
                Image(systemName: "camera.fill")
                Text("\(viewModel.usesRemaining) of \(viewModel.dailyLimit) uses remaining today")
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .clipShape(Capsule())

            // Capture button
            if viewModel.state == .idle {
                HStack(spacing: 24) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title2)
                            Text("Gallery")
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .frame(width: 72, height: 72)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                    }
                    .disabled(viewModel.usesRemaining == 0)
                    .opacity(viewModel.usesRemaining == 0 ? 0.5 : 1)

                    Button {
                        Task {
                            await viewModel.capture(focusRectNormalized: currentFocusRectNormalized)
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
                    .disabled(viewModel.usesRemaining == 0 || !viewModel.cameraService.isAuthorized)
                    .opacity((viewModel.usesRemaining == 0 || !viewModel.cameraService.isAuthorized) ? 0.5 : 1)
                }
            }
        }
        .padding(.bottom, 40)
    }

    private var cameraPermissionSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)

            Text("Use Camera for Math Scanning")
                .font(.title3.bold())

            Text("Allow camera access so MathQuest can scan problems and also detect text live while you point the camera.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("Capture handwritten or printed math problems", systemImage: "camera.viewfinder")
                Label("Preview recognized text before taking a photo", systemImage: "text.viewfinder")
            }
            .font(.subheadline)

            Spacer(minLength: 6)

            HStack(spacing: 12) {
                Button("Not Now") {
                    viewModel.dismissCameraPermissionSheet()
                }
                .buttonStyle(.bordered)

                Button("Continue") {
                    Task {
                        await viewModel.requestCameraPermissionFromSheet()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }

    @ViewBuilder
    private func focusFrameOverlay(in size: CGSize, focusRect: CGRect) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: focusCornerRadius)
                .stroke(Color.white, lineWidth: 2.5)
                .frame(width: focusRect.width, height: focusRect.height)
                .position(x: focusRect.midX, y: focusRect.midY)

            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: focusRect.width, height: focusRect.height)
                .position(x: focusRect.midX, y: focusRect.midY)
                .gesture(moveGesture(in: size))

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

        if updateModel, let normalized = normalizedFocusRectForCapture(from: clamped, in: size) {
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

    private var currentFocusRectNormalized: CGRect? {
        guard previewSize.width > 0, previewSize.height > 0 else {
            return nil
        }

        return normalizedFocusRectForCapture(from: focusRect, in: previewSize)
    }

    private func normalizedFocusRectForCapture(from rect: CGRect, in size: CGSize) -> CGRect? {
        if let previewLayer {
            let converted = previewLayer.metadataOutputRectConverted(fromLayerRect: rect)
                .standardized
                .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
            if !converted.isNull, converted.width > 0, converted.height > 0 {
                return converted
            }
        }

        return normalizedRect(from: rect, in: size)
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
        if let previewLayer {
            let converted = previewLayer.layerRectConverted(fromMetadataOutputRect: normalizedRect)
                .standardized
            if converted.width > 0, converted.height > 0 {
                return converted
            }
        }

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

    private func focusBounds(in size: CGSize) -> CGRect {
        CGRect(
            x: focusBoundsInset,
            y: focusBoundsInset,
            width: max(size.width - (focusBoundsInset * 2), 1),
            height: max(size.height - (focusBoundsInset * 2), 1)
        )
    }

    private func defaultFocusRect(in size: CGSize) -> CGRect {
        let bounds = focusBounds(in: size)
        let minDimension = min(bounds.width, bounds.height)
        let minimumSide = min(minFocusSize.width, minDimension)
        let side = min(max(minDimension * defaultFocusSideRatio, minimumSide), minDimension)

        return CGRect(
            x: bounds.midX - (side / 2),
            y: bounds.midY - (side / 2),
            width: side,
            height: side
        )
    }

    private func clampFocusRect(_ rect: CGRect, in size: CGSize) -> CGRect {
        let bounds = focusBounds(in: size)
        let minimumWidth = min(minFocusSize.width, bounds.width)
        let minimumHeight = min(minFocusSize.height, bounds.height)
        let width = min(max(rect.width, minimumWidth), bounds.width)
        let height = min(max(rect.height, minimumHeight), bounds.height)
        let originX = clamped(rect.minX, min: bounds.minX, max: bounds.maxX - width)
        let originY = clamped(rect.minY, min: bounds.minY, max: bounds.maxY - height)

        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    private func moveGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard activeResizeHandle == nil else { return }
                if dragStartRect == nil {
                    dragStartRect = resolvedFocusRect(in: size)
                }

                guard let startRect = dragStartRect else { return }
                let movedRect = startRect.offsetBy(
                    dx: value.translation.width,
                    dy: value.translation.height
                )
                applyFocusRect(movedRect, in: size, updateModel: true)
            }
            .onEnded { _ in
                dragStartRect = nil
            }
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
                dragStartRect = nil
            }
    }

    private func resizedRect(from startRect: CGRect, using translation: CGSize, handle: FocusHandle, in size: CGSize) -> CGRect {
        let bounds = focusBounds(in: size)
        let minimumWidth = min(minFocusSize.width, bounds.width)
        let minimumHeight = min(minFocusSize.height, bounds.height)

        switch handle {
        case .topLeft:
            let newMinX = clamped(startRect.minX + translation.width, min: bounds.minX, max: startRect.maxX - minimumWidth)
            let newMinY = clamped(startRect.minY + translation.height, min: bounds.minY, max: startRect.maxY - minimumHeight)
            return CGRect(
                x: newMinX,
                y: newMinY,
                width: startRect.maxX - newMinX,
                height: startRect.maxY - newMinY
            )

        case .topRight:
            let newMaxX = clamped(startRect.maxX + translation.width, min: startRect.minX + minimumWidth, max: bounds.maxX)
            let newMinY = clamped(startRect.minY + translation.height, min: bounds.minY, max: startRect.maxY - minimumHeight)
            return CGRect(
                x: startRect.minX,
                y: newMinY,
                width: newMaxX - startRect.minX,
                height: startRect.maxY - newMinY
            )

        case .bottomLeft:
            let newMinX = clamped(startRect.minX + translation.width, min: bounds.minX, max: startRect.maxX - minimumWidth)
            let newMaxY = clamped(startRect.maxY + translation.height, min: startRect.minY + minimumHeight, max: bounds.maxY)
            return CGRect(
                x: newMinX,
                y: startRect.minY,
                width: startRect.maxX - newMinX,
                height: newMaxY - startRect.minY
            )

        case .bottomRight:
            let newMaxX = clamped(startRect.maxX + translation.width, min: startRect.minX + minimumWidth, max: bounds.maxX)
            let newMaxY = clamped(startRect.maxY + translation.height, min: startRect.minY + minimumHeight, max: bounds.maxY)
            return CGRect(
                x: startRect.minX,
                y: startRect.minY,
                width: newMaxX - startRect.minX,
                height: newMaxY - startRect.minY
            )
        }
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

        var path = Path()
        switch handle {
        case .topLeft:
            path.move(to: CGPoint(x: maxX, y: minY))
            path.addLine(to: CGPoint(x: minX, y: minY))
            path.addLine(to: CGPoint(x: minX, y: maxY))

        case .topRight:
            path.move(to: CGPoint(x: minX, y: minY))
            path.addLine(to: CGPoint(x: maxX, y: minY))
            path.addLine(to: CGPoint(x: maxX, y: maxY))

        case .bottomLeft:
            path.move(to: CGPoint(x: minX, y: minY))
            path.addLine(to: CGPoint(x: minX, y: maxY))
            path.addLine(to: CGPoint(x: maxX, y: maxY))

        case .bottomRight:
            path.move(to: CGPoint(x: minX, y: maxY))
            path.addLine(to: CGPoint(x: maxX, y: maxY))
            path.addLine(to: CGPoint(x: maxX, y: minY))
        }
        return path
    }
}

#Preview {
    NavigationStack {
        CameraView()
    }
}

private struct CameraSolutionPage: View {
    let response: SolveResponse
    @State private var visibleSteps: Set<Int> = []

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("Solution")
                        .font(.title2.bold())
                    Spacer()
                    DifficultyBadge(level: response.difficultyLevel)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Problem")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(response.problem)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AnswerCardView(answer: response.solution, isVisible: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Steps")
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

                if !response.rawLatex.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LaTeX")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(response.rawLatex)
                            .font(.system(.caption, design: .monospaced))
                            .padding(10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Solved")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await animateSteps()
        }
    }

    private func animateSteps() async {
        visibleSteps.removeAll()
        for i in 0..<response.steps.count {
            try? await Task.sleep(nanoseconds: 220_000_000)
            visibleSteps.insert(i)
        }
    }
}
