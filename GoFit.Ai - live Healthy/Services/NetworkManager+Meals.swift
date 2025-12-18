import Foundation

extension NetworkManager {
    // Save the final corrected meal items to the backend (and persist in DB)
    func saveParsedMeal(userId: String?, items: [ParsedItemDTO]) async throws -> ServerMealResponse {
        let url = baseURL.appendingPathComponent("meals/save")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        if let token = AuthService.shared.readToken()?.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Calculate totals
        let totalCalories = items.reduce(0) { $0 + $1.calories }
        let totalProtein = items.reduce(0) { $0 + ($1.protein ?? 0) }
        let totalCarbs = items.reduce(0) { $0 + ($1.carbs ?? 0) }
        let totalFat = items.reduce(0) { $0 + ($1.fat ?? 0) }
        let totalSugar = items.reduce(0) { $0 + ($1.sugar ?? 0) }
        
        let payload: [String: Any] = [
            "items": try JSONEncoder().encodeToJSONObject(items),
            "totalCalories": totalCalories,
            "totalProtein": totalProtein,
            "totalCarbs": totalCarbs,
            "totalFat": totalFat,
            "totalSugar": totalSugar,
            "mealType": "snack", // Default, can be changed
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        req.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (d, r) = try await URLSession.shared.data(for: req)
        guard let httpResponse = r as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            let statusCode = (r as? HTTPURLResponse)?.statusCode ?? -1
            if let err = String(data: d, encoding: .utf8) {
                throw NSError(domain: "SaveMealError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: err])
            }
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(ServerMealResponse.self, from: d)
        return decoded
    }
}

// Helper extension to convert Codable -> JSON object (for payload)
fileprivate extension JSONEncoder {
    func encodeToJSONObject<T: Encodable>(_ value: T) throws -> Any {
        let data = try self.encode(value)
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
}
