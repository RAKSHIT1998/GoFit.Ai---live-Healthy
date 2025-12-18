import Foundation

// Response from /photo/analyze endpoint
struct PhotoAnalysisResponse: Codable {
    let items: [ParsedItem]
    let imageUrl: String?
    let imageKey: String?
    let totalCalories: Double?
    let totalProtein: Double?
    let totalCarbs: Double?
    let totalFat: Double?
    let totalSugar: Double?
    let aiVersion: String?
}

