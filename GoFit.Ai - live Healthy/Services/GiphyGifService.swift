import SwiftUI
import Foundation

// MARK: - Giphy GIF Service
/// Service to fetch and cache exercise GIFs from Giphy API
final class GiphyGifService: ObservableObject {
    static let shared = GiphyGifService()
    
    private let apiKey: String
    private let baseURL = "https://api.giphy.com/v1/gifs/search"
    private let cache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private var gifDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("GiphyExerciseGifs")
    }
    
    @Published var isSearching = false
    @Published var lastError: String?
    
    init() {
        // Load Giphy API key from environment or config file
        if let key = ProcessInfo.processInfo.environment["GIPHY_API_KEY"] {
            self.apiKey = key
        } else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                  let config = NSDictionary(contentsOfFile: path) as? [String: String],
                  let key = config["GIPHY_API_KEY"] {
            self.apiKey = key
        } else {
            self.apiKey = "" // Will need to be set by user
        }
        
        setupGifDirectory()
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB cache limit
    }
    
    // MARK: - Setup
    
    private func setupGifDirectory() {
        if !fileManager.fileExists(atPath: gifDirectory.path) {
            try? fileManager.createDirectory(at: gifDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Fetch GIFs from Giphy
    
    /// Fetch GIF URL from Giphy for an exercise
    /// - Parameters:
    ///   - exerciseName: Name of the exercise (e.g., "push-ups", "squats")
    ///   - completion: Callback with GIF data or error
    func fetchGifData(for exerciseName: String, completion: @escaping (Result<Data, GiphyError>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(.noApiKey))
            return
        }
        
        // Check memory cache first
        let cacheKey = NSString(string: exerciseName)
        if let cachedData = cache.object(forKey: cacheKey) {
            completion(.success(cachedData as Data))
            return
        }
        
        // Check disk cache
        if let diskData = loadGifFromDisk(for: exerciseName) {
            cache.setObject(diskData as NSData, forKey: cacheKey)
            completion(.success(diskData))
            return
        }
        
        // Fetch from Giphy API
        isSearching = true
        fetchFromGiphy(exerciseName) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSearching = false
            }
            
            switch result {
            case .success(let gifUrl):
                self?.downloadAndCacheGif(from: gifUrl, for: exerciseName, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Giphy API Request
    
    private func fetchFromGiphy(_ searchQuery: String, completion: @escaping (Result<URL, GiphyError>) -> Void) {
        // Build API request
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "q", value: "\(searchQuery) exercise fitness gym"),
            URLQueryItem(name: "limit", value: "1"),
            URLQueryItem(name: "offset", value: "0"),
            URLQueryItem(name: "rating", value: "g"),
            URLQueryItem(name: "bundle", value: "messaging_non_clips")
        ]
        
        guard let url = components?.url else {
            completion(.failure(.invalidRequest))
            return
        }
        
        print("🔍 Fetching GIF from Giphy for: \(searchQuery)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Check for network errors
            if let error = error {
                print("❌ Giphy API error: \(error.localizedDescription)")
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Giphy API returned status: \(httpResponse.statusCode)")
                completion(.failure(.apiError("Status: \(httpResponse.statusCode)")))
                return
            }
            
            // Parse JSON response
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(GiphyResponse.self, from: data)
                
                // Get the first GIF result
                guard let gif = response.data.first else {
                    print("⚠️ No GIF found for: \(searchQuery)")
                    completion(.failure(.noGifFound))
                    return
                }
                
                let gifUrl = gif.images.original.url ?? gif.images.fixed_height?.url ?? gif.images.fixed_width?.url ?? gif.images.downsized?.url
                
                guard let validGifUrl = gifUrl else {
                    print("⚠️ No GIF URL found for: \(searchQuery)")
                    completion(.failure(.noGifFound))
                    return
                }
                
                print("✅ Found GIF for \(searchQuery): \(validGifUrl.absoluteString)")
                completion(.success(validGifUrl))
            } catch {
                print("❌ Failed to decode Giphy response: \(error)")
                completion(.failure(.decodingError(error.localizedDescription)))
            }
        }.resume()
    }
    
    // MARK: - Download and Cache
    
    private func downloadAndCacheGif(from url: URL, for exerciseName: String, completion: @escaping (Result<Data, GiphyError>) -> Void) {
        print("⬇️ Downloading GIF from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Check for errors
            if let error = error {
                print("❌ Download error: \(error.localizedDescription)")
                completion(.failure(.downloadError(error.localizedDescription)))
                return
            }
            
            // Validate data
            guard let gifData = data, !gifData.isEmpty else {
                print("❌ No data received")
                completion(.failure(.noData))
                return
            }
            
            // Save to cache
            let cacheKey = NSString(string: exerciseName)
            self.cache.setObject(gifData as NSData, forKey: cacheKey)
            
            // Save to disk
            let fileName = exerciseName.lowercased().replacingOccurrences(of: " ", with: "_")
            let filePath = self.gifDirectory.appendingPathComponent("\(fileName).gif")
            
            do {
                try gifData.write(to: filePath)
                print("✅ Cached GIF for: \(exerciseName) (\(gifData.count) bytes)")
                completion(.success(gifData))
            } catch {
                print("⚠️ Failed to save to disk, but returning from cache: \(error)")
                completion(.success(gifData))
            }
        }.resume()
    }
    
    // MARK: - Disk Cache Management
    
    private func loadGifFromDisk(for exerciseName: String) -> Data? {
        let fileName = exerciseName.lowercased().replacingOccurrences(of: " ", with: "_")
        let filePath = gifDirectory.appendingPathComponent("\(fileName).gif")
        
        guard fileManager.fileExists(atPath: filePath.path) else {
            return nil
        }
        
        return try? Data(contentsOf: filePath)
    }
    
    /// Check if GIF exists in cache or disk
    func hasGif(for exerciseName: String) -> Bool {
        let cacheKey = NSString(string: exerciseName)
        if cache.object(forKey: cacheKey) != nil {
            return true
        }
        
        let fileName = exerciseName.lowercased().replacingOccurrences(of: " ", with: "_")
        let filePath = gifDirectory.appendingPathComponent("\(fileName).gif")
        return fileManager.fileExists(atPath: filePath.path)
    }
    
    /// Get GIF data (from cache or disk)
    func getGifData(for exerciseName: String) -> Data? {
        let cacheKey = NSString(string: exerciseName)
        
        // Check memory cache
        if let cachedData = cache.object(forKey: cacheKey) {
            return cachedData as Data
        }
        
        // Load from disk
        if let diskData = loadGifFromDisk(for: exerciseName) {
            cache.setObject(diskData as NSData, forKey: cacheKey)
            return diskData
        }
        
        return nil
    }
    
    /// Clear all cached GIFs
    func clearAllGifs() -> Bool {
        do {
            try fileManager.removeItem(at: gifDirectory)
            cache.removeAllObjects()
            setupGifDirectory()
            print("✅ Cleared all Giphy GIFs")
            return true
        } catch {
            print("❌ Failed to clear GIFs: \(error)")
            return false
        }
    }
    
    /// Get total storage used
    func getStorageUsage() -> Int64 {
        let files = try? fileManager.contentsOfDirectory(at: gifDirectory, includingPropertiesForKeys: [.fileSizeKey])
        
        var totalSize: Int64 = 0
        files?.forEach { url in
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        
        return totalSize
    }
    
    func getStorageUsageMB() -> Double {
        return Double(getStorageUsage()) / (1024 * 1024)
    }
}

// MARK: - Giphy API Models

struct GiphyResponse: Codable {
    let data: [GiphyGif]
    let pagination: GiphyPagination
}

struct GiphyGif: Codable {
    let id: String
    let title: String
    let images: GiphyImages
    let url: URL?
}

struct GiphyImages: Codable {
    let original: GiphyImage
    let fixed_height: GiphyImage?
    let fixed_width: GiphyImage?
    let downsized: GiphyImage?
}

struct GiphyImage: Codable {
    let url: URL?
    let width: String?
    let height: String?
    let size: String?
    let frames: String?
    let mp4: URL?
    let webp: URL?
}

struct GiphyPagination: Codable {
    let total_count: Int
    let count: Int
    let offset: Int
}

// MARK: - Error Types

enum GiphyError: LocalizedError {
    case noApiKey
    case invalidRequest
    case invalidResponse
    case noData
    case decodingError(String)
    case networkError(String)
    case apiError(String)
    case downloadError(String)
    case noGifFound
    
    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "Giphy API key not configured"
        case .invalidRequest:
            return "Invalid API request"
        case .invalidResponse:
            return "Invalid API response"
        case .noData:
            return "No data received from Giphy"
        case .decodingError(let msg):
            return "Failed to decode: \(msg)"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .apiError(let msg):
            return "API error: \(msg)"
        case .downloadError(let msg):
            return "Download error: \(msg)"
        case .noGifFound:
            return "No suitable GIF found for this exercise"
        }
    }
}
