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
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw NSError(domain: "ImageIO", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image source"])
        }
        
        let frameCount = CGImageSourceGetCount(imageSource)
        guard frameCount > 0 else {
            throw NSError(domain: "ImageIO", code: -1, userInfo: [NSLocalizedDescriptionKey: "No frames in GIF"])
        }
        
        var images: [UIImage] = []
        var durations: [TimeInterval] = []
        
        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) {
                images.append(UIImage(cgImage: cgImage))
                
                if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as? [String: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let duration = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                    durations.append(max(duration.doubleValue, 0.05))
                } else {
                    durations.append(0.08)
                }
            }
        }
        
        let totalDuration = durations.reduce(0, +)
        let animatedImage = UIImage.animatedImage(with: images, duration: totalDuration)
        let staticImage = images.first ?? UIImage()
        
        return (animatedImage ?? UIImage(), staticImage)
    }
}

// MARK: - Exercise GIF Service
class ExerciseGifService: NSObject, ObservableObject {
    static let shared = ExerciseGifService()
    
    private let fileManager = FileManager.default
    private let cache = NSCache<NSString, NSData>()
    private var gifDirectory: URL
    
    override private init() {
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.gifDirectory = documentDirectory.appendingPathComponent("ExerciseGifs", isDirectory: true)
        
        super.init()
        
        // Create directory if needed
        try? fileManager.createDirectory(at: gifDirectory, withIntermediateDirectories: true)
        
        // Configure cache
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }
    
    // MARK: - Public Methods
    
    func getGifData(for exerciseName: String) -> Data? {
        let key = exerciseName.lowercased()
        
        // Check memory cache first
        if let cachedData = cache.object(forKey: key as NSString) {
            print("💾 GIF found in memory cache: \(exerciseName)")
            return cachedData as Data
        }
        
        // Check disk cache
        let filePath = gifDirectory.appendingPathComponent("\(key).gif")
        if let data = fileManager.contents(atPath: filePath.path) {
            // Put in memory cache for faster future access
            cache.setObject(data as NSData, forKey: key as NSString)
            print("💾 GIF loaded from disk cache: \(exerciseName)")
            return data
        }
        
        return nil
    }
    
    func saveGifData(_ data: Data, for exerciseName: String) -> Bool {
        let key = exerciseName.lowercased()
        let filePath = gifDirectory.appendingPathComponent("\(key).gif")
        
        do {
            try data.write(to: filePath)
            cache.setObject(data as NSData, forKey: key as NSString)
            print("✅ GIF saved for: \(exerciseName)")
            return true
        } catch {
            print("❌ Failed to save GIF: \(error)")
            return false
        }
    }
    
    func hasGif(for exerciseName: String) -> Bool {
        let key = exerciseName.lowercased()
        
        // Check memory cache
        if cache.object(forKey: key as NSString) != nil {
            return true
        }
        
        // Check disk cache
        let filePath = gifDirectory.appendingPathComponent("\(key).gif")
        return fileManager.fileExists(atPath: filePath.path)
    }
    
    func clearAllGifs() -> Bool {
        do {
            let gifFiles = try fileManager.contentsOfDirectory(at: gifDirectory, includingPropertiesForKeys: nil)
            for fileURL in gifFiles {
                try fileManager.removeItem(at: fileURL)
            }
            cache.removeAllObjects()
            print("✅ All cached GIFs cleared")
            return true
        } catch {
            print("❌ Failed to clear GIFs: \(error)")
            return false
        }
    }
    
    func getStorageUsage() -> Int64 {
        guard let enumerator = fileManager.enumerator(atPath: gifDirectory.path) else { return 0 }
        var totalSize: Int64 = 0
        
        for case let file as String in enumerator {
            let filePath = gifDirectory.appendingPathComponent(file)
            if let attributes = try? fileManager.attributesOfItem(atPath: filePath.path),
               let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
    
    func getStorageUsageMB() -> Double {
        let bytes = getStorageUsage()
        return Double(bytes) / (1024 * 1024)
    }
}

// MARK: - Exercise Demo View
struct ExerciseDemoView: View {
    let exercise: Exercise
    let gifService = ExerciseGifService.shared
    let giphyService = GiphyGifService.shared
    let visualService = RecommendationVisualService.shared
    
    @State private var gifData: Data?
    @State private var isLoadingGif = false
    @State private var loadingError: String?
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
        guard !hasLoadedGif else { return }
        hasLoadedGif = true
        
        isLoadingGif = true
        
        // Try Giphy first
        giphyService.fetchGifData(for: exercise.name) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.gifData = data
                    self.loadingError = nil
                    self.isLoadingGif = false
                case .failure(let error):
                    // Fallback to local GIFs
                    if let localGifData = self.gifService.getGifData(for: self.exercise.name) {
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
                    } else if let _ = loadingError {
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
