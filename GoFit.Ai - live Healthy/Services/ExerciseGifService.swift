import SwiftUI
import AVKit
import ImageIO

/// View to display animated GIFs for exercises
struct GifImageView: View {
    let gifData: Data?
    let loopCount: Int = 0 // 0 means infinite loop
    @State private var animatedImage: UIImage?
    @State private var staticImage: UIImage?
    @State private var isLoading = false
    @State private var error: String?
    @State private var isPlaying = true
    
    var body: some View {
        ZStack {
            if let image = isPlaying ? animatedImage : staticImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
                    .overlay(
                        Group {
                            if !isPlaying {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPlaying.toggle()
                        }
                    }
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
            } else if error != nil {
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
                let (animated, staticFrame) = try self.createAnimatedImage(from: gifData)
                DispatchQueue.main.async {
                    withAnimation {
                        self.animatedImage = animated
                        self.staticImage = staticFrame
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
    
    private func createAnimatedImage(from data: Data) throws -> (UIImage, UIImage) {
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
        
        // Create animated image and static (first frame) image
        let animated = UIImage.animatedImage(with: images, duration: max(duration, 1.0)) ?? images[0]
        let staticFrame = images[0]
        return (animated, staticFrame)
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
    let giphyService = GiphyGifService.shared
    let visualService = RecommendationVisualService.shared
    
    @State private var gifData: Data?
    @State private var isLoadingGif = false
    @State private var loadingError: String?
    
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
                        Text("Tap to pause/play")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if isLoadingGif {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading animation...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
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
                                    .foregroundColor(.primary)
                                    .lineLimit(3)
                            } else {
                                Text("Follow proper form for maximum effectiveness")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
                .frame(height: 250)
            }
            
            // Exercise Details
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(exercise.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let difficulty = exercise.difficulty {
                        Text(difficulty.capitalized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                // Stats
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(exercise.duration) min")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(exercise.calories)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    if let sets = exercise.sets {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(sets)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadGif()
        }
    }
    
    private func loadGif() {
        isLoadingGif = true
        loadingError = nil
        
        // Try to fetch from Giphy first
        giphyService.fetchGifData(for: exercise.name) { [weak self] result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    self?.gifData = data
                    self?.isLoadingGif = false
                    print("✅ Loaded GIF from Giphy for: \(self?.exercise.name ?? "exercise")")
                }
            case .failure(let error):
                // Fall back to local GIFs
                print("⚠️ Giphy error: \(error.localizedDescription), trying local GIFs...")
                DispatchQueue.main.async {
                    if let localGifData = self?.gifService.getGifData(for: self?.exercise.name ?? "") {
                        self?.gifData = localGifData
                        print("✅ Loaded GIF from local storage for: \(self?.exercise.name ?? "exercise")")
                    } else {
                        self?.loadingError = error.localizedDescription
                        print("❌ No GIF available from Giphy or local storage")
                    }
                    self?.isLoadingGif = false
                }
            }
        }
    }
}
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

// MARK: - Meal Demo View with GIF Support
struct MealDemoView: View {
    let meal: RecommendationMealItem
    let gifService = ExerciseGifService.shared
    let giphyService = GiphyGifService.shared
    let visualService = RecommendationVisualService.shared
    
    @State private var gifData: Data?
    @State private var isLoadingGif = false
    @State private var loadingError: String?
    @State private var hasLoadedGif = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // GIF Display with Play/Pause
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                    
                    if isLoadingGif {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading meal preparation...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let gifData = gifData {
                        // Show actual GIF
                        GifImageView(gifData: gifData)
                            .frame(height: 300)
                    } else if let error = loadingError {
                        // Fallback: Show meal emoji with tips
                        VStack(spacing: 16) {
                            Text(visualService.getMealEmoji(for: meal.name))
                                .font(.system(size: 60))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cooking Tips")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                if let instructions = meal.instructions {
                                    Text(instructions)
                                        .font(.caption)
                                        .lineLimit(3)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                    } else {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No recipe video available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(height: 300)
                    }
                }
                .frame(height: 300)
                .cornerRadius(12)
                
                // Meal Info Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(visualService.getMealColor(for: meal.name)).opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Text(visualService.getMealEmoji(for: meal.name))
                            .font(.system(size: 28))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            Label("\(Int(meal.calories)) kcal", systemImage: "flame.fill")
                                .font(.caption)
                            Label("\(Int(meal.protein))g P", systemImage: "bolt.fill")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Nutrition Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nutrition")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        NutritionBar(label: "Protein", value: meal.protein, max: 50, color: .orange)
                        NutritionBar(label: "Carbs", value: meal.carbs, max: 100, color: .yellow)
                        NutritionBar(label: "Fat", value: meal.fat, max: 50, color: .red)
                    }
                }
                
                // Prep Info
                if let prepTime = meal.prepTime, let servings = meal.servings {
                    HStack(spacing: 16) {
                        Label("\(prepTime) min prep", systemImage: "clock.fill")
                            .font(.caption)
                        Label("\(servings) serving\(servings > 1 ? "s" : "")", systemImage: "person.fill")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Ingredients Section
                if let ingredients = meal.ingredients, !ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(ingredients, id: \.self) { ingredient in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text(ingredient)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Instructions Section
                if let instructions = meal.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Make")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(instructions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMealGif()
        }
    }
    
    private func loadMealGif() {
        guard !hasLoadedGif else { return }
        hasLoadedGif = true
        isLoadingGif = true
        
        // Try Giphy first for meal/cooking videos
        giphyService.fetchGifData(for: meal.name) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.gifData = data
                    self.loadingError = nil
                    self.isLoadingGif = false
                case .failure(let error):
                    // Fallback to local GIFs (if available)
                    if let localGifData = self.gifService.getGifData(for: meal.name) {
                        self.gifData = localGifData
                        self.loadingError = nil
                    } else {
                        self.loadingError = error.localizedDescription
                        self.gifData = nil
                    }
                    self.isLoadingGif = false
                }
            }
        }
    }
}

// Helper component for nutrition visualization
struct NutritionBar: View {
    let label: String
    let value: Double
    let max: Double
    let color: Color
    
    var percentage: Double {
        min(value / max, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: CGFloat(percentage) * 80, height: 6)
            }
            .frame(width: 80)
            
            Text("\(Int(value))g")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}
