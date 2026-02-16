import SwiftUI
import AVKit
import ImageIO

/// View to display animated GIFs for exercises
struct GifImageView: View {
    let gifData: Data?
    let loopCount: Int = 0 // 0 means infinite loop
    @State private var animatedImage: UIImage?
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        ZStack {
            if let image = animatedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
            } else if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading animation...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
            } else if let error = error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                    Text("Animation unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "film.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                    Text("No animation available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
            }
        }
        .onAppear {
            loadGif()
        }
    }
    
    private func loadGif() {
        guard let gifData = gifData, !gifData.isEmpty else {
            error = "No data"
            return
        }
        
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let image = try createAnimatedImage(from: gifData)
                DispatchQueue.main.async {
                    withAnimation {
                        self.animatedImage = image
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createAnimatedImage(from data: Data) throws -> UIImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw GifError.invalidData
        }
        
        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: TimeInterval = 0
        
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                continue
            }
            
            images.append(UIImage(cgImage: cgImage))
            
            // Get frame duration
            let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any]
            let gifProperties = properties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
            let frameDuration = (gifProperties?[kCGImagePropertyGIFDelayTime as String] as? NSNumber) ?? 0.1
            duration += frameDuration.doubleValue
        }
        
        if images.isEmpty {
            throw GifError.noFrames
        }
        
        // Create animated image
        return UIImage.animatedImage(with: images, duration: max(duration, 1.0)) ?? images[0]
    }
}

enum GifError: Error {
    case invalidData
    case noFrames
    case processingFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "Invalid GIF data"
        case .noFrames:
            return "No frames found in GIF"
        case .processingFailed:
            return "Failed to process GIF"
        }
    }
}

// MARK: - Exercise GIF Service

/// Service to manage exercise GIF animations
final class ExerciseGifService {
    static let shared = ExerciseGifService()
    
