import Foundation

struct WatchNutritionPayload: Codable, Equatable {
    let timestamp: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let water: Double

    static let empty = WatchNutritionPayload(
        timestamp: Date(),
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        water: 0
    )
}
