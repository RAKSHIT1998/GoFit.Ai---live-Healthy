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
                
                // Prevent multiple simultaneous configurations
                guard !self.isConfigured else {
                    print("⚠️ Camera already configured, skipping setup")
                    return
                }
                
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
                guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    print("❌ No camera device available")
                    self.session.commitConfiguration()
                    return
                }
                
                guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
                    print("❌ Failed to create camera input")
                    self.session.commitConfiguration()
                    return
                }
                
                guard self.session.canAddInput(input) else {
                    print("❌ Cannot add camera input to session")
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
                
                guard self.session.canAddOutput(self.output) else {
                    print("❌ Cannot add photo output to session")
                    self.session.commitConfiguration()
                    return
                }
                self.session.addOutput(self.output)
                
                self.session.commitConfiguration()
                self.isConfigured = true
                print("✅ Camera configuration completed successfully")
                
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
            
            // INSTANT CAPTURE: Skip focus/exposure locking for speed
            // Use current camera state immediately - no delays
            // Continuous autofocus is already active, so we can capture instantly
            
            // Use optimized settings for instant capture while maintaining AI quality
            let settings: AVCapturePhotoSettings
            if output.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                settings = AVCapturePhotoSettings()
            }
            
            // Use balanced resolution for instant capture (still high quality for AI)
            // 1920x1080 or similar is fast but still excellent for food recognition
            if #available(iOS 16.0, *) {
                if let activeFormat = device?.activeFormat {
                    let supportedDimensions = activeFormat.supportedMaxPhotoDimensions
                    
                    if !supportedDimensions.isEmpty {
                        // Find a balanced dimension - fast but still high quality
                        // Target ~2MP (1920x1080) for instant capture, but allow up to 4MP if needed
                        let targetPixels = 1920 * 1080 // ~2MP - fast and good quality
                        let maxPixels = 3840 * 2160 // ~8MP max - still fast enough
                        
                        var bestDimension = supportedDimensions[0]
                        var bestPixels = Int(bestDimension.width) * Int(bestDimension.height)
                        
                        for dimension in supportedDimensions {
                            let pixels = Int(dimension.width) * Int(dimension.height)
                            // Prefer dimensions close to target (2MP) but not exceeding max (8MP)
                            if pixels >= targetPixels && pixels <= maxPixels {
                                if abs(pixels - targetPixels) < abs(bestPixels - targetPixels) {
                                    bestPixels = pixels
                                    bestDimension = dimension
                                }
                            } else if pixels < targetPixels && pixels > bestPixels {
                                // Fallback to largest if nothing in target range
                                bestPixels = pixels
                                bestDimension = dimension
                            }
                        }
                        
                        settings.maxPhotoDimensions = bestDimension
                        print("📸 Instant capture with dimensions: \(bestDimension.width)x\(bestDimension.height)")
                    }
                }
            }
            
            // INSTANT CAPTURE: No delays, capture immediately
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
        
        // Safely setup preview layer with error handling
        do {
            context.coordinator.previewLayer = AVCaptureVideoPreviewLayer(session: context.coordinator.session)
            context.coordinator.previewLayer?.videoGravity = .resizeAspectFill
            
            // Set frame after a small delay to ensure view has proper bounds
            DispatchQueue.main.async {
                // Ensure we're still on main thread and view is valid
                guard let previewLayer = context.coordinator.previewLayer else { return }
                previewLayer.frame = view.bounds
                
                // Only add if not already added
                if previewLayer.superlayer == nil {
                    view.layer.addSublayer(previewLayer)
                }
            }
        } catch {
            print("⚠️ Failed to setup camera preview layer: \(error)")
            return view
        }
        
        context.coordinator.lastCaptureTrigger = captureTrigger
        
        // Ensure camera starts - setup() already starts it, but this is a backup
        // Use a small delay to prevent race conditions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            context.coordinator.start()
        }
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view bounds change (safely)
        DispatchQueue.main.async {
            guard let previewLayer = context.coordinator.previewLayer,
                  previewLayer.superlayer != nil else { return }
            previewLayer.frame = uiView.bounds
        }
        
        // Check if capture was requested (trigger changed)
        let newTrigger = captureTrigger
        if newTrigger != context.coordinator.lastCaptureTrigger {
            // Update the trigger synchronously to prevent race conditions
            context.coordinator.lastCaptureTrigger = newTrigger
            
            // INSTANT CAPTURE: Capture immediately if session is running
            if context.coordinator.session.isRunning {
                // Capture immediately on session queue (fastest path - no delays)
                context.coordinator.sessionQueue.async { [weak context] in
                    guard let coordinator = context?.coordinator else { return }
                    coordinator.capture()
                }
            } else {
                // If session not running, start it and capture (minimal delay)
                context.coordinator.sessionQueue.async { [weak context] in
                    guard let coordinator = context?.coordinator else { return }
                    coordinator.start()
                    // Minimal delay for session to start (reduced from 0.2s to 0.1s)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        coordinator.sessionQueue.async {
                            coordinator.capture()
                        }
                    }
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
        // Reset capture flag immediately for instant next capture
        isCapturingPhoto = false
        
        if let error = error {
            print("❌ Photo capture error: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.parent.capturedImage = nil
            }
            return
        }
        
        // INSTANT PROCESSING: Process photo immediately on high priority queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Get photo data representation immediately
            guard let data = photo.fileDataRepresentation() else {
                print("❌ Failed to get photo data representation")
                DispatchQueue.main.async {
                    self.parent.capturedImage = nil
                }
                return
            }
            
            // Create UIImage from data immediately
            guard let uiImage = UIImage(data: data) else {
                print("❌ Failed to create UIImage from photo data")
                DispatchQueue.main.async {
                    self.parent.capturedImage = nil
                }
                return
            }
            
            // Log instant capture success
            let imageSize = uiImage.size
            let imageDataSize = data.count
            print("✅ Instant capture successful - Size: \(Int(imageSize.width))x\(Int(imageSize.height)), Data: \(imageDataSize/1024)KB")
            
            // Update on main thread immediately
            DispatchQueue.main.async {
                self.parent.capturedImage = uiImage
            }
            
            // Stop camera session after processing (save resources, but don't delay capture)
            self.sessionQueue.async { [weak self] in
                guard let self = self else { return }
                if self.session.isRunning {
                    self.session.stopRunning()
                    print("📸 Camera session stopped after capture")
                }
            }
        }
    }
}

// Extension to expose capture method