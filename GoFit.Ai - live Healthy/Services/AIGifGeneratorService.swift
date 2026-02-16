import SwiftUI
import Vision
import CoreImage
import AVFoundation
import UniformTypeIdentifiers

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
                let saveSuccess = gifService.saveGifData(gifData, for: exercise.name)
                
                if saveSuccess {
                    await MainActor.run {
                        generationProgress = 1.0
                        isGenerating = false
                    }
                    completion(.success(gifData))
                } else {
                    await MainActor.run {
                        isGenerating = false
                        lastError = "Failed to save GIF to device"
                    }
                    completion(.failure(.saveFailed("Failed to save GIF to device")))
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
            
            // Modern gradient background
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0).cgColor,
                UIColor(red: 0.85, green: 0.90, blue: 0.98, alpha: 1.0).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
            ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
            
            // Draw grid pattern for reference
            ctx.setStrokeColor(UIColor.systemGray5.cgColor)
            ctx.setLineWidth(0.5)
            let gridSpacing: CGFloat = 40
            for i in stride(from: 0, through: size.width, by: gridSpacing) {
                ctx.move(to: CGPoint(x: i, y: 0))
                ctx.addLine(to: CGPoint(x: i, y: size.height))
            }
            for i in stride(from: 0, through: size.height, by: gridSpacing) {
                ctx.move(to: CGPoint(x: 0, y: i))
                ctx.addLine(to: CGPoint(x: size.width, y: i))
            }
            ctx.strokePath()
            
            // Get current pose by interpolating keyframes
            let pose = interpolatePose(at: progress, keyframes: keyframes)
            
            // Draw shadow first
            drawShadow(ctx: ctx, pose: pose, size: size)
            
            // Draw enhanced figure
            drawEnhancedFigure(ctx: ctx, pose: pose, size: size, exercise: exercise)
            
            // Add exercise name with styled background
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let text = exercise.name
            let textSize = text.size(withAttributes: attrs)
            let padding: CGFloat = 12
            let badgeRect = CGRect(
                x: (size.width - textSize.width - padding * 2) / 2,
                y: size.height - 50,
                width: textSize.width + padding * 2,
                height: textSize.height + padding
            )
            
            // Draw badge background
            ctx.setFillColor(UIColor.systemBlue.cgColor)
            let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: 8)
            ctx.addPath(badgePath.cgPath)
            ctx.fillPath()
            
            // Draw text
            let textRect = CGRect(
                x: badgeRect.minX + padding,
                y: badgeRect.minY + padding / 2,
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
        
        // Save state for shadow
        ctx.saveGState()
        
        // Draw body parts with gradients and thickness
        ctx.setLineWidth(8)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        
        // Head with gradient
        let headCenter = transform(pose.head)
        let headRadius: CGFloat = 25
        let headRect = CGRect(
            x: headCenter.x - headRadius,
            y: headCenter.y - headRadius,
            width: headRadius * 2,
            height: headRadius * 2
        )
        
        // Head gradient (skin tone)
        let headColorSpace = CGColorSpaceCreateDeviceRGB()
        let headColors = [
            UIColor(red: 0.95, green: 0.76, blue: 0.65, alpha: 1.0).cgColor,
            UIColor(red: 0.90, green: 0.70, blue: 0.58, alpha: 1.0).cgColor
        ] as CFArray
        let headGradient = CGGradient(colorsSpace: headColorSpace, colors: headColors, locations: [0.0, 1.0])!
        ctx.saveGState()
        ctx.addEllipse(in: headRect)
        ctx.clip()
        ctx.drawRadialGradient(headGradient, startCenter: CGPoint(x: headCenter.x - 5, y: headCenter.y - 5), startRadius: 5, endCenter: headCenter, endRadius: headRadius, options: [])
        ctx.restoreGState()
        
        // Head outline
        ctx.setStrokeColor(UIColor(red: 0.8, green: 0.6, blue: 0.5, alpha: 1.0).cgColor)
        ctx.setLineWidth(2)
        ctx.addEllipse(in: headRect)
        ctx.strokePath()
        
        // Body (torso) - Blue athletic shirt
        ctx.setStrokeColor(UIColor.systemBlue.cgColor)
        ctx.setLineWidth(12)
        ctx.move(to: transform(pose.neck))
        ctx.addLine(to: transform(pose.hips))
        ctx.strokePath()
        
        // Arms - with muscle definition
        ctx.setLineWidth(10)
        
        // Left arm
        drawLimb(ctx: ctx, from: transform(pose.leftShoulder), via: transform(pose.leftElbow), to: transform(pose.leftHand), color: UIColor(red: 0.95, green: 0.76, blue: 0.65, alpha: 1.0))
        
        // Right arm
        drawLimb(ctx: ctx, from: transform(pose.rightShoulder), via: transform(pose.rightElbow), to: transform(pose.rightHand), color: UIColor(red: 0.95, green: 0.76, blue: 0.65, alpha: 1.0))
        
        // Legs - Black athletic pants
        ctx.setLineWidth(12)
        
        // Left leg
        drawLimb(ctx: ctx, from: transform(pose.hips), via: transform(pose.leftKnee), to: transform(pose.leftFoot), color: UIColor.darkGray)
        
        // Right leg
        drawLimb(ctx: ctx, from: transform(pose.hips), via: transform(pose.rightKnee), to: transform(pose.rightFoot), color: UIColor.darkGray)
        
        // Joints with depth
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.setShadow(offset: CGSize(width: 1, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.3).cgColor)
        
        let jointRadius: CGFloat = 6
        let joints = [pose.neck, pose.leftShoulder, pose.rightShoulder, pose.leftElbow, pose.rightElbow, pose.leftHand, pose.rightHand, pose.hips, pose.leftKnee, pose.rightKnee, pose.leftFoot, pose.rightFoot]
        
        for point in joints {
            let transformed = transform(point)
            ctx.fillEllipse(in: CGRect(
                x: transformed.x - jointRadius,
                y: transformed.y - jointRadius,
                width: jointRadius * 2,
                height: jointRadius * 2
            ))
        }
        
        ctx.restoreGState()
    }
    
    private func drawLimb(ctx: CGContext, from start: CGPoint, via middle: CGPoint, to end: CGPoint, color: UIColor) {
        // Upper segment
        ctx.setStrokeColor(color.cgColor)
        ctx.move(to: start)
        ctx.addLine(to: middle)
        ctx.strokePath()
        
        // Lower segment with slight shading
        ctx.setStrokeColor(color.withAlphaComponent(0.9).cgColor)
        ctx.move(to: middle)
        ctx.addLine(to: end)
        ctx.strokePath()
    }
    
    private func createBodyGradient() -> CGGradient {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor.systemBlue.cgColor,
            UIColor.systemBlue.withAlphaComponent(0.8).cgColor
        ] as CFArray
        return CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
    }
    
    private func drawShadow(ctx: CGContext, pose: StickFigurePose, size: CGSize) {
        let scale = min(size.width, size.height) * 0.6
        let offsetX = size.width / 2
        let offsetY = size.height / 2
        
        func transform(_ point: CGPoint) -> CGPoint {
            return CGPoint(
                x: offsetX + point.x * scale,
                y: offsetY - point.y * scale
            )
        }
        
        // Draw shadow ellipse at feet
        let shadowY = max(transform(pose.leftFoot).y, transform(pose.rightFoot).y) + 10
        let shadowRect = CGRect(x: offsetX - 40, y: shadowY, width: 80, height: 20)
        
        ctx.saveGState()
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.1).cgColor)
        ctx.fillEllipse(in: shadowRect)
        ctx.restoreGState()
    }
    
    private func drawEnhancedFigure(ctx: CGContext, pose: StickFigurePose, size: CGSize, exercise: Exercise) {
        drawStickFigure(ctx: ctx, pose: pose, size: size, exercise: exercise)
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
        guard let destination = CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, frames.count, nil) else {
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
        Task { @MainActor in
            var successCount = 0
            
            for (index, exercise) in exercises.enumerated() {
                // Skip if already has GIF
                if gifService.hasGif(for: exercise.name) {
                    successCount += 1
                    completion(index + 1, successCount)
                    continue
                }
                
                // Generate GIF
                let result = await withCheckedContinuation { continuation in
                    generateGif(for: exercise) { result in
                        continuation.resume(returning: result)
                    }
                }
                
                if case .success(_) = result {
                    successCount += 1
                }
                
                completion(index + 1, successCount)
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
