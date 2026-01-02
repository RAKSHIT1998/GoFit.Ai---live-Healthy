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
                
                // Use low resolution preset for fastest startup
                // We can still capture high quality photos, but preview starts faster
                if self.session.canSetSessionPreset(.medium) {
                    self.session.sessionPreset = .medium // Faster than .photo
                } else if self.session.canSetSessionPreset(.photo) {
                    self.session.sessionPreset = .photo
                }
                
                // Camera device - use default for fastest access
                guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: captureDevice),
                      self.session.canAddInput(input) else {
                    self.session.commitConfiguration()
                    return
                }
                self.device = captureDevice
                
                // Minimal device configuration for speed
                do {
                    try captureDevice.lockForConfiguration()
                    // Use fastest autofocus mode
                    if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                        captureDevice.focusMode = .continuousAutoFocus
                    }
                    // Skip exposure configuration to save time
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
                // Get supported dimensions from the device's active format to avoid crashes
                // Only use dimensions that are actually supported by the device
                if let activeFormat = device?.activeFormat {
                    let targetWidth: Int32 = 1920
                    let targetHeight: Int32 = 1080
                    let supportedDimensions = activeFormat.supportedMaxPhotoDimensions
                    
                    // Filter dimensions that fit within target size
                    var suitableDimensions: [CMVideoDimensions] = []
                    for dimension in supportedDimensions {
                        if dimension.width <= targetWidth && dimension.height <= targetHeight {
                            suitableDimensions.append(dimension)
                        }
                    }
                    
                    // Find the largest suitable dimension
                    if !suitableDimensions.isEmpty {
                        var bestDimension = suitableDimensions[0]
                        var bestPixels = Int(bestDimension.width) * Int(bestDimension.height)
                        
                        for dimension in suitableDimensions {
                            let pixels = Int(dimension.width) * Int(dimension.height)
                            if pixels > bestPixels {
                                bestPixels = pixels
                                bestDimension = dimension
                            }
                        }
                        settings.maxPhotoDimensions = bestDimension
                    } else if !supportedDimensions.isEmpty {
                        // Fallback to smallest supported dimension
                        var smallestDimension = supportedDimensions[0]
                        var smallestPixels = Int(smallestDimension.width) * Int(smallestDimension.height)
                        
                        for dimension in supportedDimensions {
                            let pixels = Int(dimension.width) * Int(dimension.height)
                            if pixels < smallestPixels {
                                smallestPixels = pixels
                                smallestDimension = dimension
                            }
                        }
                        settings.maxPhotoDimensions = smallestDimension
                    }
                }
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
            
            // Capture on the session queue to ensure thread safety
            context.coordinator.sessionQueue.async {
                context.coordinator.capture()
            }
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.stop()
    }
}

extension CameraView.Coordinator: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
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
            
            // Get photo data representation
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
            
            // Update on main thread
            DispatchQueue.main.async {
                print("✅ Photo captured successfully, size: \(uiImage.size)")
                self.parent.capturedImage = uiImage
            }
        }
    }
}

// Extension to expose capture method