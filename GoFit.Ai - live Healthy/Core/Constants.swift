import Foundation
import SwiftUI

// App-wide constants
struct AppConstants {
    static let appName = "GoFit.ai"
    static let tagline = "Your AI-powered health companion"
    
    // API
    static let apiBaseURL = EnvironmentConfig.apiBaseURL
    
    // Defaults
    static let defaultWaterGoal: Double = 2.5 // liters
    static let defaultCalorieGoal: Int = 2000
    static let defaultFastingWindow: Int = 16 // hours
}

// Design typealias is now in DesignSystem.swift for better accessibility
