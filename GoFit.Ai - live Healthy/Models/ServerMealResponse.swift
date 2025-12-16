import Foundation

struct ServerMealResponse: Codable {
    let mealId: String?
    let parsedItems: [ParsedItem]?
    let recommendations: String?
}
