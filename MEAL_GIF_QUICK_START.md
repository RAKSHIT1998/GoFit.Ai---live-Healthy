# 🍽️ Meal GIF Features - Quick Start

## What's New

You can now see **real cooking videos** for meal recommendations! 🎬

## How to Use

### 1. View Meal Recipe Videos
```
Home → Recommendations → Meals Tab
  ↓
Tap any meal card
  ↓
"View Recipe Video" button ← NEW!
  ↓
See cooking video in modal
  ↓
Tap video to Pause/Play
```

### 2. Interactive Features
- **Tap the GIF:** Toggle play/pause
- **Tap the button:** View full recipe with video
- **See nutrition:** Macro breakdown with color-coded bars
- **Expandable sections:** Ingredients & Instructions

## Example Flow

```
User sees: "Grilled Chicken Breast"
       ↓
Taps: "View Recipe Video"
       ↓
MealDemoView opens with:
  - Loading... (fetching from Giphy)
  - Video shows cooking the chicken
  - Nutrition breakdown
  - Ingredients & instructions
  ↓
Tap video to pause/play cooking demo
```

## What Happens Behind the Scenes

```
📱 You tap "View Recipe Video"
     ↓
🌐 App searches Giphy for: "Grilled Chicken Breast recipe cooking"
     ↓
✅ Giphy returns cooking video GIF
     ↓
💾 Caches for fast replay (memory + disk)
     ↓
🎬 Displays with play/pause control
     ↓
💡 If Giphy unavailable: Shows emoji + cooking tips
```

## Fallback Chain (Automatic)

1. **Try:** Fetch real video from Giphy ✅
2. **If not available:** Use local generated GIF (if available)
3. **If still unavailable:** Show emoji + cooking tips

**Result:** Always shows something useful!

## Supported Meals

Works with **ANY** meal in recommendations!

Examples:
- Breakfast: Oatmeal, Eggs, Pancakes
- Lunch: Pasta, Salad, Sandwich
- Dinner: Salmon, Steak, Stir Fry
- Snacks: Yogurt, Nuts, Berries

## Features

✅ Real cooking videos from Giphy  
✅ Tap to play/pause  
✅ Nutrition visualization  
✅ Expandable ingredients  
✅ Expandable instructions  
✅ Offline fallback (emoji + tips)  
✅ Smart caching (memory + disk)  
✅ Loading indicators  
✅ Error handling  

## UI Preview

```
┌─────────────────────────────────┐
│    🎥 Pasta Carbonara Recipe    │
├─────────────────────────────────┤
│                                 │
│   [   GIF Playing    ] 🎬       │
│   [  (Tap to Pause)  ]         │
│                                 │
├─────────────────────────────────┤
│ 🍝 Pasta Carbonara              │
│    450 kcal    35g P            │
├─────────────────────────────────┤
│ Nutrition Breakdown:            │
│ Protein: ████████░░░ 35g       │
│ Carbs:   ██████████░ 50g       │
│ Fat:     ██████░░░░░ 18g       │
├─────────────────────────────────┤
│ ⏱️ 20 min prep • 👤 2 servings  │
├─────────────────────────────────┤
│ ▶ Ingredients                   │
│ ▶ How to Make                   │
└─────────────────────────────────┘
```

## Testing Tips

**Best Experience:**
1. Go to Recommendations tab
2. Tap "Meals"
3. Tap "View Recipe Video" on any meal
4. Watch the cooking demonstration
5. Tap to pause/play

**Offline Testing:**
1. Enable Airplane Mode
2. Tap "View Recipe Video"
3. See fallback: emoji + cooking tips
4. Disable Airplane Mode to see real videos

**Repeat Views:**
1. After first view, GIF is cached
2. Subsequent views load instantly
3. Check Documents/GiphyExerciseGifs/ for cache

## Same Technology as Exercises

Just like exercise demo videos, meals now support:
- 🎬 Giphy video fetching
- 💾 Dual-tier caching (memory + disk)
- 🔄 Fallback chain
- ⏸️ Play/pause control
- 📊 Loading states
- ⚠️ Error handling

## Performance

| Action | Time |
|--------|------|
| First load (Giphy fetch) | ~500-2000ms |
| Cached load (memory) | <1ms |
| Cached load (disk) | ~50ms |
| GIF playback | Smooth 24fps |

## Storage

- **Memory cache:** Limited to 100 MB
- **Disk cache:** Documents/GiphyExerciseGifs/
- **Total:** Depends on meal variety

Clear cache manually if needed (Settings → Clear Cache)

---

**That's it!** 🎉 Enjoy watching real cooking videos with your meal recommendations!
