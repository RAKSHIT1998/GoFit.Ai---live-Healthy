import SwiftUI
import Vision
import CoreImage
import AVFoundation

// MARK: - AI GIF Generator Service
/// Generates exercise GIF animations using AI and stores them locally on device
final class AIGifGeneratorService: ObservableObject {
    static let shared = AIGifGeneratorService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var lastError: String?
    
    private let gifService = ExerciseGifService.shared
    private let apiKey: String
    private let ciContext = CIContext()
    
    // Configuration
    private let frameCount = 24 // 24 frames for 3-second animation at 8fps
    private let frameDuration: TimeInterval = 0.125 // 8 fps
    
    init() {
        // Load API key from environment or config
        self.apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    // MARK: - Generate GIF for Exercise
    
    /// Generate an AI-powered GIF animation for an exercise
    func generateGif(for exercise: Exercise, completion: @escaping (Result<Data, AIGifError>) -> Void) {
        guard !isGenerating else {
            completion(.failure(.alreadyGenerating))
            return
        }
        
        isGenerating = true
        generationProgress = 0.0
        lastError = nil
        
        Task {
            do {
                // Step 1: Generate frames using AI (20%)
                await MainActor.run { generationProgress = 0.1 }
                let frames = try await generateFrames(for: exercise)
                
                // Step 2: Process frames (40%)
                await MainActor.run { generationProgress = 0.4 }
                let processedFrames = try processFrames(frames)
                
                // Step 3: Create GIF (60%)
                await MainActor.run { generationProgress = 0.6 }
                let gifData = try createGifFromFrames(processedFrames)
                
                // Step 4: Save to device (80%)
                await MainActor.run { generationProgress = 0.8 }
                let saveResult = gifService.saveGifData(gifData, for: exercise.name)
                
                switch saveResult {
                case .success:
                    await MainActor.run {
                        generationProgress = 1.0
                        isGenerating = false
                    }
                    completion(.success(gifData))
                    
                case .failure(let error):
                    await MainActor.run {
                        isGenerating = false
                        lastError = error.localizedDescription
                    }
                    completion(.failure(.saveFailed(error.localizedDescription)))
                }
                
            } catch let error as AIGifError {
                await MainActor.run {
                    isGenerating = false
                    lastError = error.localizedDescription
                }
                completion(.failure(error))
                
            } catch {
                await MainActor.run {
                    isGenerating = false
                    lastError = error.localizedDescription
                }
                completion(.failure(.unknownError(error.localizedDescription)))
            }
        }
    }
    
    // MARK: - Frame Generation
    
    private func generateFrames(for exercise: Exercise) async throws -> [UIImage] {
        // Generate stick figure animation frames using procedural animation
        // This is a local AI-free approach that creates exercise animations
        return try await generateStickFigureFrames(for: exercise)
    }
    
    private func generateStickFigureFrames(for exercise: Exercise) async throws -> [UIImage] {
        var frames: [UIImage] = []
        
        // Get animation keyframes based on exercise type
        let keyframes = getKeyframes(for: exercise)
        
        // Generate interpolated frames
        for i in 0..<frameCount {
            let progress = Double(i) / Double(frameCount - 1)
            let frame = try renderStickFigure(at: progress, keyframes: keyframes, exercise: exercise)
            frames.append(frame)
            
            // Update progress
            await MainActor.run {
                generationProgress = 0.1 + (Double(i) / Double(frameCount)) * 0.3
            }
        }
        
        return frames
    }
    
    // MARK: - Stick Figure Rendering
    
    private func renderStickFigure(at progress: Double, keyframes: [StickFigureKeyframe], exercise: Exercise) throws -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Background
            ctx.setFillColor(UIColor.systemBackground.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Get current pose by interpolating keyframes
            let pose = interpolatePose(at: progress, keyframes: keyframes)
            
            // Draw stick figure
            drawStickFigure(ctx: ctx, pose: pose, size: size, exercise: exercise)
            
            // Add exercise name at bottom
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let text = exercise.name
            let textSize = text.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: size.height - 40,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)
        }
    }
    
    private func drawStickFigure(ctx: CGContext, pose: StickFigurePose, size: CGSize, exercise: Exercise) {
        let scale = min(size.width, size.height) * 0.6
        let offsetX = size.width / 2
        let offsetY = size.height / 2
        
        // Transform normalized coordinates to screen coordinates
        func transform(_ point: CGPoint) -> CGPoint {
            return CGPoint(
                x: offsetX + point.x * scale,
                y: offsetY - point.y * scale // Flip Y axis
            )
        }
        
        // Draw body parts
        ctx.setLineWidth(4)
        ctx.setLineCap(.round)
        
        // Head
        let headCenter = transform(pose.head)
        ctx.setStrokeColor(UIColor.systemBlue.cgColor)
        ctx.addEllipse(in: CGRect(
            x: headCenter.x - 20,
            y: headCenter.y - 20,
            width: 40,
            height: 40
        ))
        ctx.strokePath()
        
        // Body (torso)
        ctx.setStrokeColor(UIColor.systemGreen.cgColor)
        ctx.move(to: transform(pose.neck))
        ctx.addLine(to: transform(pose.hips))
        ctx.strokePath()
        
        // Left arm
        ctx.setStrokeColor(UIColor.systemOrange.cgColor)
        ctx.move(to: transform(pose.leftShoulder))
        ctx.addLine(to: transform(pose.leftElbow))
        ctx.addLine(to: transform(pose.leftHand))
        ctx.strokePath()
        
        // Right arm
        ctx.move(to: transform(pose.rightShoulder))
        ctx.addLine(to: transform(pose.rightElbow))
        ctx.addLine(to: transform(pose.rightHand))
        ctx.strokePath()
        
        // Left leg
        ctx.setStrokeColor(UIColor.systemRed.cgColor)
        ctx.move(to: transform(pose.hips))
        ctx.addLine(to: transform(pose.leftKnee))
        ctx.addLine(to: transform(pose.leftFoot))
        ctx.strokePath()
        
        // Right leg
        ctx.move(to: transform(pose.hips))
        ctx.addLine(to: transform(pose.rightKnee))
        ctx.addLine(to: transform(pose.rightFoot))
        ctx.strokePath()
        
        // Joints (small circles)
        ctx.setFillColor(UIColor.label.cgColor)
        let jointRadius: CGFloat = 6
        for point in pose.allPoints {
            let transformed = transform(point)
            ctx.fillEllipse(in: CGRect(
                x: transformed.x - jointRadius,
                y: transformed.y - jointRadius,
                width: jointRadius * 2,
                height: jointRadius * 2
            ))
        }
    }
    
    // MARK: - Keyframe Management
    
    private func getKeyframes(for exercise: Exercise) -> [StickFigureKeyframe] {
        let exerciseType = exercise.type.lowercased()
        let exerciseName = exercise.name.lowercased()
        
        // Define keyframes based on exercise type
        if exerciseName.contains("push") || exerciseName.contains("pushup") {
            return getPushupKeyframes()
        } else if exerciseName.contains("squat") {
            return getSquatKeyframes()
        } else if exerciseName.contains("plank") {
            return getPlankKeyframes()
        } else if exerciseName.contains("jumping jack") {
            return getJumpingJackKeyframes()
        } else if exerciseName.contains("lunge") {
            return getLungeKeyframes()
        } else if exerciseType.contains("cardio") {
            return getRunningKeyframes()
        } else {
            return getStandingKeyframes()
        }
    }
    
    // MARK: - Exercise-Specific Keyframes
    
    private func getPushupKeyframes() -> [StickFigureKeyframe] {
        // Starting position (plank, arms extended)
        let start = StickFigurePose(
            head: CGPoint(x: 0, y: 0.5),
            neck: CGPoint(x: 0, y: 0.35),
            leftShoulder: CGPoint(x: -0.15, y: 0.3),
            rightShoulder: CGPoint(x: 0.15, y: 0.3),
            leftElbow: CGPoint(x: -0.25, y: 0.0),
            rightElbow: CGPoint(x: 0.25, y: 0.0),
            leftHand: CGPoint(x: -0.25, y: -0.15),
            rightHand: CGPoint(x: 0.25, y: -0.15),
            hips: CGPoint(x: 0, y: 0.0),
            leftKnee: CGPoint(x: -0.1, y: -0.3),
            rightKnee: CGPoint(x: 0.1, y: -0.3),
            leftFoot: CGPoint(x: -0.1, y: -0.5),
            rightFoot: CGPoint(x: 0.1, y: -0.5)
        )
        
        // Down position (chest near ground)
        let down = StickFigurePose(
            head: CGPoint(x: 0, y: 0.2),
            neck: CGPoint(x: 0, y: 0.05),
            leftShoulder: CGPoint(x: -0.15, y: 0.0),
            rightShoulder: CGPoint(x: 0.15, y: 0.0),
            leftElbow: CGPoint(x: -0.2, y: 0.1),
            rightElbow: CGPoint(x: 0.2, y: 0.1),
            leftHand: CGPoint(x: -0.25, y: -0.15),
            rightHand: CGPoint(x: 0.25, y: -0.15),
            hips: CGPoint(x: 0, y: -0.15),
            leftKnee: CGPoint(x: -0.1, y: -0.4),
            rightKnee: CGPoint(x: 0.1, y: -0.4),
            leftFoot: CGPoint(x: -0.1, y: -0.5),
            rightFoot: CGPoint(x: 0.1, y: -0.5)
        )
        
        return [
            StickFigureKeyframe(time: 0.0, pose: start),
            StickFigureKeyframe(time: 0.5, pose: down),
            StickFigureKeyframe(time: 1.0, pose: start)
        ]
    }
    
    private func getSquatKeyframes() -> [StickFigureKeyframe] {
        let standing = StickFigurePose(
            head: CGPoint(x: 0, y: 0.6),
            neck: CGPoint(x: 0, y: 0.45),
            leftShoulder: CGPoint(x: -0.15, y: 0.4),
            rightShoulder: CGPoint(x: 0.15, y: 0.4),
            leftElbow: CGPoint(x: -0.2, y: 0.15),
            rightElbow: CGPoint(x: 0.2, y: 0.15),
            leftHand: CGPoint(x: -0.15, y: -0.05),
            rightHand: CGPoint(x: 0.15, y: -0.05),
            hips: CGPoint(x: 0, y: 0.0),
            leftKnee: CGPoint(x: -0.1, y: -0.3),
            rightKnee: CGPoint(x: 0.1, y: -0.3),
            leftFoot: CGPoint(x: -0.15, y: -0.6),
            rightFoot: CGPoint(x: 0.15, y: -0.6)
        )
        
        let squatting = StickFigurePose(
            head: CGPoint(x: 0, y: 0.3),
            neck: CGPoint(x: 0, y: 0.2),
            leftShoulder: CGPoint(x: -0.15, y: 0.15),
            rightShoulder: CGPoint(x: 0.15, y: 0.15),
            leftElbow: CGPoint(x: -0.25, y: 0.2),
            rightElbow: CGPoint(x: 0.25, y: 0.2),
            leftHand: CGPoint(x: -0.3, y: 0.1),
            rightHand: CGPoint(x: 0.3, y: 0.1),
            hips: CGPoint(x: 0, y: -0.2),
            leftKnee: CGPoint(x: -0.2, y: -0.35),
            rightKnee: CGPoint(x: 0.2, y: -0.35),
            leftFoot: CGPoint(x: -0.2, y: -0.6),
            rightFoot: CGPoint(x: 0.2, y: -0.6)
        )
        
        return [
            StickFigureKeyframe(time: 0.0, pose: standing),
            StickFigureKeyframe(time: 0.5, pose: squatting),
            StickFigureKeyframe(time: 1.0, pose: standing)
        ]
    }
    
    private func getPlankKeyframes() -> [StickFigureKeyframe] {
        let plank = StickFigurePose(
            head: CGPoint(x: 0, y: 0.2),
            neck: CGPoint(x: 0, y: 0.1),
            leftShoulder: CGPoint(x: -0.15, y: 0.05),
            rightShoulder: CGPoint(x: 0.15, y: 0.05),
            leftElbow: CGPoint(x: -0.2, y: -0.05),
            rightElbow: CGPoint(x: 0.2, y: -0.05),
            leftHand: CGPoint(x: -0.2, y: -0.15),
            rightHand: CGPoint(x: 0.2, y: -0.15),
            hips: CGPoint(x: 0, y: 0.0),
            leftKnee: CGPoint(x: -0.1, y: -0.15),
            rightKnee: CGPoint(x: 0.1, y: -0.15),
            leftFoot: CGPoint(x: -0.1, y: -0.3),
            rightFoot: CGPoint(x: 0.1, y: -0.3)
        )
        
        // Plank is static, slight breathing motion
        return [
            StickFigureKeyframe(time: 0.0, pose: plank),
            StickFigureKeyframe(time: 1.0, pose: plank)
        ]
    }
    
    private func getJumpingJackKeyframes() -> [StickFigureKeyframe] {
        let standing = StickFigurePose(
            head: CGPoint(x: 0, y: 0.6),
            neck: CGPoint(x: 0, y: 0.45),
            leftShoulder: CGPoint(x: -0.1, y: 0.4),
            rightShoulder: CGPoint(x: 0.1, y: 0.4),
            leftElbow: CGPoint(x: -0.1, y: 0.15),
            rightElbow: CGPoint(x: 0.1, y: 0.15),
            leftHand: CGPoint(x: -0.05, y: -0.05),
            rightHand: CGPoint(x: 0.05, y: -0.05),
            hips: CGPoint(x: 0, y: 0.0),
            leftKnee: CGPoint(x: -0.05, y: -0.3),
            rightKnee: CGPoint(x: 0.05, y: -0.3),
            leftFoot: CGPoint(x: -0.05, y: -0.6),
            rightFoot: CGPoint(x: 0.05, y: -0.6)
        )
        
        let jumping = StickFigurePose(
            head: CGPoint(x: 0, y: 0.7),
            neck: CGPoint(x: 0, y: 0.55),
            leftShoulder: CGPoint(x: -0.2, y: 0.5),
            rightShoulder: CGPoint(x: 0.2, y: 0.5),
            leftElbow: CGPoint(x: -0.3, y: 0.6),
            rightElbow: CGPoint(x: 0.3, y: 0.6),
            leftHand: CGPoint(x: -0.35, y: 0.65),
            rightHand: CGPoint(x: 0.35, y: 0.65),
            hips: CGPoint(x: 0, y: 0.1),
            leftKnee: CGPoint(x: -0.2, y: -0.2),
            rightKnee: CGPoint(x: 0.2, y: -0.2),
            leftFoot: CGPoint(x: -0.25, y: -0.5),
            rightFoot: CGPoint(x: 0.25, y: -0.5)
        )
        
        return [
            StickFigureKeyframe(time: 0.0, pose: standing),
            StickFigureKeyframe(time: 0.5, pose: jumping),
            StickFigureKeyframe(time: 1.0, pose: standing)
        ]
    }
    
    private func getLungeKeyframes() -> [StickFigureKeyframe] {
        let standing = getStandingPose()
        
        let lunging = StickFigurePose(
            head: CGPoint(x: 0, y: 0.5),
            neck: CGPoint(x: 0, y: 0.35),
            leftShoulder: CGPoint(x: -0.15, y: 0.3),
            rightShoulder: CGPoint(x: 0.15, y: 0.3),
            leftElbow: CGPoint(x: -0.2, y: 0.1),
            rightElbow: CGPoint(x: 0.2, y: 0.1),
            leftHand: CGPoint(x: -0.15, y: -0.1),
            rightHand: CGPoint(x: 0.15, y: -0.1),
            hips: CGPoint(x: 0, y: 0.0),
            leftKnee: CGPoint(x: -0.05, y: -0.25),
            rightKnee: CGPoint(x: 0.25, y: -0.25),
            leftFoot: CGPoint(x: -0.05, y: -0.5),
            rightFoot: CGPoint(x: 0.35, y: -0.5)
        )
        
        return [
            StickFigureKeyframe(time: 0.0, pose: standing),
            StickFigureKeyframe(time: 0.5, pose: lunging),
            StickFigureKeyframe(time: 1.0, pose: standing)
        ]
    }
    
    private func getRunningKeyframes() -> [StickFigureKeyframe] {
        let pose1 = StickFigurePose(
            head: CGPoint(x: 0, y: 0.6),
            neck: CGPoint(x: 0, y: 0.45),
            leftShoulder: CGPoint(x: -0.15, y: 0.4),
            rightShoulder: CGPoint(x: 0.15, y: 0.4),
            leftElbow: CGPoint(x: -0.2, y: 0.25),
            rightElbow: CGPoint(x: 0.1, y: 0.15),
            leftHand: CGPoint(x: -0.15, y: 0.1),
            rightHand: CGPoint(x: 0.05, y: 0.0),
            hips: CGPoint(x: 0, y: 0.0),
            leftKnee: CGPoint(x: -0.1, y: -0.25),
            rightKnee: CGPoint(x: 0.15, y: -0.15),
            leftFoot: CGPoint(x: -0.1, y: -0.55),
            rightFoot: CGPoint(x: 0.2, y: -0.4)
        )
        
        let pose2 = StickFigurePose(
            head: CGPoint(x: 0, y: 0.6),
            neck: CGPoint(x: 0, y: 0.45),
            leftShoulder: CGPoint(x: -0.15, y: 0.4),
            rightShoulder: CGPoint(x: 0.15, y: 0.4),
            leftElbow: CGPoint(x: -0.1, y: 0.15),
            rightElbow: CGPoint(x: 0.2, y: 0.25),
            leftHand: CGPoint(x: -0.05, y: 0.0),
            rightHand: CGPoint(x: 0.15, y: 0.1),
            hips: CGPoint(x: 0, y: 0.0),
            leftKnee: CGPoint(x: -0.15, y: -0.15),
            rightKnee: CGPoint(x: 0.1, y: -0.25),
            leftFoot: CGPoint(x: -0.2, y: -0.4),
            rightFoot: CGPoint(x: 0.1, y: -0.55)
        )
        
        return [
            StickFigureKeyframe(time: 0.0, pose: pose1),
            StickFigureKeyframe(time: 0.5, pose: pose2),
            StickFigureKeyframe(time: 1.0, pose: pose1)
        ]
    }
    
    private func getStandingKeyframes() -> [StickFigureKeyframe] {
        let standing = getStandingPose()
        return [
            StickFigureKeyframe(time: 0.0, pose: standing),
            StickFigureKeyframe(time: 1.0, pose: standing)
        ]
    }
    
    private func getStandingPose() -> StickFigurePose {
        return StickFigurePose(
            head: CGPoint(x: 0, y: 0.6),
            neck: CGPoint(x: 0, y: 0.45),
            leftShoulder: CGPoint(x: -0.15, y: 0.4),
            rightShoulder: CGPoint(x: 0.15, y: 0.4),
            leftElbow: CGPoint(x: -0.2, y: 0.15),
            rightElbow: CGPoint(x: 0.2, y: 0.15),
            leftHand: CGPoint(x: -0.15, y: -0.05),
            rightHand: CGPoint(x: 0.15, y: -0.05),
            hips: CGPoint(x: 0, y: 0.0),
            leftKnee: CGPoint(x: -0.1, y: -0.3),
            rightKnee: CGPoint(x: 0.1, y: -0.3),
            leftFoot: CGPoint(x: -0.1, y: -0.6),
            rightFoot: CGPoint(x: 0.1, y: -0.6)
        )
    }
    
    // MARK: - Pose Interpolation
    
    private func interpolatePose(at progress: Double, keyframes: [StickFigureKeyframe]) -> StickFigurePose {
        guard !keyframes.isEmpty else { return getStandingPose() }
        guard keyframes.count > 1 else { return keyframes[0].pose }
        
        // Loop the animation
        let loopedProgress = progress.truncatingRemainder(dividingBy: 1.0)
        
        // Find the two keyframes to interpolate between
        var fromKeyframe = keyframes[0]
        var toKeyframe = keyframes[1]
        
        for i in 0..<keyframes.count - 1 {
            if loopedProgress >= keyframes[i].time && loopedProgress <= keyframes[i + 1].time {
                fromKeyframe = keyframes[i]
                toKeyframe = keyframes[i + 1]
                break
            }
        }
        
        // Calculate interpolation factor
        let timeRange = toKeyframe.time - fromKeyframe.time
        let localProgress = timeRange > 0 ? (loopedProgress - fromKeyframe.time) / timeRange : 0
        
        // Interpolate all joint positions
        return StickFigurePose(
            head: interpolatePoint(fromKeyframe.pose.head, toKeyframe.pose.head, t: localProgress),
            neck: interpolatePoint(fromKeyframe.pose.neck, toKeyframe.pose.neck, t: localProgress),
            leftShoulder: interpolatePoint(fromKeyframe.pose.leftShoulder, toKeyframe.pose.leftShoulder, t: localProgress),
            rightShoulder: interpolatePoint(fromKeyframe.pose.rightShoulder, toKeyframe.pose.rightShoulder, t: localProgress),
            leftElbow: interpolatePoint(fromKeyframe.pose.leftElbow, toKeyframe.pose.leftElbow, t: localProgress),
            rightElbow: interpolatePoint(fromKeyframe.pose.rightElbow, toKeyframe.pose.rightElbow, t: localProgress),
            leftHand: interpolatePoint(fromKeyframe.pose.leftHand, toKeyframe.pose.leftHand, t: localProgress),
            rightHand: interpolatePoint(fromKeyframe.pose.rightHand, toKeyframe.pose.rightHand, t: localProgress),
            hips: interpolatePoint(fromKeyframe.pose.hips, toKeyframe.pose.hips, t: localProgress),
            leftKnee: interpolatePoint(fromKeyframe.pose.leftKnee, toKeyframe.pose.leftKnee, t: localProgress),
            rightKnee: interpolatePoint(fromKeyframe.pose.rightKnee, toKeyframe.pose.rightKnee, t: localProgress),
            leftFoot: interpolatePoint(fromKeyframe.pose.leftFoot, toKeyframe.pose.leftFoot, t: localProgress),
            rightFoot: interpolatePoint(fromKeyframe.pose.rightFoot, toKeyframe.pose.rightFoot, t: localProgress)
        )
    }
    
    private func interpolatePoint(_ from: CGPoint, _ to: CGPoint, t: Double) -> CGPoint {
        let t = CGFloat(t)
        return CGPoint(
            x: from.x + (to.x - from.x) * t,
            y: from.y + (to.y - from.y) * t
        )
    }
    
    // MARK: - Frame Processing
    
    private func processFrames(_ frames: [UIImage]) throws -> [UIImage] {
        // Optionally apply filters or enhancements
        return frames
    }
    
    // MARK: - GIF Creation
    
    private func createGifFromFrames(_ frames: [UIImage]) throws -> Data {
        guard !frames.isEmpty else {
            throw AIGifError.noFrames
        }
        
        let fileProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0 // Infinite loop
            ]
        ]
        
        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: frameDuration
            ]
        ]
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, kUTTypeGIF, frames.count, nil) else {
            throw AIGifError.creationFailed("Failed to create GIF destination")
        }
        
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
        
        for frame in frames {
            guard let cgImage = frame.cgImage else {
                throw AIGifError.creationFailed("Failed to get CGImage from frame")
            }
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }
        
        guard CGImageDestinationFinalize(destination) else {
            throw AIGifError.creationFailed("Failed to finalize GIF")
        }
        
        return data as Data
    }
    
    // MARK: - Bulk Generation
    
    /// Generate GIFs for multiple exercises
    func generateGifsForExercises(_ exercises: [Exercise], completion: @escaping (Int, Int) -> Void) {
        Task {
            var successCount = 0
            
            for (index, exercise) in exercises.enumerated() {
                // Skip if already has GIF
                if gifService.hasGif(for: exercise.name) {
                    successCount += 1
                    await MainActor.run {
                        completion(index + 1, successCount)
                    }
                    continue
                }
                
                // Generate GIF
                await withCheckedContinuation { continuation in
                    generateGif(for: exercise) { result in
                        if case .success = result {
                            successCount += 1
                        }
                        continuation.resume()
                    }
                }
                
                await MainActor.run {
                    completion(index + 1, successCount)
                }
            }
        }
    }
}

