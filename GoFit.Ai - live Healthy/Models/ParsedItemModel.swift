import Foundation

struct ParsedItem: Codable {
    let name: String
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let sugar: Double? // Added sugar field
    let portionSize: String? // Added portion size
    let confidence: Double? // AI confidence score
}

// DTO expected by backend when saving corrected meal
struct ParsedItemDTO: Codable {
    let name: String
    let qtyText: String
    let calories: Double
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let sugar: Double? // Added sugar field
}
