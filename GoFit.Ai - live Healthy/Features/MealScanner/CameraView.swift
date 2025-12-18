import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isTaking: Bool

    class Coordinator: NSObject {
        var parent: CameraView
        let session = AVCaptureSession()
        let output = AVCapturePhotoOutput()
        var previewLayer: AVCaptureVideoPreviewLayer?
        var hasCaptured = false

        init(_ parent: CameraView) {
            self.parent = parent
            super.init()
            setup()
        }

        func setup() {
            session.beginConfiguration()
            session.sessionPreset = .photo
            // Camera device
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            session.commitConfiguration()
        }

        func start() { if !session.isRunning { session.startRunning() } }
        func stop() { if session.isRunning { session.stopRunning() } }

        func capture() {
            let settings = AVCapturePhotoSettings()
            if #available(iOS 16.0, *) {
                settings.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
            } else {
                settings.isHighResolutionPhotoEnabled = true
            }
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        context.coordinator.previewLayer = AVCaptureVideoPreviewLayer(session: context.coordinator.session)
        context.coordinator.previewLayer?.videoGravity = .resizeAspectFill
        context.coordinator.previewLayer?.frame = view.bounds
        if let pl = context.coordinator.previewLayer {
            view.layer.addSublayer(pl)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            context.coordinator.start()
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
        
        // Handle photo capture without modifying state during view update
        if isTaking && !context.coordinator.hasCaptured {
            context.coordinator.hasCaptured = true
            DispatchQueue.main.async {
                context.coordinator.capture()
                // Reset flag after capture
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    context.coordinator.hasCaptured = false
                    self.isTaking = false
                }
            }
        } else if !isTaking {
            context.coordinator.hasCaptured = false
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.stop()
    }
}

extension CameraView.Coordinator: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let uiImage = UIImage(data: data) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.capturedImage = uiImage
            }
        }
    }
}
