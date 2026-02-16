import Foundation
import UIKit
import Combine

/// Service for managing meal photos and food images
/// Stores user meal photos, nutrition labels, and food item images
final class MealImageManager: ObservableObject {
    static let shared = MealImageManager()
    
    private init() {
        setupImageDirectories()
    }
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let imageLock = DispatchQueue(label: "meal.image.manager.queue")
    
    private var mealImagesURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("GoFitMealImages", isDirectory: true)
    }
    
    private var mealPhotosURL: URL {
        mealImagesURL.appendingPathComponent("meal_photos", isDirectory: true)
    }
    
    private var foodItemsURL: URL {
        mealImagesURL.appendingPathComponent("food_items", isDirectory: true)
    }
    
    private var nutritionLabelsURL: URL {
        mealImagesURL.appendingPathComponent("nutrition_labels", isDirectory: true)
    }
    
    // MARK: - Setup
    private func setupImageDirectories() {
        imageLock.async {
            try? self.fileManager.createDirectory(at: self.mealPhotosURL, withIntermediateDirectories: true)
            try? self.fileManager.createDirectory(at: self.foodItemsURL, withIntermediateDirectories: true)
            try? self.fileManager.createDirectory(at: self.nutritionLabelsURL, withIntermediateDirectories: true)
            AppLogger.shared.storage("Meal image directories initialized")
        }
    }
    
    // MARK: - Meal Photos
    /// Save a photo of a meal (what user actually ate)
    func saveMealPhoto(_ imageData: Data, mealId: String, mealName: String) -> String {
        let photoId = UUID().uuidString
        return imageLock.sync {
            let filename = "\(mealId)_\(mealName.lowercased().replacingOccurrences(of: " ", with: "_"))_\(photoId).jpg"
            let path = mealPhotosURL.appendingPathComponent(filename)
            
            do {
                // Optimize image size - compress to reasonable quality
                if let image = UIImage(data: imageData),
                   let optimizedData = image.compressedData(quality: 0.75) {
                    try optimizedData.write(to: path, options: [.atomic])
                    AppLogger.shared.meal("Saved meal photo: \(mealName)")
                    return filename
                }
                return ""
            } catch {
                AppLogger.shared.logError(error, context: "Failed to save meal photo: \(mealName)")
                return ""
            }
        }
    }
    
    /// Load meal photo by filename
    func loadMealPhoto(filename: String) -> UIImage? {
        return imageLock.sync {
            let path = mealPhotosURL.appendingPathComponent(filename)
            guard let imageData = try? Data(contentsOf: path) else {
                return nil
            }
            
            let image = UIImage(data: imageData)
            if image != nil {
                AppLogger.shared.storage("Loaded meal photo: \(filename)")
            }
            return image
        }
    }
    
    /// Get all photos for a specific meal
    func getMealPhotos(mealId: String) -> [UIImage] {
        return imageLock.sync {
            do {
                let files = try fileManager.contentsOfDirectory(at: mealPhotosURL, includingPropertiesForKeys: nil)
                let mealFiles = files.filter { $0.lastPathComponent.contains(mealId) }
                
                var images: [UIImage] = []
                for file in mealFiles {
                    if let imageData = try? Data(contentsOf: file),
                       let image = UIImage(data: imageData) {
                        images.append(image)
                    }
                }
                
                return images
            } catch {
                AppLogger.shared.logError(error, context: "Failed to load meal photos")
                return []
            }
        }
    }
    
    /// Get thumbnail of latest meal photo
    func getLatestMealThumbnail(mealId: String) -> UIImage? {
        return getMealPhotos(mealId: mealId).first
    }
    
    // MARK: - Food Item Images
    /// Save image of a food item (ingredient, food type reference)
    func saveFoodItemImage(_ imageData: Data, foodName: String) -> String {
        let itemId = UUID().uuidString
        return imageLock.sync {
            let filename = "\(foodName.lowercased().replacingOccurrences(of: " ", with: "_"))_\(itemId).jpg"
            let path = foodItemsURL.appendingPathComponent(filename)
            
            do {
                if let image = UIImage(data: imageData),
                   let resized = image.resized(to: CGSize(width: 200, height: 200)),
                   let optimizedData = resized.compressedData(quality: 0.8) {
                    try optimizedData.write(to: path, options: [.atomic])
                    AppLogger.shared.storage("Saved food item image: \(foodName)")
                    return filename
                }
                return ""
            } catch {
                AppLogger.shared.logError(error, context: "Failed to save food item image")
                return ""
            }
        }
    }
    
    /// Load food item image
    func loadFoodItemImage(filename: String) -> UIImage? {
        return imageLock.sync {
            let path = foodItemsURL.appendingPathComponent(filename)
            guard let imageData = try? Data(contentsOf: path) else {
                return nil
            }
            return UIImage(data: imageData)
        }
    }
    
    /// Get all images for a food item
    func getFoodItemImages(foodName: String) -> [UIImage] {
        return imageLock.sync {
            do {
                let files = try fileManager.contentsOfDirectory(at: foodItemsURL, includingPropertiesForKeys: nil)
                let foodFiles = files.filter { $0.lastPathComponent.lowercased().contains(foodName.lowercased()) }
                
                var images: [UIImage] = []
                for file in foodFiles {
                    if let imageData = try? Data(contentsOf: file),
                       let image = UIImage(data: imageData) {
                        images.append(image)
                    }
                }
                
                return images
            } catch {
                return []
            }
        }
    }
    
    // MARK: - Nutrition Labels
    /// Save photo of nutrition label (from food packaging)
    func saveNutritionLabel(_ imageData: Data, mealId: String) -> String {
        return imageLock.sync {
            let filename = "\(mealId)_nutrition_label_\(UUID().uuidString).jpg"
            let path = nutritionLabelsURL.appendingPathComponent(filename)
            
            do {
                if let image = UIImage(data: imageData),
                   let optimizedData = image.compressedData(quality: 0.85) {
                    try optimizedData.write(to: path, options: [.atomic])
                    AppLogger.shared.storage("Saved nutrition label")
                    return filename
                }
                return ""
            } catch {
                AppLogger.shared.logError(error, context: "Failed to save nutrition label")
                return ""
            }
        }
    }
    
    /// Load nutrition label image
    func loadNutritionLabel(filename: String) -> UIImage? {
        return imageLock.sync {
            let path = nutritionLabelsURL.appendingPathComponent(filename)
            guard let imageData = try? Data(contentsOf: path) else {
                return nil
            }
            return UIImage(data: imageData)
        }
    }
    
    /// Get nutrition label for a meal
    func getNutritionLabel(mealId: String) -> UIImage? {
        return imageLock.sync {
            do {
                let files = try fileManager.contentsOfDirectory(at: nutritionLabelsURL, includingPropertiesForKeys: nil)
                let labelFile = files.first { $0.lastPathComponent.contains(mealId) }
                
                if let labelFile = labelFile,
                   let imageData = try? Data(contentsOf: labelFile) {
                    return UIImage(data: imageData)
                }
                return nil
            } catch {
                return nil
            }
        }
    }
    
    // MARK: - Image Management
    /// Delete a meal photo
    func deleteMealPhoto(filename: String) -> Bool {
        return imageLock.sync {
            let path = mealPhotosURL.appendingPathComponent(filename)
            do {
                try fileManager.removeItem(at: path)
                AppLogger.shared.storage("Deleted meal photo: \(filename)")
                return true
            } catch {
                AppLogger.shared.logError(error, context: "Failed to delete meal photo")
                return false
            }
        }
    }
    
    /// Delete all photos for a meal
    func deleteMealPhotos(mealId: String) -> Bool {
        return imageLock.sync {
            do {
                let files = try fileManager.contentsOfDirectory(at: mealPhotosURL, includingPropertiesForKeys: nil)
                let mealFiles = files.filter { $0.lastPathComponent.contains(mealId) }
                
                for file in mealFiles {
                    try fileManager.removeItem(at: file)
                }
                
                AppLogger.shared.storage("Deleted all photos for meal: \(mealId)")
                return true
            } catch {
                AppLogger.shared.logError(error, context: "Failed to delete meal photos")
                return false
            }
        }
    }
    
    /// Delete nutrition label
    func deleteNutritionLabel(filename: String) -> Bool {
        return imageLock.sync {
            let path = nutritionLabelsURL.appendingPathComponent(filename)
            do {
                try fileManager.removeItem(at: path)
                return true
            } catch {
                return false
            }
        }
    }
    
    // MARK: - Storage Management
    /// Get storage size used by meal images
    func getMealImageStorageSize() -> UInt64 {
        return imageLock.sync {
            do {
                let photoFiles = try fileManager.contentsOfDirectory(at: mealPhotosURL, includingPropertiesForKeys: [.fileSizeKey])
                let foodFiles = try fileManager.contentsOfDirectory(at: foodItemsURL, includingPropertiesForKeys: [.fileSizeKey])
                let labelFiles = try fileManager.contentsOfDirectory(at: nutritionLabelsURL, includingPropertiesForKeys: [.fileSizeKey])
                
                var totalSize: UInt64 = 0
                
                for file in photoFiles + foodFiles + labelFiles {
                    if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                       let fileSize = attributes[.size] as? NSNumber {
                        totalSize += fileSize.uint64Value
                    }
                }
                
                return totalSize
            } catch {
                return 0
            }
        }
    }
    
    /// Get formatted storage size string
    func getMealImageStorageSizeString() -> String {
        let bytes = getMealImageStorageSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Clean up images older than specified days
    func cleanupOldImages(olderThanDays: Int = 60) {
        imageLock.async {
            let cutoffDate = Date().addingTimeInterval(-TimeInterval(olderThanDays * 24 * 60 * 60))
            
            for directory in [self.mealPhotosURL, self.foodItemsURL, self.nutritionLabelsURL] {
                do {
                    let files = try self.fileManager.contentsOfDirectory(
                        at: directory,
                        includingPropertiesForKeys: [.contentModificationDateKey]
                    )
                    
                    for file in files {
                        if let attributes = try? self.fileManager.attributesOfItem(atPath: file.path),
                           let modDate = attributes[.modificationDate] as? Date,
                           modDate < cutoffDate {
                            try? self.fileManager.removeItem(at: file)
                            AppLogger.shared.storage("Cleaned up old meal image: \(file.lastPathComponent)")
                        }
                    }
                } catch {
                    AppLogger.shared.logError(error, context: "Failed to cleanup old meal images")
                }
            }
        }
    }
    
    /// Get statistics on stored images
    func getImageStats() -> (mealPhotos: Int, foodItems: Int, labels: Int, totalSize: String) {
        return imageLock.sync {
            let photoCount = (try? fileManager.contentsOfDirectory(at: mealPhotosURL, includingPropertiesForKeys: nil).count) ?? 0
            let foodCount = (try? fileManager.contentsOfDirectory(at: foodItemsURL, includingPropertiesForKeys: nil).count) ?? 0
            let labelCount = (try? fileManager.contentsOfDirectory(at: nutritionLabelsURL, includingPropertiesForKeys: nil).count) ?? 0
            
            return (photoCount, foodCount, labelCount, getMealImageStorageSizeString())
        }
    }
    
    /// Export meal photos for sharing
    func exportMealPhotos(mealId: String) -> [Data] {
        return imageLock.sync {
            var photoDataList: [Data] = []
            
            do {
                let files = try fileManager.contentsOfDirectory(at: mealPhotosURL, includingPropertiesForKeys: nil)
                let mealFiles = files.filter { $0.lastPathComponent.contains(mealId) }
                
                for file in mealFiles {
                    if let data = try? Data(contentsOf: file) {
                        photoDataList.append(data)
                    }
                }
            } catch {
                AppLogger.shared.logError(error, context: "Failed to export meal photos")
            }
            
            return photoDataList
        }
    }
}

// MARK: - Data Model
struct MealImageMetadata: Codable {
    var imageFilename: String
    var mealId: String
    var mealName: String
    var imageType: ImageType // photo, food_item, label
    var captureDate: Date
    var thumbnailFilename: String?
    
    enum ImageType: String, Codable {
        case mealPhoto = "meal_photo"
        case foodItem = "food_item"
        case nutritionLabel = "nutrition_label"
    }
}

// MARK: - Image Helper Extensions
extension UIImage {
    /// Create thumbnail version of image
    func thumbnail(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage? {
        return resized(to: size)
    }
    
    /// Get image dimensions
    var dimensions: CGSize {
        return self.size
    }
}
