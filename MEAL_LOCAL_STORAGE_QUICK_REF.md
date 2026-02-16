# 🍽️ Meal Local Storage - Quick Reference

## ✅ What's Now Working

All meal logging methods now save to local device storage **IMMEDIATELY** before syncing to backend:

### 1. Manual Meal Entry
**File**: `Features/MealScanner/ManualMealLogView.swift`

- ✅ User enters meal manually
- ✅ Saved to `UserDataCache.shared` immediately
- ✅ Also added to `LocalDailyLogStore` for daily tracking
- ✅ Backend sync happens in background (non-blocking)

```swift
// User logs: Chicken (350cal) + Rice (200cal)
// ↓
// 1. Cache: UserDataCache.shared.addMealEntry(meal)
// 2. Daily Log: LocalDailyLogStore.shared.addMeal(loggedMeal)
// 3. UI: showSuccess = true (instant)
// 4. Backend: NetworkManager.shared.saveParsedMeal(...) in background
```

### 2. AI-Scanned Meal
**File**: `Features/MealScanner/MealScannerView3.swift`

- ✅ User scans meal photo with Gemini AI
- ✅ AI parses items and nutrition
- ✅ Saved to `LocalMealCache.shared` immediately
- ✅ Also added to `LocalDailyLogStore`
- ✅ Backend sync happens in background

```swift
// User scans meal photo
// ↓
// 1. Cache: LocalMealCache.shared.addMeal(cachedMeal)
// 2. Daily Log: LocalDailyLogStore.shared.addMeal(loggedMeal)
// 3. UI: NotificationCenter post "MealSaved"
// 4. Backend: NetworkManager.shared.saveParsedMeal(...) in background
```

---

## 📊 Access Meal History

### In Any View

```swift
// Current meal entries
let meals = UserDataCache.shared.mealEntries

// Today's meals
let todaysMeals = UserDataCache.shared.getTodaysMeals()

// Last 7 days
let weekHistory = UserDataCache.shared.getMealHistory(for: 7)

// Calculate nutrition
let (cals, protein, carbs, fat) = UserDataCache.shared.calculateTodaysNutrition()

// Daily stats
let todayStats = UserDataCache.shared.calculateTodaysStats()
```

### Display in SwiftUI

```swift
struct MealHistoryView: View {
    @ObservedObject var cache = UserDataCache.shared
    
    var body: some View {
        List(cache.mealEntries) { meal in
            MealRow(meal: meal)
        }
    }
}
```

---

## 🔄 Data Persistence Layers

| Layer | Purpose | Storage | Limit |
|-------|---------|---------|-------|
| **LocalMealCache** | Immediate offline storage | `local_meals_cache.json` | Unlimited (synced) |
| **LocalDailyLogStore** | Daily organization & stats | `local_daily_logs.json` | Full history |
| **UserDataCache** | Unified access layer | `cached_meals` | 500 meals |
| **DeviceStorageManager** | Low-level file I/O | App Documents folder | File system limit |

---

## 💡 Best Practices

### When Creating New Meal Logging View
```swift
private func saveMeal() async {
    // 1️⃣ Create MealEntry
    let meal = MealEntry(
        name: "...",
        calories: totalCals,
        // ... other fields
        date: Date(),
        mealType: "manual"
    )
    
    // 2️⃣ Save to cache IMMEDIATELY
    await MainActor.run {
        UserDataCache.shared.addMealEntry(meal)
    }
    
    // 3️⃣ Optional: Add to daily log
    let loggedMeal = LoggedMeal(...)
    await MainActor.run {
        LocalDailyLogStore.shared.addMeal(loggedMeal)
    }
    
    // 4️⃣ Update UI instantly
    await MainActor.run {
        showSuccess = true
    }
    
    // 5️⃣ Sync to backend in background
    Task.detached(priority: .utility) {
        do {
            // Backend sync here
        } catch {
            // Meal remains in cache
        }
    }
}
```

### When Displaying Meals
```swift
struct MyMealView: View {
    @ObservedObject var cache = UserDataCache.shared
    
    var body: some View {
        List(cache.mealEntries) { meal in
            // Direct binding to cache
            // Auto-updates when new meals added
        }
    }
}
```

### When Syncing Meals
```swift
// Automatically handles offline meals
let unsynced = LocalMealCache.shared.getUnsyncedMeals()

for meal in unsynced {
    do {
        _ = try await NetworkManager.shared.saveParsedMeal(...)
        LocalMealCache.shared.markSynced(mealId: meal.id)
    } catch {
        // Stays in cache, retry later
    }
}
```

