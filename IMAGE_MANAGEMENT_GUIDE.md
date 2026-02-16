# 📸 Workout & Meal Images Implementation Guide

## Overview

Your GoFit app now has complete image management for both workouts and meals, stored directly on device for offline access and fast loading.

---

## 🏋️ WorkoutImageManager

### Features

✅ **Exercise Form Images** - Store demonstration photos of proper exercise form  
✅ **Workout Photos** - Save photos taken during workouts  
✅ **Exercise Icons** - Store custom exercise icons/thumbnails  
✅ **Auto Optimization** - Images automatically compressed and resized  
✅ **Thread Safe** - All operations are thread-safe  

### File Structure

```
Documents/
└── GoFitWorkoutImages/
    ├── exercise_forms/
    │   ├── bench_press_form_uuid.jpg
    │   ├── squat_form_uuid.jpg
    │   └── deadlift_form_uuid.jpg
    │
    ├── workout_photos/
    │   ├── workout_id_exercise_uuid.jpg
    │   └── workout_id_exercise_uuid.jpg
    │
    └── exercise_icons/
        ├── bench_press_icon.jpg
        └── squat_icon.jpg
```

### Usage Examples

#### Save Exercise Form Image
```swift
let workoutManager = WorkoutImageManager.shared

// When user adds an exercise form reference image
if let image = selectedImage,
   let imageData = image.jpegData(compressionQuality: 0.8) {
    let filename = workoutManager.saveExerciseFormImage(imageData, exerciseName: "Bench Press")
    // filename: "bench_press_uuid.jpg"
}
```

#### Load Exercise Form Images
```swift
// Get all form images for an exercise
let formImages = WorkoutImageManager.shared.getExerciseFormImages(exerciseName: "Bench Press")

// Display in carousel or grid
ForEach(formImages, id: \.hashValue) { image in
    Image(uiImage: image)
        .resizable()
        .scaledToFill()
}
```

#### Save Workout Photo
```swift
// When user takes a photo during workout
if let image = capturedImage,
   let imageData = image.jpegData(compressionQuality: 0.75) {
    let filename = workoutManager.saveWorkoutPhoto(
        imageData,
        workoutId: workout.id,
        exerciseName: "Bench Press"
    )
    
    // Update exercise record with image filename
    exercise.imageURL = filename
}
```

#### Get Workout Photos
```swift
// Get all photos from a specific workout
let photos = WorkoutImageManager.shared.getWorkoutPhotos(workoutId: workoutId)

// Display in photo grid
ScrollView(.horizontal) {
    HStack {
        ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .cornerRadius(8)
        }
    }
}
```

#### Save Exercise Icon
```swift
// Save a custom icon for an exercise
if let image = customIcon,
   let imageData = image.jpegData(compressionQuality: 0.8) {
    workoutManager.saveExerciseIcon(imageData, exerciseName: "Dumbbell Curl")
}

// Load exercise icon
if let icon = WorkoutImageManager.shared.loadExerciseIcon(exerciseName: "Dumbbell Curl") {
    Image(uiImage: icon)
        .resizable()
        .scaledToFill()
        .frame(width: 40, height: 40)
}
```

#### Storage Management
```swift
// Get storage info
let (forms, photos, icons) = workoutManager.getImageStats()
print("Form images: \(forms), Workout photos: \(photos), Icons: \(icons)")

// Get total storage size
let sizeInBytes = workoutManager.getWorkoutImageStorageSize()
let formatter = ByteCountFormatter()
print("Storage used: \(formatter.string(fromByteCount: Int64(sizeInBytes)))")

// Clean up old images (older than 30 days)
workoutManager.cleanupOldImages(olderThanDays: 30)

// Delete specific workout's photos
workoutManager.deleteWorkoutPhotos(workoutId: workoutId)
```

---

## 🍽️ MealImageManager

### Features

✅ **Meal Photos** - Store photos of meals eaten  
✅ **Food Item Images** - Save reference images of food items  
✅ **Nutrition Labels** - Capture and store nutrition label photos  
✅ **Thumbnail Generation** - Auto-create thumbnails  
✅ **Export Capability** - Export meal photos for sharing  

### File Structure

```
Documents/
└── GoFitMealImages/
    ├── meal_photos/
    │   ├── meal_id_chicken_uuid.jpg
    │   └── meal_id_salad_uuid.jpg
    │
    ├── food_items/
    │   ├── chicken_uuid.jpg
    │   └── broccoli_uuid.jpg
    │
    └── nutrition_labels/
        └── meal_id_nutrition_label_uuid.jpg
```

### Usage Examples

