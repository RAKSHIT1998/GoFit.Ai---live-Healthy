import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    var captureTrigger: Int // Use Int to trigger captures without binding issues

    class Coordinator: NSObject {
        var parent: CameraView
        let session = AVCaptureSession()
        let output = AVCapturePhotoOutput()
        var previewLayer: AVCaptureVideoPreviewLayer?
        var lastCaptureTrigger: Int = 0

        init(_ parent: CameraView) {
            self.parent = parent
            super.init()
            setup()
        }

        func setup() {
            session.beginConfiguration()
            // Use photo preset optimized for still image capture
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
            // Start session immediately for faster camera opening
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }

        func start() { 
            if !session.isRunning { 
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.session.startRunning()
                }
            }
        }
        func stop() { if session.isRunning { session.stopRunning() } }

        func capture() {
            guard session.isRunning else { return }
            // Use fastest capture settings for instant photo
            // Prioritize speed over maximum resolution for one-tap capture
            let settings: AVCapturePhotoSettings
            if output.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                settings = AVCapturePhotoSettings()
            }
            // Use standard resolution for faster capture (iOS 16+)
            if #available(iOS 16.0, *) {
                // Get supported dimensions from the photo output to avoid crashes
                // Only use dimensions that are actually supported by the device
                let targetWidth: Int32 = 1920
                let targetHeight: Int32 = 1080
                
                // Find the largest supported dimension <= 1920x1080 for best quality at target speed
                let suitableDimensions = output.supportedMaxPhotoDimensions.filter { dimension in
                    dimension.width <= targetWidth && dimension.height <= targetHeight
                }
                
                if let bestDimension = suitableDimensions.max(by: { dim1, dim2 in
                    // Sort by total pixels (width * height) to get the largest suitable dimension
                    (dim1.width * dim1.height) < (dim2.width * dim2.height)
                }) {
                    // Use the largest supported dimension that's <= 1920x1080 for faster capture
                    settings.maxPhotoDimensions = bestDimension
                } else if !output.supportedMaxPhotoDimensions.isEmpty,
                          let smallestDimension = output.supportedMaxPhotoDimensions.min(by: { dim1, dim2 in
                              (dim1.width * dim1.height) < (dim2.width * dim2.height)
                          }) {
                    // Fallback to smallest supported dimension if no suitable one found
                    settings.maxPhotoDimensions = smallestDimension
                }
                // If no supported dimensions available, don't set maxPhotoDimensions (use default)
            } else {
                // Fallback for iOS < 16
                settings.isHighResolutionPhotoEnabled = false
            }
            // Capture immediately without delay
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
        context.coordinator.lastCaptureTrigger = captureTrigger
        // Camera should already be starting in setup(), but ensure it starts
            context.coordinator.start()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Only update the preview layer frame - no state modifications here
        context.coordinator.previewLayer?.frame = uiView.bounds
        
        // Check if capture was requested (trigger changed)
        let newTrigger = captureTrigger
        if newTrigger != context.coordinator.lastCaptureTrigger {
            // Update the trigger synchronously to prevent race conditions
            context.coordinator.lastCaptureTrigger = newTrigger
            
            // Capture immediately on the current queue for instant response
            // This ensures the photo is taken as soon as the button is pressed
            context.coordinator.capture()
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.stop()
    }
}

extension CameraView.Coordinator: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Photo capture error: \(error.localizedDescription)")
            return
        }
        
        if let data = photo.fileDataRepresentation(), let uiImage = UIImage(data: data) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.capturedImage = uiImage
            }
        }
    }
}

// Extension to expose capture method