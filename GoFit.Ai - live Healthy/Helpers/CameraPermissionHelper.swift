import AVFoundation
import UIKit

// Camera permission helper functions

func checkCameraPermission(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        completion(true)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    case .denied, .restricted:
        completion(false)
    @unknown default:
        completion(false)
    }
}
