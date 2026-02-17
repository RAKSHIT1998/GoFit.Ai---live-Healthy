import Foundation

/// APIConfig provides centralized backend URL configuration
/// Uses UserDefaults for stored backend URL or defaults to localhost development server
struct APIConfig {
    /// Base URL for API endpoints
    static var baseURL: String {
        // Check if a backend URL has been stored in UserDefaults
        if let storedURL = UserDefaults.standard.string(forKey: "backendURL"), !storedURL.isEmpty {
            return storedURL
        }
        
        // Default to local development server
        return "http://localhost:3000"
    }
    
    /// Update the backend URL stored in UserDefaults
    /// - Parameter url: The new backend URL to use
    static func setBaseURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "backendURL")
    }
}
