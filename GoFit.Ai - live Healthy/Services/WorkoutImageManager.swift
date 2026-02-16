import Foundation
import UIKit
import Combine

/// Service for managing workout exercise images and form reference photos
/// Stores exercise demonstrations, form guides, and user workout photos
final class WorkoutImageManager: ObservableObject {
    static let shared = WorkoutImageManager()
    
    private init() {
        setupImageDirectories()
    }
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let imageLock = DispatchQueue(label: "workout.image.manager.queue")
    
    private var workoutImagesURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("GoFitWorkoutImages", isDirectory: true)
    }
    
    private var exerciseFormURL: URL {
        workoutImagesURL.appendingPathComponent("exercise_forms", isDirectory: true)
    }
    
    private var workoutPhotosURL: URL {
        workoutImagesURL.appendingPathComponent("workout_photos", isDirectory: true)
    }
    
    private var exerciseIconsURL: URL {
        workoutImagesURL.appendingPathComponent("exercise_icons", isDirectory: true)
    }
    
    // MARK: - Setup
    private func setupImageDirectories() {
        imageLock.async {
            try? self.fileManager.createDirectory(at: self.exerciseFormURL, withIntermediateDirectories: true)
            try? self.fileManager.createDirectory(at: self.workoutPhotosURL, withIntermediateDirectories: true)
            try? self.fileManager.createDirectory(at: self.exerciseIconsURL, withIntermediateDirectories: true)
            AppLogger.shared.storage("Workout image directories initialized")
        }
    }
    
    // MARK: - Exercise Form Images
    /// Save exercise form reference image (e.g., how to do bench press)
    func saveExerciseFormImage(_ imageData: Data, exerciseName: String) -> String {
        let id = UUID().uuidString
        return imageLock.sync {
            let filename = "\(exerciseName.lowercased().replacingOccurrences(of: " ", with: "_"))_\(id).jpg"
            let path = exerciseFormURL.appendingPathComponent(filename)
            
            do {
                try imageData.write(to: path, options: [.atomic])
                AppLogger.shared.storage("Saved exercise form image: \(exerciseName)")
                return filename
            } catch {
                AppLogger.shared.logError(error, context: "Failed to save exercise form image: \(exerciseName)")
                return ""
            }
        }
    }
    
    /// Load exercise form image by filename
    func loadExerciseFormImage(filename: String) -> UIImage? {
        return imageLock.sync {
            let path = exerciseFormURL.appendingPathComponent(filename)
            guard let imageData = try? Data(contentsOf: path) else {
                AppLogger.shared.logWarning("Exercise form image not found: \(filename)", category: "ImageLoad")
                return nil
            }
            
            let image = UIImage(data: imageData)
            if image != nil {
                AppLogger.shared.storage("Loaded exercise form image: \(filename)")
            }
            return image
        }
    }
    
    /// Get all exercise form images for an exercise
    func getExerciseFormImages(exerciseName: String) -> [UIImage] {
        return imageLock.sync {
            do {
                let files = try fileManager.contentsOfDirectory(at: exerciseFormURL, includingPropertiesForKeys: nil)
                let exerciseFiles = files.filter { $0.lastPathComponent.lowercased().contains(exerciseName.lowercased()) }
                
                var images: [UIImage] = []
                for file in exerciseFiles {
                    if let imageData = try? Data(contentsOf: file),
                       let image = UIImage(data: imageData) {
                        images.append(image)
                    }
                }
                
                AppLogger.shared.storage("Found \(images.count) form images for \(exerciseName)")
                return images
            } catch {
                AppLogger.shared.logError(error, context: "Failed to load exercise form images")
                return []
            }
        }
    }
    
    // MARK: - Workout Photos
    /// Save photo taken during a workout
    func saveWorkoutPhoto(_ imageData: Data, workoutId: String, exerciseName: String) -> String {
        let photoId = UUID().uuidString
        return imageLock.sync {
            let filename = "\(workoutId)_\(exerciseName.lowercased().replacingOccurrences(of: " ", with: "_"))_\(photoId).jpg"
            let path = workoutPhotosURL.appendingPathComponent(filename)
            
            do {
                try imageData.write(to: path, options: [.atomic])
                AppLogger.shared.workout("Saved workout photo: \(exerciseName)")
                return filename
            } catch {
                AppLogger.shared.logError(error, context: "Failed to save workout photo")
                return ""
            }
        }
    }
    
    /// Load workout photo
    func loadWorkoutPhoto(filename: String) -> UIImage? {
        return imageLock.sync {
            let path = workoutPhotosURL.appendingPathComponent(filename)
            guard let imageData = try? Data(contentsOf: path) else {
                return nil
            }
            
            let image = UIImage(data: imageData)
            if image != nil {
                AppLogger.shared.storage("Loaded workout photo: \(filename)")
            }
            return image
        }
    }
    
    /// Get all photos for a workout
    func getWorkoutPhotos(workoutId: String) -> [UIImage] {
        return imageLock.sync {
            do {
                let files = try fileManager.contentsOfDirectory(at: workoutPhotosURL, includingPropertiesForKeys: nil)
                let workoutFiles = files.filter { $0.lastPathComponent.contains(workoutId) }
                
                var images: [UIImage] = []
                for file in workoutFiles {
                    if let imageData = try? Data(contentsOf: file),
                       let image = UIImage(data: imageData) {
                        images.append(image)
                    }
                }
                
                return images
            } catch {
                AppLogger.shared.logError(error, context: "Failed to load workout photos")
                return []
            }
        }
    }
    
    // MARK: - Exercise Icons
    /// Save custom exercise icon/thumbnail
    func saveExerciseIcon(_ imageData: Data, exerciseName: String) -> String {
        return imageLock.sync {
            let filename = "\(exerciseName.lowercased().replacingOccurrences(of: " ", with: "_"))_icon.jpg"
            let path = exerciseIconsURL.appendingPathComponent(filename)
            
            do {
                // Compress icon to thumbnail size (~100x100)
                if let image = UIImage(data: imageData),
                   let compressedData = image.jpegData(compressionQuality: 0.7) {
                    try compressedData.write(to: path, options: [.atomic])
                    AppLogger.shared.storage("Saved exercise icon: \(exerciseName)")
                    return filename
                }
                return ""
            } catch {
                AppLogger.shared.logError(error, context: "Failed to save exercise icon")
                return ""
            }
        }
    }
    
    /// Load exercise icon
    func loadExerciseIcon(exerciseName: String) -> UIImage? {
        return imageLock.sync {
            let filename = "\(exerciseName.lowercased().replacingOccurrences(of: " ", with: "_"))_icon.jpg"
            let path = exerciseIconsURL.appendingPathComponent(filename)
            
            guard let imageData = try? Data(contentsOf: path) else {
                return nil
            }
            
            return UIImage(data: imageData)
        }
    }
    
    // MARK: - Image Management
    /// Delete a workout photo
    func deleteWorkoutPhoto(filename: String) -> Bool {
        return imageLock.sync {
            let path = workoutPhotosURL.appendingPathComponent(filename)
            do {
                try fileManager.removeItem(at: path)
                AppLogger.shared.storage("Deleted workout photo: \(filename)")
                return true
            } catch {
                AppLogger.shared.logError(error, context: "Failed to delete workout photo")
                return false
            }
        }
    }
    
    /// Delete all photos for a workout
    func deleteWorkoutPhotos(workoutId: String) -> Bool {
        return imageLock.sync {
            do {
                let files = try fileManager.contentsOfDirectory(at: workoutPhotosURL, includingPropertiesForKeys: nil)
                let workoutFiles = files.filter { $0.lastPathComponent.contains(workoutId) }
                
                for file in workoutFiles {
                    try fileManager.removeItem(at: file)
                }
                
                AppLogger.shared.storage("Deleted all photos for workout: \(workoutId)")
                return true
            } catch {
                AppLogger.shared.logError(error, context: "Failed to delete workout photos")
                return false
            }
        }
    }
    
    /// Get storage size used by workout images
    func getWorkoutImageStorageSize() -> UInt64 {
        return imageLock.sync {
            do {
                let formFiles = try fileManager.contentsOfDirectory(at: exerciseFormURL, includingPropertiesForKeys: [.fileSizeKey])
                let photoFiles = try fileManager.contentsOfDirectory(at: workoutPhotosURL, includingPropertiesForKeys: [.fileSizeKey])
                let iconFiles = try fileManager.contentsOfDirectory(at: exerciseIconsURL, includingPropertiesForKeys: [.fileSizeKey])
                
                var totalSize: UInt64 = 0
                
                for file in formFiles + photoFiles + iconFiles {
                    if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                       let fileSize = attributes[.size] as? NSNumber {
                        totalSize += fileSize.unsignedLongLongValue
                    }
                }
                
                return totalSize
            } catch {
                return 0
            }
        }
    }
    
    /// Clean up old images (older than specified days)
    func cleanupOldImages(olderThanDays: Int = 30) {
        imageLock.async {
            let cutoffDate = Date().addingTimeInterval(-TimeInterval(olderThanDays * 24 * 60 * 60))
            
            for directory in [self.workoutPhotosURL, self.exerciseFormURL] {
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
                            AppLogger.shared.storage("Cleaned up old image: \(file.lastPathComponent)")
                        }
                    }
                } catch {
                    AppLogger.shared.logError(error, context: "Failed to cleanup old images")
                }
            }
        }
    }
    
    /// Get total count of images
    func getImageStats() -> (formImages: Int, workoutPhotos: Int, icons: Int) {
        return imageLock.sync {
            let formCount = (try? fileManager.contentsOfDirectory(at: exerciseFormURL).count) ?? 0
            let photoCount = (try? fileManager.contentsOfDirectory(at: workoutPhotosURL).count) ?? 0
            let iconCount = (try? fileManager.contentsOfDirectory(at: exerciseIconsURL).count) ?? 0
            
            return (formCount, photoCount, iconCount)
        }
    }
}

// MARK: - Image Conversion Helpers
extension UIImage {
    /// Resize image to specified dimensions
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Compress image data with quality setting
    func compressedData(quality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
}

// MARK: - Data Model
struct WorkoutImageMetadata: Codable {
    var imageFilename: String
    var exerciseName: String
    var imageType: ImageType // form, photo, icon
    var uploadDate: Date
    var workoutId: String?
    
    enum ImageType: String, Codable {
        case form = "exercise_form"
        case photo = "workout_photo"
        case icon = "exercise_icon"
    }
}