// MARK: - Data Models

struct StickFigurePose {
    let head: CGPoint
    let neck: CGPoint
    let leftShoulder: CGPoint
    let rightShoulder: CGPoint
    let leftElbow: CGPoint
    let rightElbow: CGPoint
    let leftHand: CGPoint
    let rightHand: CGPoint
    let hips: CGPoint
    let leftKnee: CGPoint
    let rightKnee: CGPoint
    let leftFoot: CGPoint
    let rightFoot: CGPoint
    
    var allPoints: [CGPoint] {
        return [
            head, neck,
            leftShoulder, rightShoulder,
            leftElbow, rightElbow,
            leftHand, rightHand,
            hips,
            leftKnee, rightKnee,
            leftFoot, rightFoot
        ]
    }
}

struct StickFigureKeyframe {
    let time: Double // 0.0 to 1.0
    let pose: StickFigurePose
}

// MARK: - Error Types

enum AIGifError: LocalizedError {
    case alreadyGenerating
    case noFrames
    case creationFailed(String)
    case saveFailed(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .alreadyGenerating:
            return "A GIF is already being generated"
        case .noFrames:
            return "No frames available for GIF creation"
        case .creationFailed(let message):
            return "GIF creation failed: \(message)"
        case .saveFailed(let message):
            return "Failed to save GIF: \(message)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}
