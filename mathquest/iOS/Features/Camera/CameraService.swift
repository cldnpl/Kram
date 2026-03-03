@preconcurrency import AVFoundation
import QuartzCore
import UIKit
import Vision

@MainActor
final class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?
    @Published var liveDetectedText = ""

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoContinuation: CheckedContinuation<UIImage?, Error>?
    private let sessionQueue = DispatchQueue(label: "com.mathquest.camera.session")
    private let liveTextRecognizer = LiveTextRecognizer()
    private var focusRegionNormalized = CGRect(x: 0.2, y: 0.35, width: 0.6, height: 0.3)

    var session: AVCaptureSession? {
        captureSession
    }

    var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    override init() {
        super.init()
        liveTextRecognizer.onTextDetected = { [weak self] text in
            Task { @MainActor in
                self?.liveDetectedText = text
            }
        }
        liveTextRecognizer.setRegionOfInterest(visionRegion(from: focusRegionNormalized))
    }

    func refreshAuthorizationStatus() {
        switch authorizationStatus {
        case .authorized:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }

    func requestCameraAccess() async -> Bool {
        switch authorizationStatus {
        case .authorized:
            isAuthorized = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            if !granted {
                errorMessage = "Camera access not authorized"
            }
            return granted
        default:
            isAuthorized = false
            errorMessage = "Camera access not authorized"
            return false
        }
    }

    func setFocusRegion(_ normalizedRect: CGRect) {
        let clampedRect = normalizedRect
            .standardized
            .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))

        guard !clampedRect.isNull, clampedRect.width > 0, clampedRect.height > 0 else {
            return
        }

        focusRegionNormalized = clampedRect
        liveTextRecognizer.setRegionOfInterest(visionRegion(from: clampedRect))
    }

    func setupCamera() async {
        refreshAuthorizationStatus()
        guard isAuthorized else {
            errorMessage = "Camera access not authorized"
            return
        }

        if captureSession != nil, photoOutput != nil, videoOutput != nil {
            startSessionIfNeeded()
            return
        }

        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            errorMessage = "Failed to access camera"
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(liveTextRecognizer, queue: liveTextRecognizer.outputQueue)
        }

        session.commitConfiguration()

        self.captureSession = session
        self.photoOutput = output
        self.videoOutput = videoOutput

        startSessionIfNeeded()
    }

    func capturePhoto() async throws -> UIImage? {
        guard let photoOutput = photoOutput,
              let captureSession = captureSession else {
            throw CameraError.notConfigured
        }

        guard captureSession.isRunning else {
            throw CameraError.sessionNotRunning
        }

        guard photoContinuation == nil else {
            throw CameraError.captureInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation

            let settings: AVCapturePhotoSettings
            if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            } else {
                settings = AVCapturePhotoSettings()
            }

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func stopSession() {
        if let continuation = photoContinuation {
            continuation.resume(throwing: CameraError.sessionStopped)
            photoContinuation = nil
        }

        liveDetectedText = ""

        guard let captureSession = captureSession else { return }
        sessionQueue.async {
            guard captureSession.isRunning else { return }
            captureSession.stopRunning()
        }
    }

    private func startSessionIfNeeded() {
        guard let captureSession = captureSession else { return }
        sessionQueue.async {
            guard !captureSession.isRunning else { return }
            captureSession.startRunning()
        }
    }

    private func visionRegion(from topLeftRect: CGRect) -> CGRect {
        CGRect(
            x: topLeftRect.minX,
            y: 1 - topLeftRect.maxY,
            width: topLeftRect.width,
            height: topLeftRect.height
        )
    }

    enum CameraError: Error, LocalizedError {
        case notConfigured
        case sessionNotRunning
        case captureInProgress
        case sessionStopped
        case captureFailed

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Camera not configured"
            case .sessionNotRunning:
                return "Camera is still starting. Please try again."
            case .captureInProgress:
                return "A capture is already in progress."
            case .sessionStopped:
                return "Camera session stopped"
            case .captureFailed:
                return "Failed to capture photo"
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        Task { @MainActor in
            if let error = error {
                photoContinuation?.resume(throwing: error)
                photoContinuation = nil
                return
            }

            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else {
                photoContinuation?.resume(throwing: CameraError.captureFailed)
                photoContinuation = nil
                return
            }

            capturedImage = image
            photoContinuation?.resume(returning: image)
            photoContinuation = nil
        }
    }
}

private final class LiveTextRecognizer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onTextDetected: ((String) -> Void)?
    let outputQueue = DispatchQueue(label: "com.mathquest.camera.liveText", qos: .userInitiated)

    private var isProcessing = false
    private var lastProcessTime: CFTimeInterval = 0
    private let throttleInterval: CFTimeInterval = 0.6
    private let lock = NSLock()
    private var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)

    func setRegionOfInterest(_ rect: CGRect) {
        lock.lock()
        regionOfInterest = rect
        lock.unlock()
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard shouldProcessFrame(),
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let request = VNRecognizeTextRequest { [weak self] request, _ in
            defer { self?.markProcessingComplete() }

            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let lines = observations
                .compactMap { $0.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            self?.onTextDetected?(Array(lines.prefix(3)).joined(separator: "\n"))
        }

        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.025
        request.regionOfInterest = currentRegionOfInterest()

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try handler.perform([request])
        } catch {
            markProcessingComplete()
        }
    }

    private func shouldProcessFrame() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let now = CACurrentMediaTime()
        guard !isProcessing, now - lastProcessTime >= throttleInterval else {
            return false
        }

        isProcessing = true
        lastProcessTime = now
        return true
    }

    private func currentRegionOfInterest() -> CGRect {
        lock.lock()
        let current = regionOfInterest
        lock.unlock()
        return current
    }

    private func markProcessingComplete() {
        lock.lock()
        isProcessing = false
        lock.unlock()
    }
}
