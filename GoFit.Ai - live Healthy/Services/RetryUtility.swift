import Foundation

// MARK: - Retry Utility
// Provides automatic retry logic with exponential backoff for AI requests
struct RetryUtility {
    static let shared = RetryUtility()
    
    // Maximum number of retry attempts
    static let maxRetries = 5
    
    // Base delay in seconds (exponential backoff: 1s, 2s, 4s, 8s, 16s)
    static let baseDelay: TimeInterval = 1.0
    
    /**
     * Retry an async operation with exponential backoff
     * - Parameters:
     *   - maxAttempts: Maximum number of attempts (default: 5)
     *   - operation: The async operation to retry
     * - Returns: Result of the operation
     * - Throws: Error if all attempts fail
     */
    func retry<T>(
        maxAttempts: Int = maxRetries,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on certain errors (authentication, validation)
                if shouldNotRetry(error) {
                    throw error
                }
                
                // If this is the last attempt, throw the error
                if attempt == maxAttempts - 1 {
                    throw error
                }
                
                // Calculate exponential backoff delay
                let delay = baseDelay * pow(2.0, Double(attempt))
                
                #if DEBUG
                print("🔄 Retry attempt \(attempt + 1)/\(maxAttempts) after \(delay)s delay...")
                #endif
                
                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        // Should never reach here, but just in case
        throw lastError ?? NSError(domain: "RetryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "All retry attempts failed"])
    }
    
    /**
     * Check if an error should not be retried
     * - Parameter error: The error to check
     * - Returns: true if error should not be retried
     */
    private func shouldNotRetry(_ error: Error) -> Bool {
        if let nsError = error as NSError? {
            // Don't retry authentication errors (401)
            if nsError.code == 401 {
                return true
            }
            
            // Don't retry validation errors (400) except for rate limits
            if nsError.code == 400 {
                let message = (nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? "").lowercased()
                // Retry rate limit errors (429), but not other 400 errors
                return !message.contains("rate limit") && !message.contains("429")
            }
            
            // Don't retry client errors (4xx) except rate limits
            if (400..<500).contains(nsError.code) && nsError.code != 429 {
                return true
            }
        }
        
        return false
    }
}

