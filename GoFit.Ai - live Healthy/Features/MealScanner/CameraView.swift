import SwiftUI
import AVFoundation
import CoreMedia

struct CameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    var captureTrigger: Int // Use Int to trigger captures without binding issues

    class Coordinator: NSObject {
        var parent: CameraView
        let session = AVCaptureSession()
        let output = AVCapturePhotoOutput()
        var device: AVCaptureDevice?
        var previewLayer: AVCaptureVideoPreviewLayer?
        var lastCaptureTrigger: Int = 0
        private var isCapturingPhoto = false

        init(_ parent: CameraView) {
            self.parent = parent
            super.init()
            setup()
        }

        // Use a serial queue to prevent race conditions with session configuration
        let sessionQueue = DispatchQueue(label: "com.gofit.camera.session")
        private var isConfigured = false
        
        func setup() {
            // Start camera setup on serial queue to prevent race conditions
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                
                self.session.beginConfiguration()
                
                // Use .photo preset for highest quality captures (needed for AI recognition)
                // This ensures we get the best possible image quality for food recognition
                if self.session.canSetSessionPreset(.photo) {
                    self.session.sessionPreset = .photo // Highest quality for AI
                } else if self.session.canSetSessionPreset(.high) {
                    self.session.sessionPreset = .high
                } else {
                    self.session.sessionPreset = .medium
                }
                
                // Camera device - use default for fastest access
                guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: captureDevice),
                      self.session.canAddInput(input) else {
                    self.session.commitConfiguration()
                    return
                }
                self.device = captureDevice
                
                // Configure device for high quality photos
                do {
                    try captureDevice.lockForConfiguration()
                    // Use auto focus for sharp images (critical for AI recognition)
                    if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                        captureDevice.focusMode = .continuousAutoFocus
                    }
                    // Enable auto exposure for proper lighting
                    if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
                        captureDevice.exposureMode = .continuousAutoExposure
                    }
                    // Enable auto white balance for accurate colors
                    if captureDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                        captureDevice.whiteBalanceMode = .continuousAutoWhiteBalance
                    }
                    captureDevice.unlockForConfiguration()
                } catch {
                    // Continue even if configuration fails
                    print("⚠️ Could not configure camera device: \(error)")
                }
                
                self.session.addInput(input)
                if self.session.canAddOutput(self.output) {
                    self.session.addOutput(self.output)
                }
                
                self.session.commitConfiguration()
                self.isConfigured = true
                
                // Check camera permission before starting
                let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
                guard authStatus == .authorized else {
                    print("⚠️ Camera permission not granted, cannot start session (status: \(authStatus.rawValue))")
                    return
                }
                
                // Start session after configuration is complete
                if !self.session.isRunning {
                    self.session.startRunning()
                    print("✅ Camera session started after configuration")
                }
            }
        }

        func start() { 
            // Use the same serial queue to prevent conflicts
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                
                // Check camera permission
                let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
                guard authStatus == .authorized else {
                    print("⚠️ Cannot start camera: permission not granted (status: \(authStatus.rawValue))")
                    return
                }
                
                guard self.isConfigured else {
                    print("⚠️ Cannot start camera: not configured yet")
                    return
                }
                
                guard !self.session.isRunning else {
                    return
                }
                
                self.session.startRunning()
                print("✅ Camera session started")
            }
        }
        func stop() { if session.isRunning { session.stopRunning() } }

        func capture() {
            // Ensure we're on the session queue
            guard session.isRunning else {
                print("⚠️ Cannot capture: session is not running")
                return
            }
            
            // Check if already capturing
            guard !isCapturingPhoto else {
                print("⚠️ Already capturing photo, skipping")
                return
            }
            
            isCapturingPhoto = true
            
            // Lock focus and exposure for sharp, well-exposed photo (critical for AI)
            if let device = device {
                do {
                    try device.lockForConfiguration()
                    // Lock focus at current point for sharp image
                    if device.isFocusModeSupported(.autoFocus) {
                        device.focusMode = .autoFocus
                    }
                    // Lock exposure for consistent lighting
                    if device.isExposureModeSupported(.autoExpose) {
                        device.exposureMode = .autoExpose
                    }
                    device.unlockForConfiguration()
                } catch {
                    print("⚠️ Could not lock device for capture: \(error)")
                }
            }
            
            // Use highest quality settings for AI recognition
            let settings: AVCapturePhotoSettings
            if output.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                settings = AVCapturePhotoSettings()
            }
            
            // Use maximum supported resolution for best AI recognition (iOS 16+)
            if #available(iOS 16.0, *) {
                if let activeFormat = device?.activeFormat {
                    let supportedDimensions = activeFormat.supportedMaxPhotoDimensions
                    
                    if !supportedDimensions.isEmpty {
                        // Find the LARGEST supported dimension for maximum quality
                        var maxDimension = supportedDimensions[0]
                        var maxPixels = Int(maxDimension.width) * Int(maxDimension.height)
                        
                        for dimension in supportedDimensions {
                            let pixels = Int(dimension.width) * Int(dimension.height)
                            if pixels > maxPixels {
                                maxPixels = pixels
                                maxDimension = dimension
                            }
                        }
                        settings.maxPhotoDimensions = maxDimension
                        print("📸 Using maximum photo dimensions: \(maxDimension.width)x\(maxDimension.height) for AI recognition")
                    }
                }
            }
            
            // Capture immediately - photo taken instantly
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black // Show black immediately while camera loads
        
        // Check camera permission before setup
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        guard authStatus == .authorized else {
            print("⚠️ Camera permission not granted, status: \(authStatus.rawValue)")
            return view
        }
        
        // Setup preview layer immediately
        context.coordinator.previewLayer = AVCaptureVideoPreviewLayer(session: context.coordinator.session)
        context.coordinator.previewLayer?.videoGravity = .resizeAspectFill
        
        // Set frame after a small delay to ensure view has proper bounds
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = view.bounds
        }
        
        if let pl = context.coordinator.previewLayer {
            view.layer.addSublayer(pl)
        }
        
        context.coordinator.lastCaptureTrigger = captureTrigger
        
        // Ensure camera starts - setup() already starts it, but this is a backup
        context.coordinator.start()
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view bounds change
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
        
        // Check if capture was requested (trigger changed)
        let newTrigger = captureTrigger
        if newTrigger != context.coordinator.lastCaptureTrigger {
            // Update the trigger synchronously to prevent race conditions
            context.coordinator.lastCaptureTrigger = newTrigger
            
            // If camera session is not running, restart it first
            if !context.coordinator.session.isRunning {
                context.coordinator.sessionQueue.async {
                    context.coordinator.start()
                    // Wait a brief moment for session to start before capturing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        context.coordinator.sessionQueue.async {
                            context.coordinator.capture()
                        }
                    }
                }
            } else {
                // Capture on the session queue to ensure thread safety
                context.coordinator.sessionQueue.async {
                    context.coordinator.capture()
                }
            }
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.stop()
    }
}

