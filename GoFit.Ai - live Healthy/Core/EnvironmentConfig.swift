import Foundation

struct EnvironmentConfig {
    // Render backend URL - Your deployed backend service
    private static let renderBackendURL = "https://gofit-ai-live-healthy.onrender.com/api"
    
    static var apiBaseURL: String {
        #if DEBUG
        // Using Render backend for development
        // To use local backend instead, change this to: "http://localhost:3000/api"
        return renderBackendURL
        #else
        // Production: Using Render backend
        return renderBackendURL
        #endif
    }
    
    static var openAIApiKey: String {
        // Should be stored in environment variables or secure storage
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    static var s3BucketName: String {
        return ProcessInfo.processInfo.environment["S3_BUCKET_NAME"] ?? "gofit-ai-meals"
    }
}
