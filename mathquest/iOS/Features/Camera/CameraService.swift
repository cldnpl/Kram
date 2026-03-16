@preconcurrency import AVFoundation
import UIKit

@MainActor
final class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var photoContinuation: CheckedContinuation<UIImage?, Error>?
    private let sessionQueue = DispatchQueue(label: "com.mathquest.camera.session")

    var session: AVCaptureSession? {
        captureSession
    }

    var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    override init() {
        super.init()
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

    func setupCamera() async {
        refreshAuthorizationStatus()
        guard isAuthorized else {
            errorMessage = "Camera access not authorized"
            return
        }

        if captureSession != nil, photoOutput != nil {
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

        session.commitConfiguration()

        self.captureSession = session
        self.photoOutput = output

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

    func toggleTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              device.hasTorch else {
            return
        }

        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Failed to toggle torch: \(error)")
        }
    }

    func stopSession() {
        if let continuation = photoContinuation {
            continuation.resume(throwing: CameraError.sessionStopped)
            photoContinuation = nil
        }

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

