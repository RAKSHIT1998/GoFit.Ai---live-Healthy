import Foundation
import UIKit
import SwiftUI

@MainActor
class ShareService {
    static let shared = ShareService()
    
    private init() {}
    
    // MARK: - Share Progress Data
    func shareProgress(
        calories: String,
        steps: Int,
        activeCalories: Double,
        waterIntake: Double,
        heartRate: Double?,
        userName: String
    ) {
        let shareText = generateShareText(
            calories: calories,
            steps: steps,
            activeCalories: activeCalories,
            waterIntake: waterIntake,
            heartRate: heartRate,
            userName: userName
        )
        
        shareContent(text: shareText)
    }
    
    // MARK: - Share Progress Image
    func shareProgressImage(
        calories: String,
        steps: Int,
        activeCalories: Double,
        waterIntake: Double,
        heartRate: Double?,
        userName: String,
        completion: @escaping (UIImage?) -> Void
    ) {
        // Generate the image
        let image = generateProgressImage(
            calories: calories,
            steps: steps,
            activeCalories: activeCalories,
            waterIntake: waterIntake,
            heartRate: heartRate,
            userName: userName
        )
        
        completion(image)
        
        // Share the image
        if let image = image {
            shareImage(image: image, text: "Check out my fitness progress with GoFit.Ai! 💪")
        }
    }
    
    // MARK: - Generate Share Text
    private func generateShareText(
        calories: String,
        steps: Int,
        activeCalories: Double,
        waterIntake: Double,
        heartRate: Double?,
        userName: String
    ) -> String {
        var text = "💪 My Fitness Progress Today\n\n"
        text += "📊 Stats:\n"
        text += "🔥 Calories: \(calories)\n"
        text += "🚶 Steps: \(steps.formatted())\n"
        text += "⚡ Active Calories: \(Int(activeCalories).formatted())\n"
        text += "💧 Water: \(String(format: "%.1f", waterIntake))L\n"
        
        if let heartRate = heartRate, heartRate > 0 {
            text += "❤️ Heart Rate: \(Int(heartRate)) bpm\n"
        }
        
        text += "\n#GoFitAi #Fitness #Health #Wellness"
        
        return text
    }
    
    // MARK: - Generate Progress Image
    private func generateProgressImage(
        calories: String,
        steps: Int,
        activeCalories: Double,
        waterIntake: Double,
        heartRate: Double?,
        userName: String
    ) -> UIImage? {
        let size = CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background gradient
            let colors = [
                UIColor.systemBlue.cgColor,
                UIColor.systemPurple.cgColor
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil) else {
                return
            }
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // White content area (rounded rectangle instead of ellipse)
            let contentRect = CGRect(x: 60, y: 60, width: size.width - 120, height: size.height - 120)
            let path = UIBezierPath(roundedRect: contentRect, cornerRadius: 40)
            UIColor.white.setFill()
            path.fill()
            
            // Title
            let titleText = "My Fitness Progress"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let titleSize = titleText.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: 180,
                width: titleSize.width,
                height: titleSize.height
            )
            titleText.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Stats
            let statsY: CGFloat = 400
            let statsSpacing: CGFloat = 100
            var currentY = statsY
            
            // Calories
            drawStat(
                context: context,
                icon: "🔥",
                value: calories,
                label: "Calories",
                y: currentY,
                width: size.width
            )
            currentY += statsSpacing
            
            // Steps
            drawStat(
                context: context,
                icon: "🚶",
                value: "\(steps.formatted())",
                label: "Steps",
                y: currentY,
                width: size.width
            )
            currentY += statsSpacing
            
            // Active Calories
            drawStat(
                context: context,
                icon: "⚡",
                value: "\(Int(activeCalories).formatted())",
                label: "Active Calories",
                y: currentY,
                width: size.width
            )
            currentY += statsSpacing
            
            // Water
            drawStat(
                context: context,
                icon: "💧",
                value: "\(String(format: "%.1f", waterIntake))L",
                label: "Water",
                y: currentY,
                width: size.width
            )
            
            // Heart Rate (if available)
            if let heartRate = heartRate, heartRate > 0 {
                currentY += statsSpacing
                drawStat(
                    context: context,
                    icon: "❤️",
                    value: "\(Int(heartRate))",
                    label: "Heart Rate (bpm)",
                    y: currentY,
                    width: size.width
                )
            }
            
            // Footer
            let footerText = "#GoFitAi #Fitness #Health"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let footerSize = footerText.size(withAttributes: footerAttributes)
            let footerRect = CGRect(
                x: (size.width - footerSize.width) / 2,
                y: size.height - 150,
                width: footerSize.width,
                height: footerSize.height
            )
            footerText.draw(in: footerRect, withAttributes: footerAttributes)
        }
    }
    
    private func drawStat(
        context: UIGraphicsImageRendererContext,
        icon: String,
        value: String,
        label: String,
        y: CGFloat,
        width: CGFloat
    ) {
        let fontSize: CGFloat = 40
        let labelFontSize: CGFloat = 28
        
        // Icon
        let iconAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize)
        ]
        let iconSize = icon.size(withAttributes: iconAttributes)
        let iconRect = CGRect(x: 200, y: y, width: iconSize.width, height: iconSize.height)
        icon.draw(in: iconRect, withAttributes: iconAttributes)
        
        // Value
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        let valueSize = value.size(withAttributes: valueAttributes)
        let valueRect = CGRect(x: 280, y: y, width: valueSize.width, height: valueSize.height)
        value.draw(in: valueRect, withAttributes: valueAttributes)
        
        // Label
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: labelFontSize),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let labelSize = label.size(withAttributes: labelAttributes)
        let labelRect = CGRect(x: width - 200 - labelSize.width, y: y + 8, width: labelSize.width, height: labelSize.height)
        label.draw(in: labelRect, withAttributes: labelAttributes)
    }
    
    // MARK: - Share Content
    private func shareContent(text: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ Could not find root view controller for sharing")
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityVC, animated: true)
    }
    
    private func shareImage(image: UIImage, text: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ Could not find root view controller for sharing")
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [image, text],
            applicationActivities: nil
        )
        
        // Exclude some activities
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList
        ]
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityVC, animated: true)
    }
}

// MARK: - SwiftUI Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // For iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}