#### Save Meal Photo
```swift
let mealManager = MealImageManager.shared

// When user logs a meal with photo
if let image = capturedMealImage,
   let imageData = image.jpegData(compressionQuality: 0.75) {
    let filename = mealManager.saveMealPhoto(
        imageData,
        mealId: meal.id,
        mealName: "Chicken Salad"
    )
    
    // Save filename to meal entry
    meal.imageURL = filename
}
```

#### Load Meal Photos
```swift
// Get all photos for a meal
let mealPhotos = MealImageManager.shared.getMealPhotos(mealId: mealId)

// Get latest meal photo as thumbnail
if let thumbnail = MealImageManager.shared.getLatestMealThumbnail(mealId: mealId) {
    Image(uiImage: thumbnail)
        .resizable()
        .scaledToFill()
        .frame(height: 200)
        .cornerRadius(8)
}
```

#### Save Food Item Image
```swift
// Store reference image for a food item
if let foodImage = selectedFoodImage,
   let imageData = foodImage.jpegData(compressionQuality: 0.8) {
    let filename = mealManager.saveFoodItemImage(imageData, foodName: "Chicken Breast")
    // Auto-resized to 200x200 for thumbnails
}

// Load food item images
let chickenImages = mealManager.getFoodItemImages(foodName: "Chicken Breast")
```

#### Save Nutrition Label
```swift
// User takes photo of nutrition label
if let labelImage = capturedLabel,
   let imageData = labelImage.jpegData(compressionQuality: 0.85) {
    let filename = mealManager.saveNutritionLabel(imageData, mealId: mealId)
}

// Load nutrition label
if let label = MealImageManager.shared.getNutritionLabel(mealId: mealId) {
    Image(uiImage: label)
        .resizable()
        .scaledToFit()
}
```

#### Storage Management
```swift
// Get meal image statistics
let (photos, foodItems, labels, totalSize) = mealManager.getImageStats()
print("Meals: \(photos), Foods: \(foodItems), Labels: \(labels)")
print("Total size: \(totalSize)")

// Get formatted size string
let sizeString = mealManager.getMealImageStorageSizeString()
print("Using: \(sizeString)")

// Clean up old images (older than 60 days)
mealManager.cleanupOldImages(olderThanDays: 60)

// Delete meal photos
mealManager.deleteMealPhotos(mealId: mealId)

// Delete nutrition label
mealManager.deleteNutritionLabel(filename: labelFilename)
```

#### Export Meals
```swift
// Export all photos for a meal
let photoDataList = mealManager.exportMealPhotos(mealId: mealId)

// Share with ShareSheet
let vc = UIActivityViewController(activityItems: photoDataList, applicationActivities: nil)
present(vc, animated: true)
```

---

## 🎨 UI Components

### MealImageView
Complete meal photo management UI component

```swift
struct MealImageView: View {
    let mealId: String
    let mealName: String
    // Automatically loads and displays meal photos
    // Allows adding new photos
    // Allows deleting photos
}

// Usage
MealImageView(mealId: meal.id, mealName: meal.name)
```

### MealCardWithImageView
Beautiful meal card with photo display

```swift
struct MealCardWithImageView: View {
    let meal: MealEntry
    // Shows meal photo if available
    // Displays nutrition info
    // Shows meal type and time
}

// Usage
MealCardWithImageView(meal: mealEntry)
```

### MealPhotoBrowserView
Browse all meal photos in a grid

```swift
struct MealPhotoBrowserView: View {
    // Displays all meal photos in a grid
    // Tap to view full size
    // Share functionality
}

// Usage
NavigationLink(destination: MealPhotoBrowserView()) {
    Text("View All Meal Photos")
}
```

---

## 📊 Integration Examples

### Complete Meal Logging with Photo

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
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            
            Button("Take Photo") {
                showPhotoPicker = true
            }
            
            Button("Save Meal") {
                saveMealWithPhoto()
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedImage)
    }
    
    func saveMealWithPhoto() {
        let meal = MealEntry(
            name: mealName,
            calories: Double(calories),
            protein: 0,
            carbs: 0,
            fat: 0
        )
        
        // Save meal to cache
        UserDataCache.shared.addMealEntry(meal)
        
        // Save photo if selected
        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.75) {
            let filename = MealImageManager.shared.saveMealPhoto(
                imageData,
                mealId: meal.id,
                mealName: mealName
            )
            AppLogger.shared.meal("Logged: \(mealName) with photo")
        } else {
            AppLogger.shared.meal("Logged: \(mealName)")
        }
    }
}
```

### Complete Workout with Exercise Form Reference

```swift
struct ExerciseDetailWithFormGuide: View {
    let exercise: ExerciseRecord
    @State private var formImages: [UIImage] = []
    @State private var selectedFormImage: UIImage?
    
