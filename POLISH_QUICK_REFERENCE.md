# 🎨 Polish Extensions - Quick Reference Guide

## Quick Start - Adding Polish to New Screens

### 1. Import the Polish Extension
```swift
import SwiftUI
// PolishExtensions.swift is automatically available
```

### 2. Add Haptic Feedback to Buttons
```swift
Button(action: {
    HapticManager.shared.lightTap()  // or .mediumTap(), .heavyTap()
    // Your action here
}) {
    Text("Action")
}
```

### 3. Add Smooth Animations to Content
```swift
// Fade in with delay
VStack {
    Text("Content")
}
.smoothFadeIn(delay: 0.1)

// Scale animation
Text("Growing Text")
    .smoothScale(delay: 0.2)

// Slide in animations
VStack {
    Text("Sliding in")
}
.slideInFromBottom()
```

### 4. Apply Button Styling
```swift
Button(action: {}) {
    Text("Smooth Action")
}
.buttonStyle(SmoothButtonStyle())
```

### 5. Add Staggered Animations to Lists
```swift
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ItemView(item: item)
        .delayedAppear(Double(index) * 0.05)  // 50ms delay per item
        .transition(.moveAndFade)
}
```

### 6. Show Loading States
```swift
// Skeleton loading
if isLoading {
    SkeletonLoadingView()
}

// With overlay
VStack {
    // Content
}
.modifier(LoadingOverlay(isLoading: isLoading))
```

### 7. Display Progress
```swift
SmoothProgressView(
    value: progress,
    color: Design.Colors.primary
)
```

### 8. Create Toast Notifications
```swift
@State private var showSuccess = false

VStack {
    // Content
}
.toast(isPresented: $showSuccess, message: "Success!", type: .success)
```

### 9. Dismiss Keyboard on Swipe
```swift
TextField("Enter text", text: $text)
    .dismissKeyboardOnSwipe()
```

### 10. Add Tab Selection Haptics
```swift
TabView(selection: $selectedTab) {
    Tab1()
        .tag(0)
    Tab2()
        .tag(1)
}
.modifier(SmoothTabSelection())
```

---

## Common Patterns

### Pattern 1: Loading to Success
```swift
@State private var isLoading = false
@State private var showSuccess = false

Button(action: {
    HapticManager.shared.mediumTap()
    Task {
        withAnimation {
            isLoading = true
        }
        
        // Do work
        try await someAsyncOperation()
        
        withAnimation {
            isLoading = false
            showSuccess = true
        }
        HapticManager.shared.success()
    }
}) {
    if isLoading {
        ProgressView()
    } else {
        Text("Save")
    }
}
.disabled(isLoading)
.toast(isPresented: $showSuccess, message: "Saved!", type: .success)
```

### Pattern 2: Staggered List Animation
```swift
VStack(spacing: Design.Spacing.md) {
    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
        ItemView(item: item)
            .delayedAppear(Double(index) * 0.1)
            .transition(.moveAndFade)
    }
}
```

### Pattern 3: Modal with Polish
```swift
@State private var showModal = false

Button(action: {
    HapticManager.shared.mediumTap()
    withAnimation(.easeInOut(duration: 0.2)) {
        showModal = true
    }
}) {
    Text("Open Modal")
}
.sheet(isPresented: $showModal) {
    VStack {
        // Content
    }
    .delayedAppear(0)
}
```

### Pattern 4: Form with Smooth Interactions
```swift
@State private var value = ""

Form {
    Section("Input") {
        TextField("Enter text", text: $value)
            .dismissKeyboardOnSwipe()
            .onChange(of: value) { _ in
                HapticManager.shared.lightTap()
            }
    }
}
.smoothListStyle()
```

---

## Haptic Feedback Timing

| Interaction | Haptic | Duration | Example |
|-------------|--------|----------|---------|
| Light button tap | `lightTap()` | - | Picker changes |
| Standard action | `mediumTap()` | - | Form submit |
| Heavy action | `heavyTap()` | - | Delete action |
| Success | `success()` | 200ms | Meal saved |
| Error | `error()` | 100ms | Validation failed |
| Warning | `warning()` | 150ms | Fast ended |

---

## Animation Timing Standards

| Type | Duration | Easing | Use Case |
|------|----------|--------|----------|
| Light | 150-200ms | easeInOut | Subtle changes |
| Standard | 200-300ms | spring | Main interactions |
| Heavy | 300-500ms | spring | Complex animations |
| Stagger | 50-100ms | linear | List items |

---

## Common Mistakes to Avoid

❌ **Don't:** Add haptics to every interaction
✅ **Do:** Use haptics strategically for important actions

❌ **Don't:** Use long animations (>500ms)
✅ **Do:** Keep animations snappy (200-300ms)

❌ **Don't:** Animate all state changes
✅ **Do:** Animate user-initiated actions

❌ **Don't:** Stack multiple animations on same view
✅ **Do:** Use transitions for clear state changes

❌ **Don't:** Forget to disable buttons during loading
✅ **Do:** Use `.disabled(isLoading)` to prevent double-tap

---

## Testing Polish

### Visual Testing
1. Open each screen and observe animations
2. Verify all button presses trigger haptics
3. Check loading states display correctly
4. Test on device (simulator haptics may vary)

### Performance Testing
1. Profile animations with Instruments
2. Monitor memory usage during heavy animations
3. Test on older iPhone models (haptics work on 6s+)

### User Testing
1. Ask users if interactions feel responsive
2. Gather feedback on haptic intensity
3. Note if any animations feel delayed
4. Check accessibility with VoiceOver

---

## Troubleshooting

### Animations Not Playing
- Ensure `withAnimation` wrapper is used
- Check if view is in a `NavigationView` (may block transitions)
- Verify opacity changes with `.smoothFadeIn()`

### Haptics Not Triggering
- Confirm haptics enabled in device settings
- Test on physical device (simulator has limited support)
- Check if `HapticManager.shared` is properly initialized
- Verify haptic style matches interaction

### Performance Issues
- Reduce number of animated items in list
- Simplify gradient/shadow effects
- Use `.drawingGroup()` for complex views
- Profile with Instruments

### Layout Issues
- Use `.transition()` carefully with Lists
- Test with dynamic type sizes
- Verify constraints with `.frame()`
- Test on multiple screen sizes

---

## Design Philosophy

**Every animation should:**
1. **Guide attention** - Help users focus on important elements
2. **Provide feedback** - Confirm user actions
3. **Feel responsive** - Never make app feel slow
4. **Be purposeful** - Not just decorative
5. **Respect preferences** - Honor reduce motion settings

---

## Resources

- `PolishExtensions.swift` - All polish utilities
- `Design.swift` - Design system constants
- `Design.Animation` - Pre-configured timing curves
- `HapticManager` - Haptic feedback system

---

**Happy Polishing! 🎨**
