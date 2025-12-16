import Foundation

struct ParsedItem: Codable {
    let name: String
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
}

// DTO expected by backend when saving corrected meal
struct ParsedItemDTO: Codable {
    let name: String
    let qtyText: String
    let calories: Double
    let protein: Double?
    let carbs: Double?
    let fat: Double?
}