extension CameraView.Coordinator: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Stop camera session immediately after capture to save resources
        // This prevents the camera from "keeping on working"
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                print("📸 Camera session stopped after capture")
            }
        }
        
        // Reset capture flag
        isCapturingPhoto = false
        
        if let error = error {
            print("❌ Photo capture error: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                // Set capturedImage to nil to indicate failure
                self?.parent.capturedImage = nil
            }
            return
        }
        
        // Process photo data on background queue to avoid blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Get photo data representation (use highest quality)
            guard let data = photo.fileDataRepresentation() else {
                print("❌ Failed to get photo data representation")
                DispatchQueue.main.async {
                    self.parent.capturedImage = nil
                }
                return
            }
            
            // Create UIImage from data
            guard let uiImage = UIImage(data: data) else {
                print("❌ Failed to create UIImage from photo data")
                DispatchQueue.main.async {
                    self.parent.capturedImage = nil
                }
                return
            }
            
            // Log photo quality for debugging
            let imageSize = uiImage.size
            let imageDataSize = data.count
            print("✅ Photo captured successfully - Size: \(Int(imageSize.width))x\(Int(imageSize.height)), Data: \(imageDataSize/1024)KB")
            
            // Update on main thread
            DispatchQueue.main.async {
                self.parent.capturedImage = uiImage
            }
        }
    }
}

// Extension to expose capture method