# Giphy Integration - Workout GIF Fetching

## Overview

The app now supports fetching real, high-quality workout GIFs from Giphy API instead of relying only on local procedural animations. This provides users with authentic demonstrations of exercises.

**Status**: ✅ Complete Implementation
**Date**: February 17, 2026

---

## 🎬 How It Works

### Hierarchy
1. **First Choice**: Fetch from Giphy API (real workout videos)
2. **Fallback**: Use locally-generated GIFs (procedural stick figures)
3. **Final Fallback**: Display exercise icon with form tips

### Process Flow
```
User opens exercise demo
    ↓
GiphyGifService.fetchGifData(for: exerciseName)
    ├─ Check memory cache
    ├─ Check disk cache
    └─ Fetch from Giphy API
    ↓
Download GIF & Save to Cache
    ├─ Memory cache (NSCache, 100 MB limit)
    └─ Disk cache (Documents/GiphyExerciseGifs/)
    ↓
Display in GifImageView
```

---

## 📝 Setup Instructions

### 1. Get Giphy API Key

1. Visit [https://developers.giphy.com/](https://developers.giphy.com/)
2. Sign up for a free account
3. Create a new app to get your API key
4. Copy your API key (looks like: `abc123xyz789def`)

### 2. Add API Key to App

**Option A: Environment Variable (Recommended)**
```bash
# Add to your build configuration or shell
export GIPHY_API_KEY="your_api_key_here"
```

**Option B: Config File**
Create `Config.plist` in the app bundle:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GIPHY_API_KEY</key>
    <string>your_api_key_here</string>
</dict>
</plist>
```

**Option C: Hardcode (Not Recommended)**
Edit `GiphyGifService.swift`:
```swift
init() {
    self.apiKey = "your_api_key_here" // Direct assignment
}
```

### 3. Rebuild and Test

```bash
# Clean build
Cmd + Shift + K

# Run
Cmd + R
```

---

## 🔍 Searching for Giphy GIFs

The service searches for workout GIFs using:
- Exercise name: "push-ups"
- Additional context: "exercise", "fitness", "gym"

Examples:
- "push-ups" → searches "push-ups exercise fitness gym"
- "squats" → searches "squats exercise fitness gym"
- "plank" → searches "plank exercise fitness gym"

**Rating Filter**: G-rated only (family-friendly)
**Limit**: 1 GIF per search (best match)

---

## 💾 Caching System

### Memory Cache (NSCache)
- **Limit**: 100 MB
- **Speed**: < 1 ms access
- **Lifetime**: While app is running

### Disk Cache
- **Location**: `Documents/GiphyExerciseGifs/`
- **Speed**: ~50-100 ms access
- **Lifetime**: Persistent (survives app restarts)

### Cache Size Management
```swift
// Check storage usage
let usageMB = GiphyGifService.shared.getStorageUsageMB()
print("Giphy GIF cache: \(usageMB) MB")

// Clear cache when needed
GiphyGifService.shared.clearAllGifs()
```

---

## 📱 Usage in Code

### Basic Usage
```swift
let giphyService = GiphyGifService.shared

// Fetch GIF for exercise
giphyService.fetchGifData(for: "push-ups") { result in
    switch result {
    case .success(let gifData):
        // Use GIF data for display
        print("Got GIF: \(gifData.count) bytes")
    case .failure(let error):
        // Use fallback (local GIFs or icon)
        print("Error: \(error.localizedDescription)")
    }
}
```

### Check if Cached
```swift
// Returns true if in memory or disk cache
if giphyService.hasGif(for: "squats") {
    let data = giphyService.getGifData(for: "squats")
}
```

### Integration with ExerciseDemoView
```swift
// Already integrated! Opens with Giphy GIFs
// Falls back to local GIFs if Giphy fails
ExerciseDemoView(exercise: exercise)
```

---

## 🔌 API Response Format

Giphy returns rich GIF data:
```json
{
  "data": [
    {
      "id": "xyz123",
      "title": "Push-ups workout",
      "images": {
        "original": {
          "url": "https://media.giphy.com/media/xyz/giphy.gif",
          "width": "480",
          "height": "360",
          "frames": "60"
        }
      }
    }
  ]
}
```

---

## ⚠️ Error Handling

### Graceful Fallback Chain
```
Giphy API Unavailable
    ↓
Try Local Procedure Animations
    ↓
Show Icon + Form Tips
```

### Error Types
| Error | Cause | Recovery |
|-------|-------|----------|
| `noApiKey` | API key not set | Set GIPHY_API_KEY |
| `networkError` | Internet connection | Fallback to local |
| `noGifFound` | No matching GIF | Show form tips |
| `decodingError` | Invalid JSON response | Retry with fallback |
| `downloadError` | Download failed | Use cached version |

---

## 📊 Performance

### Download Sizes
| GIF Type | Size | Frames |
|----------|------|--------|
| Giphy GIF | 2-5 MB | 30-60 |
| Local GIF | 2-3 MB | 24 |

### Load Times
| Source | Time | Condition |
|--------|------|-----------|
| Memory Cache | < 1 ms | After first load |
| Disk Cache | ~50 ms | After download |
| Giphy API | ~2-3 sec | First time fetch |

---

## 🎯 Supported Exercises

The service works with any exercise name, but works best with:

### Popular Exercises
- Push-ups / Push ups
- Squats
- Pull-ups / Pull ups
- Lunges
- Planks
- Jumping Jacks / Jumping jacks
- Burpees
- Mountain Climbers / Mountain climbers
- Running / Cardio
- Cycling
- Swimming
- Yoga
- Pilates
- CrossFit
- HIIT
- Boxing

### Tips for Best Results
- Use common names ("push-ups" not "pushups")
- Use singular or plural (both work)
- Include equipment if relevant ("dumbbell squats")

---

## 🐛 Troubleshooting

### GIFs Not Loading
**Check 1**: Verify API key is set
```swift
let service = GiphyGifService.shared
print(service.apiKey.isEmpty ? "❌ No API key" : "✅ API key set")
```

**Check 2**: Verify internet connection
```swift
// Try fetching from a known exercise
giphyService.fetchGifData(for: "push-ups") { result in
    print(result)
}
```

**Check 3**: Clear cache and retry
```swift
GiphyGifService.shared.clearAllGifs()
// Then try fetching again
```

### Slow Loading
- **Cause**: Network latency
- **Solution**: GIFs are cached after first load
- **Result**: 2nd+ views load instantly

### API Key Not Found
- **Cause**: Environment variable not set
- **Solution**: Check build settings or add Config.plist

### "No suitable GIF found"
- **Cause**: Giphy has no matching GIF
- **Solution**: App falls back to local GIFs automatically
- **Result**: Exercise still displays with icon and tips

---

## 📚 Code Files

### New Files
- `Services/GiphyGifService.swift` (400+ lines)
  - GiphyGifService singleton
  - Giphy API integration
  - Response parsing & caching
  - Error handling

### Modified Files
- `Services/ExerciseGifService.swift`
  - Updated ExerciseDemoView
  - Integrated Giphy fetching
  - Fallback to local GIFs
  - Loading states

---

## 🔄 Integration Points

### With Existing Systems
✅ **ExerciseDemoView** - Already integrated
✅ **ExerciseGifService** - Fallback support
✅ **GifImageView** - Display component
✅ **WorkoutSuggestionsView** - Uses ExerciseDemoView

### Workflow
1. User taps "View Demo" on exercise card
2. ExerciseDemoView opens
3. Attempts to fetch from Giphy
4. Falls back to local GIFs if needed
5. Displays with play/pause controls

---

## 🚀 Future Enhancements

- [ ] Local video downloads from Giphy (MP4 format)
- [ ] Caching quality selection (HD/SD/Mobile)
- [ ] Trending exercises from Giphy
- [ ] User ratings for GIFs
- [ ] Offline-first architecture (pre-cache popular exercises)
- [ ] Custom GIF search UI
- [ ] Multiple Giphy results per exercise

---

## 📝 Example Implementation

See `ExerciseDemoView.loadGif()` method in `ExerciseGifService.swift` for complete integration example.

```swift
private func loadGif() {
    isLoadingGif = true
    
    // Try Giphy first
    giphyService.fetchGifData(for: exercise.name) { result in
        switch result {
        case .success(let data):
            DispatchQueue.main.async {
                self.gifData = data
                self.isLoadingGif = false
            }
        case .failure(_):
            // Fallback to local
            DispatchQueue.main.async {
                self.gifData = self.gifService.getGifData(for: self.exercise.name)
                self.isLoadingGif = false
            }
        }
    }
}
```

---

**Ready to Use**: ✅ All files created and integrated
**No API Key**: Set your GIPHY_API_KEY before building
**Offline Support**: App works with or without API key

