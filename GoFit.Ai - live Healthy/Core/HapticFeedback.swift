import UIKit

// MARK: - Haptic Feedback Manager
class HapticManager {
    static let shared = HapticManager()
    
    func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func mediumTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func heavyTap() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    // Legacy static methods for backward compatibility
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