    var body: some View {
        VStack(spacing: 16) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            // Form Reference Images
            if !formImages.isEmpty {
                Text("Form Guide")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                TabView(selection: Binding(
                    get: { selectedFormImage },
                    set: { selectedFormImage = $0 }
                )) {
                    ForEach(formImages, id: \.hashValue) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .tag(image)
                    }
                }
                .frame(height: 300)
                .tabViewStyle(.page)
            }
            
            // Exercise Details
            HStack(spacing: 20) {
                VStack {
                    Text("Sets")
                        .font(.caption)
                    Text("\(exercise.sets)")
                        .font(.headline)
                }
                
                VStack {
                    Text("Reps")
                        .font(.caption)
                    Text(exercise.reps.map(String.init).joined(separator: "×"))
                        .font(.headline)
                }
                
                if let weight = exercise.weight {
                    VStack {
                        Text("Weight")
                            .font(.caption)
                        Text("\(Int(weight))kg")
                            .font(.headline)
                    }
                }
            }
        }
        .onAppear {
            loadFormGuides()
        }
    }
    
    func loadFormGuides() {
        formImages = WorkoutImageManager.shared.getExerciseFormImages(
            exerciseName: exercise.exerciseName
        )
    }
}
```

---

## 🔧 Configuration

### Image Quality Settings
```swift
// Meal photos
let mealData = image.jpegData(compressionQuality: 0.75)  // Good quality, smaller size

// Workout photos
let workoutData = image.jpegData(compressionQuality: 0.75)

// Exercise forms (higher quality for reference)
let formData = image.jpegData(compressionQuality: 0.8)

// Icons (smaller, compressed)
let iconData = image.jpegData(compressionQuality: 0.7)
```

### Cleanup Schedules
```swift
// In AppDelegate or app startup
WorkoutImageManager.shared.cleanupOldImages(olderThanDays: 30)  // Remove old workout photos
MealImageManager.shared.cleanupOldImages(olderThanDays: 60)      // Remove old meal photos
```

---

## 📊 Storage Usage

Typical storage for images:
- **Meal photo**: 150-300 KB (compressed)
- **Workout photo**: 200-400 KB
- **Exercise form**: 300-500 KB
- **Exercise icon**: 20-50 KB
- **Nutrition label**: 200-400 KB

Example storage calculation:
- 50 meals with photos: ~10 MB
- 20 workouts with 3 photos each: ~15 MB
- 30 exercise forms: ~12 MB
- **Total: ~37 MB** (easily manageable)

---

## 🎯 Best Practices

1. **Always use compression** - JPEG quality 0.7-0.8 is usually sufficient
2. **Auto cleanup** - Set up scheduled cleanup of old images
3. **Check storage** - Monitor storage usage in settings
4. **Load async** - Always load images on background thread
5. **Update UI on main** - Switch back to main thread before updating UI
6. **Add logging** - Log when saving/loading images for debugging

---

## 🧪 Testing

### Test Image Saving
```swift
let testImage = UIImage(systemName: "photo.on.rectangle")!
let data = testImage.pngData()!
WorkoutImageManager.shared.saveExerciseFormImage(data, exerciseName: "Test Exercise")
```

### Test Image Loading
```swift
let images = WorkoutImageManager.shared.getExerciseFormImages(exerciseName: "Test Exercise")
print("Found \(images.count) images")
```

### Test Storage Management
```swift
let stats = WorkoutImageManager.shared.getImageStats()
print("Stats: \(stats)")

let size = WorkoutImageManager.shared.getWorkoutImageStorageSize()
print("Size in bytes: \(size)")
```

---

## 📝 Logging

All image operations are automatically logged:

```
✅ "Saved meal photo: Chicken Salad"
✅ "Loaded meal photo: meal_001"
🗑️ "Deleted meal photo: filename"
🧹 "Cleaned up old image: filename"
⚠️ "Exercise form image not found: filename"
❌ "Failed to save meal photo: error description"
```

Check logs in `AppLogger.shared.getLogsAsString()`

---

## 🎁 What You Have

✅ **2 Image Managers** - Workout and Meal image management  
✅ **4 UI Components** - For displaying and managing images  
✅ **Complete Storage** - Organized on device filesystem  
✅ **Auto Optimization** - Images compressed and resized  
✅ **Thread Safe** - All operations safe for concurrent access  
✅ **Full Logging** - Track all image operations  
✅ **Export Ready** - Share meal photos easily  
✅ **Cleanup Tools** - Manage storage automatically  

---

**Your app now has complete image support for workouts and meals!** 📸🏋️🍽️
