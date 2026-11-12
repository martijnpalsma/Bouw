import AVFoundation
import Photos
import Speech
import UIKit

@MainActor
final class PermissionManager: ObservableObject {
    enum Permission: String {
        case camera
        case microphone
        case speechRecognition
        case photoLibraryAdd
        case photoLibraryRead
    }

    enum Status {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    @Published private(set) var cameraStatus: Status = .notDetermined
    @Published private(set) var microphoneStatus: Status = .notDetermined
    @Published private(set) var speechStatus: Status = .notDetermined
    @Published private(set) var photoAddStatus: Status = .notDetermined
    @Published private(set) var photoReadStatus: Status = .notDetermined

    init() {
        refresh()
    }

    func refresh() {
        cameraStatus = mapAVStatus(AVCaptureDevice.authorizationStatus(for: .video))
        microphoneStatus = mapAVStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        speechStatus = mapSpeechStatus(SFSpeechRecognizer.authorizationStatus())
        photoAddStatus = mapPhotoStatus(PHPhotoLibrary.authorizationStatus(for: .addOnly))
        photoReadStatus = mapPhotoStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestCameraAccess() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        refresh()
        if !granted { AppLogger.permissionDenied(Permission.camera.rawValue) }
        return granted
    }

    func requestMicrophoneAccess() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        refresh()
        if !granted { AppLogger.permissionDenied(Permission.microphone.rawValue) }
        return granted
    }

    func requestSpeechAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.refresh()
                    let ok = status == .authorized
                    if !ok { AppLogger.permissionDenied(Permission.speechRecognition.rawValue) }
                    continuation.resume(returning: ok)
                }
            }
        }
    }

    func requestPhotoLibraryAddAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        refresh()
        let ok = status == .authorized || status == .limited
        if !ok { AppLogger.permissionDenied(Permission.photoLibraryAdd.rawValue) }
        return ok
    }

    func requestPhotoLibraryReadAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        refresh()
        let ok = status == .authorized || status == .limited
        if !ok { AppLogger.permissionDenied(Permission.photoLibraryRead.rawValue) }
        return ok
    }

    /// Camera + microphone + speech for dictation flows.
    func prepareDictationAccess() async -> Bool {
        let mic = await requestMicrophoneAccess()
        let speech = await requestSpeechAccess()
        return mic && speech
    }

    private func mapAVStatus(_ status: AVAuthorizationStatus) -> Status {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }

    private func mapSpeechStatus(_ status: SFSpeechRecognizerAuthorizationStatus) -> Status {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }

    private func mapPhotoStatus(_ status: PHAuthorizationStatus) -> Status {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized, .limited: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }
}
