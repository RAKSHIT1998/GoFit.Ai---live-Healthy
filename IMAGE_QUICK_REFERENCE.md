# 📸 Image Management Quick Reference

## Quick Start - Save & Load Images

### Save Workout Exercise Form
```swift
if let image = selectedImage,
   let data = image.jpegData(compressionQuality: 0.8) {
    let filename = WorkoutImageManager.shared.saveExerciseFormImage(data, exerciseName: "Bench Press")
}
```

### Load Workout Exercise Form
```swift
let images = WorkoutImageManager.shared.getExerciseFormImages(exerciseName: "Bench Press")
Image(uiImage: images.first!)
```

### Save Workout Photo
```swift
if let image = capturedImage,
   let data = image.jpegData(compressionQuality: 0.75) {
    let filename = WorkoutImageManager.shared.saveWorkoutPhoto(data, workoutId: id, exerciseName: "Bench Press")
}
```

### Get Workout Photos
```swift
let photos = WorkoutImageManager.shared.getWorkoutPhotos(workoutId: workoutId)
```

---

### Save Meal Photo
```swift
if let image = selectedImage,
   let data = image.jpegData(compressionQuality: 0.75) {
    let filename = MealImageManager.shared.saveMealPhoto(data, mealId: meal.id, mealName: meal.name)
}
```

### Load Meal Photos
```swift
let photos = MealImageManager.shared.getMealPhotos(mealId: mealId)
// or get just the latest
if let thumb = MealImageManager.shared.getLatestMealThumbnail(mealId: mealId) {
    Image(uiImage: thumb)
}
```

### Save Food Item Image
```swift
if let data = image.jpegData(compressionQuality: 0.8) {
    MealImageManager.shared.saveFoodItemImage(data, foodName: "Chicken")
}
```

### Save Nutrition Label
```swift
if let data = labelImage.jpegData(compressionQuality: 0.85) {
    MealImageManager.shared.saveNutritionLabel(data, mealId: mealId)
}
```

---

## Common Operations

### Get Storage Info
```swift
// Workout images
let size = WorkoutImageManager.shared.getWorkoutImageStorageSize()
let (forms, photos, icons) = WorkoutImageManager.shared.getImageStats()

// Meal images
let size = MealImageManager.shared.getMealImageStorageSize()
let sizeStr = MealImageManager.shared.getMealImageStorageSizeString()
let (meals, foods, labels, total) = MealImageManager.shared.getImageStats()
```

### Delete Images
```swift
// Delete single photo
WorkoutImageManager.shared.deleteWorkoutPhoto(filename: "filename")
MealImageManager.shared.deleteMealPhoto(filename: "filename")

// Delete all for workout/meal
WorkoutImageManager.shared.deleteWorkoutPhotos(workoutId: id)
MealImageManager.shared.deleteMealPhotos(mealId: id)

// Delete nutrition label
MealImageManager.shared.deleteNutritionLabel(filename: "filename")
```

### Cleanup Old Images
```swift
WorkoutImageManager.shared.cleanupOldImages(olderThanDays: 30)
MealImageManager.shared.cleanupOldImages(olderThanDays: 60)
```

---

## UI Components

### Meal Image View
```swift
MealImageView(mealId: meal.id, mealName: meal.name)
```

### Meal Card with Image
```swift
MealCardWithImageView(meal: mealEntry)
```

### Meal Photo Browser
```swift
MealPhotoBrowserView()
```

---

## Image Quality Guide

```swift
// Meal photos - balance quality and size
image.jpegData(compressionQuality: 0.75)  // ~200KB

// Workout photos - good quality needed
image.jpegData(compressionQuality: 0.75)  // ~250KB

// Exercise forms - higher quality for reference
image.jpegData(compressionQuality: 0.8)   // ~300KB

// Icons/thumbnails - smaller
image.jpegData(compressionQuality: 0.7)   // ~50KB
```

---

## File Organization

```
Documents/
├── GoFitWorkoutImages/
│   ├── exercise_forms/      ← Exercise demonstrations
│   ├── workout_photos/      ← Photos during workouts
│   └── exercise_icons/      ← Custom exercise thumbnails
│
└── GoFitMealImages/
    ├── meal_photos/         ← Photos of meals eaten
    ├── food_items/          ← Reference food images
    └── nutrition_labels/    ← Nutrition label photos
```

---

## Complete Example - Log Meal with Photo

```swift
struct LogMealView: View {
    @State private var mealName = ""
    @State private var calories = 0
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    
    var body: some View {
        Form {
            TextField("Meal Name", text: $mealName)
            Stepper("Calories: \(calories)", value: $calories, in: 0...2000, step: 50)
            
            if let image = selectedImage {
                Image(uiImage: image).resizable().scaledToFit()
            }
            
            Button("Take Photo") { showPhotoPicker = true }
            Button("Save") { saveMeal() }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedImage)
    }
    
    func saveMeal() {
        let meal = MealEntry(name: mealName, calories: Double(calories), protein: 0, carbs: 0, fat: 0)
        UserDataCache.shared.addMealEntry(meal)
        
        if let image = selectedImage,
           let data = image.jpegData(compressionQuality: 0.75) {
            MealImageManager.shared.saveMealPhoto(data, mealId: meal.id, mealName: mealName)
        }
    }
}
```

---

## Storage Estimation

| Item | Size | Count | Total |
|------|------|-------|-------|
| Meal photo | 150-300 KB | 50 | 10 MB |
| Workout photo | 200-400 KB | 60 | 15 MB |
| Exercise form | 300-500 KB | 30 | 12 MB |
| Nutrition label | 200-400 KB | 20 | 5 MB |
| **Total** | - | 160 | **~42 MB** |

---

## Error Handling

```swift
// Save with error handling
if let data = image.jpegData(compressionQuality: 0.75) {
    let filename = MealImageManager.shared.saveMealPhoto(data, mealId: id, mealName: name)
    if !filename.isEmpty {
        AppLogger.shared.meal("Photo saved")
    } else {
        AppLogger.shared.logError("Failed to save meal photo")
    }
}
```

---

## Logging

All operations are automatically logged:
- Image saved: `AppLogger.shared.meal("Saved photo")`
- Image loaded: `AppLogger.shared.storage("Loaded photo")`
- Image deleted: `AppLogger.shared.storage("Deleted photo")`
- Cleanup: `AppLogger.shared.storage("Cleaned up old image")`
- Errors: `AppLogger.shared.logError(error)`

View logs: `AppLogger.shared.getLogsAsString()`

---

## Files Created

- `Services/WorkoutImageManager.swift` (400+ lines)
- `Services/MealImageManager.swift` (350+ lines)
- `Features/Meal/MealImageView.swift` (400+ lines)
- `IMAGE_MANAGEMENT_GUIDE.md` (complete guide)

---

**Ready to add images? Start with the examples above!** 📸