---

## 🧪 Testing Meal Storage

### Check Cache Status
```swift
// In any view or app delegate
let meals = UserDataCache.shared.mealEntries
print("Cache has \(meals.count) meals")

// Check today's total
let today = UserDataCache.shared.getTodaysMeals()
print("Today: \(today.count) meals")

// Check storage
if let history = DeviceStorageManager.shared.loadMealHistory() {
    print("✅ Storage: \(history.count) meals on disk")
}
```

### Verify Local Files
```swift
// Print cache file location
let cachePath = "Documents/GoFitStorage/cached_meals"
print("Cache location: \(cachePath)")

// Check file size
let fileManager = FileManager.default
if let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
    let storageURL = docs.appendingPathComponent("GoFitStorage")
    // List contents
}
```

### Test Offline Scenario
```swift
// Disable network temporarily
// 1. Log meal in app
// 2. Meal appears immediately (from cache)
// 3. Turn on network
// 4. Meal syncs automatically
```

---

## 🐛 Troubleshooting

### Meals Not Appearing
**Cause**: View not subscribed to cache changes

**Fix**:
```swift
// ❌ Wrong
let meals = UserDataCache.shared.mealEntries
List(meals) { ... } // Static copy

// ✅ Correct
@ObservedObject var cache = UserDataCache.shared
List(cache.mealEntries) { ... } // Live binding
```

### Meals Disappearing
**Cause**: Likely exceeding 500-meal limit in UserDataCache

**Fix**:
```swift
// UserDataCache auto-prunes after 500
// Check full history in LocalDailyLogStore or backend
let fullHistory = LocalDailyLogStore.shared.getMeals(for: 365) // All year
```

### Backend Sync Failing
**Cause**: Network issue, but meals stay in cache

**Fix**:
```swift
// Meals remain in LocalMealCache with synced=false
let unsynced = LocalMealCache.shared.getUnsyncedMeals()
print("Waiting to sync: \(unsynced.count) meals")

// Will retry automatically when network returns
// Or manually trigger sync
Task {
    await syncOfflineMeals()
}
```

---

## 📝 Code Examples

### Add Meal from Any Source
```swift
let meal = MealEntry(
    name: "Breakfast",
    calories: 450,
    protein: 25,
    carbs: 50,
    fat: 15,
    date: Date(),
    mealType: "breakfast"
)

UserDataCache.shared.addMealEntry(meal)
// ✅ Saved locally and logged
```

### Get Meals for Specific Date
```swift
let targetDate = Date()
let allLogs = LocalDailyLogStore.shared.getMeals(for: targetDate)

for meal in allLogs {
    print("\(meal.mealType): \(meal.totalCalories)cal")
}
```

### Calculate Weekly Average
```swift
let weekMeals = UserDataCache.shared.getMealHistory(for: 7)
let avgCals = weekMeals.isEmpty ? 0 : 
    weekMeals.map { $0.calories }.reduce(0, +) / Double(weekMeals.count)

print("Weekly average: \(avgCals)cal/day")
```

### Sync Meals When Online
```swift
Task {
    let unsynced = LocalMealCache.shared.getUnsyncedMeals()
    
    for meal in unsynced {
        do {
            let dto = meal.items.map { ParsedItemDTO(...) }
            _ = try await NetworkManager.shared.saveParsedMeal(
                userId: userId,
                items: dto
            )
            LocalMealCache.shared.markSynced(mealId: meal.id)
        } catch {
            print("Retry later: \(error)")
        }
    }
}
```

---

## ✨ Features

- ✅ **Instant Saving**: Meals saved locally before user leaves screen
- ✅ **Offline Access**: View history anytime, even without internet
- ✅ **Automatic Sync**: Background sync to backend when online
- ✅ **Crash Protection**: Meals never lost even if app crashes
- ✅ **Auto Pruning**: Old data cleaned up automatically
- ✅ **Dual Views**: Access via UserDataCache (recent) or LocalDailyLogStore (historical)
- ✅ **Logging**: All operations logged to AppLogger

---

## 📞 Support

For issues with meal storage:
1. Check `AppLogger.shared` for meal-related logs
2. Verify `UserDataCache.shared.mealEntries` has data
3. Check `LocalDailyLogStore.shared.getMeals(for: 30)` for history
4. Inspect `DeviceStorageManager` for file I/O status
5. Test network sync with `LocalMealCache.shared.getUnsyncedMeals()`

---

**Status**: ✅ Production Ready  
**Last Updated**: February 16, 2026