    private let cache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private var gifDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ExerciseGifs")
    }
    
    private init() {
        setupGifDirectory()
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB cache limit
    }
    
    // MARK: - Directory Management
    
    private func setupGifDirectory() {
        if !fileManager.fileExists(atPath: gifDirectory.path) {
            try? fileManager.createDirectory(at: gifDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - GIF Management
    
    /// Get GIF data for an exercise
    func getGifData(for exerciseName: String) -> Data? {
        let cacheKey = NSString(string: exerciseName)
        
        // Check memory cache first
        if let cachedData = cache.object(forKey: cacheKey) {
            return cachedData as Data
        }
        
        // Load from disk
        let gifData = loadGifFromDisk(for: exerciseName)
        
        // Cache in memory
        if let data = gifData {
            cache.setObject(data as NSData, forKey: cacheKey)
        }
        
        return gifData
    }
    
    /// Save GIF data for an exercise
    func saveGifData(_ data: Data, for exerciseName: String) -> Bool {
        let fileName = exerciseName.lowercased().replacingOccurrences(of: " ", with: "_")
        let filePath = gifDirectory.appendingPathComponent("\(fileName).gif")
        
        do {
            try data.write(to: filePath)
            
            // Also cache in memory
            let cacheKey = NSString(string: exerciseName)
            cache.setObject(data as NSData, forKey: cacheKey)
            
            print("✅ Saved GIF for exercise: \(exerciseName)")
            return true
        } catch {
            print("❌ Failed to save GIF for exercise \(exerciseName): \(error)")
            return false
        }
    }
    
    /// Load GIF from disk
    private func loadGifFromDisk(for exerciseName: String) -> Data? {
        let fileName = exerciseName.lowercased().replacingOccurrences(of: " ", with: "_")
        let filePath = gifDirectory.appendingPathComponent("\(fileName).gif")
        
        return try? Data(contentsOf: filePath)
    }
    
    /// Check if GIF exists for exercise
    func hasGif(for exerciseName: String) -> Bool {
        let fileName = exerciseName.lowercased().replacingOccurrences(of: " ", with: "_")
        let filePath = gifDirectory.appendingPathComponent("\(fileName).gif")
        return fileManager.fileExists(atPath: filePath.path)
    }
    
    /// Delete GIF for exercise
    func deleteGif(for exerciseName: String) -> Bool {
        let fileName = exerciseName.lowercased().replacingOccurrences(of: " ", with: "_")
        let filePath = gifDirectory.appendingPathComponent("\(fileName).gif")
        
        do {
            try fileManager.removeItem(at: filePath)
            
            // Remove from cache
            let cacheKey = NSString(string: exerciseName)
            cache.removeObject(forKey: cacheKey)
            
            print("✅ Deleted GIF for exercise: \(exerciseName)")
            return true
        } catch {
            print("❌ Failed to delete GIF for exercise \(exerciseName): \(error)")
            return false
        }
    }
    
    /// Get all stored GIFs
    func getAllStoredGifs() -> [String: URL] {
        var gifs: [String: URL] = [:]
        
        do {
            let files = try fileManager.contentsOfDirectory(at: gifDirectory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension.lowercased() == "gif" {
                let exerciseName = file.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ").capitalized
                gifs[exerciseName] = file
            }
        } catch {
            print("⚠️ Failed to read GIF directory: \(error)")
        }
        
        return gifs
    }
    
    /// Get total storage used by GIFs
    func getStorageUsage() -> Int64 {
        var totalSize: Int64 = 0
        
        do {
            let files = try fileManager.contentsOfDirectory(at: gifDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                if let resources = try? file.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resources.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        } catch {
            print("⚠️ Failed to calculate GIF storage: \(error)")
        }
        
        return totalSize
    }
    
    /// Clear all GIFs
    func clearAllGifs() -> Bool {
        do {
            try fileManager.removeItem(at: gifDirectory)
            setupGifDirectory()
            cache.removeAllObjects()
            print("✅ Cleared all exercise GIFs")
            return true
        } catch {
            print("❌ Failed to clear GIFs: \(error)")
            return false
        }
    }
    
    /// Preload GIFs for a list of exercises
    func preloadGifs(for exerciseNames: [String], completion: @escaping (Int) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var loaded = 0
            for exerciseName in exerciseNames {
                if let _ = self.getGifData(for: exerciseName) {
                    loaded += 1
                }
            }
            DispatchQueue.main.async {
                completion(loaded)
            }
        }
    }
}

// MARK: - SwiftUI Helper View

struct ExerciseDemoView: View {
    let exercise: Exercise
    let gifService = ExerciseGifService.shared
    let visualService = RecommendationVisualService.shared
    
    @State private var gifData: Data?
    @State private var hasLoadedGif = false
    
    var body: some View {
        VStack(spacing: 12) {
            // GIF Animation or Fallback
            if let gifData = gifData {
                VStack {
                    GifImageView(gifData: gifData)
                        .frame(height: 250)
                        .cornerRadius(12)
                    
                    HStack {
                        Image(systemName: "film.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Tap to play")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Fallback: Show icon with form tips
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                    
                    VStack(spacing: 16) {
                        Image(systemName: visualService.getExerciseIcon(for: exercise.name))
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Form Tips")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            if let instructions = exercise.instructions {
                                Text(instructions)
                                    .font(.caption)
                                    .lineLimit(3)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
                .frame(height: 250)
            }
            
            // Exercise info
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Label("\(exercise.duration) min", systemImage: "clock.fill")
                        .font(.caption)
                    Label("\(exercise.calories) kcal", systemImage: "flame.fill")
                        .font(.caption)
                    
                    if let difficulty = exercise.difficulty {
                        Text(difficulty.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadGif()
        }
    }
    
    private func loadGif() {
        guard !hasLoadedGif else { return }
        hasLoadedGif = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let data = gifService.getGifData(for: exercise.name)
            DispatchQueue.main.async {
                withAnimation {
                    self.gifData = data
                }
            }
        }
    }
}
