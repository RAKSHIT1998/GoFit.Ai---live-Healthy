import SwiftUI
import Foundation
import AVFoundation

// Nutrition Metric Card Component
struct NutritionMetricCard: View {
    let value: String
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(Design.Typography.title3)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MealScannerView3: View {
    @EnvironmentObject var authVM: AuthViewModel
    @AppStorage("hasAcceptedAIConsent") private var hasAcceptedAIConsent = false

    @State private var capturedImage: UIImage? = nil
    @State private var captureTrigger: Int = 0
    @State private var showPicker = false
    @State private var showingAIConsentSheet = false

    @State private var isUploading = false
    @State private var uploadResult: ServerMealResponse? = nil
    @State private var errorMsg: String?

    // when server returns parsed items, we map them to editable items for UI
    @State private var editableItems: [EditableParsedItem] = []
    @State private var showEditScreen = false

    @State private var showManualLog = false
    @State private var showFlash = false
    @State private var isCapturing = false
    @State private var showSaveSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Camera View - Full Screen
                ZStack {
                    CameraView(capturedImage: $capturedImage, captureTrigger: captureTrigger)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                    
                    // Flash effect overlay (like Snapchat)
                    if showFlash {
                        Color.white
                            .ignoresSafeArea()
                            .opacity(0.8)
                            .animation(.easeOut(duration: 0.1), value: showFlash)
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                HapticManager.shared.lightTap()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPicker = true
                                }
                            } label: {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.primary.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding()
                        }
                        Spacer()
                        
                        // Capture Button - Instant capture
                        Button(action: { 
                            guard !isCapturing else { return }
                            isCapturing = true
                            
                            HapticManager.shared.mediumTap()
                            captureTrigger += 1
                            
                            withAnimation(.easeOut(duration: 0.05)) {
                                showFlash = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                showFlash = false
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isCapturing = false
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isCapturing ? Color.gray : Color.white)
                                    .frame(width: 70, height: 70)
                                    .animation(.easeInOut(duration: 0.1), value: isCapturing)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 80, height: 80)
                                
                                if isCapturing {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .disabled(isCapturing)
                        .padding(.bottom, 40)
                    }
                }

                // Results Section - Scrollable
                if isUploading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Design.Colors.primary)
                        Text("Analyzing with AI...")
                            .font(Design.Typography.headline)
                            .foregroundColor(.primary)
                            .smoothFadeIn()
                        Text("Detecting food items and nutrition")
                            .font(Design.Typography.caption)
                            .foregroundColor(.secondary)
                        Text("This may take up to 60 seconds")
                            .font(Design.Typography.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Design.Colors.background)
                }

                // Results Section
                if let resp = uploadResult, let items = resp.parsedItems, !items.isEmpty {
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: Design.Scale.value(60, textStyle: .title1)))
                                    .foregroundColor(Design.Colors.primary)
                                    .symbolEffect(.bounce, value: uploadResult != nil)
                                    .delayedAppear(0)
                                
                                Text("Meal Detected!")
                                    .font(Design.Typography.title)
                                    .foregroundColor(.primary)
                                    .delayedAppear(0.05)
                                
                                Text("\(items.count) item\(items.count == 1 ? "" : "s") found")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .delayedAppear(0.1)
                            }
                            .padding(.top, 20)
                            
                            ForEach(Array(items.enumerated()), id: \.element.name) { index, item in
                                VStack(spacing: 0) {
                                    HStack {
                                        Image(systemName: "fork.knife.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        
                                        Text(item.name)
                                            .font(Design.Typography.title2)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    .padding(20)
                                    .background(
                                        LinearGradient(
                                            colors: [Design.Colors.primary, Design.Colors.primary.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    
                                    VStack(spacing: 16) {
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 16) {
                                            NutritionMetricCard(
                                                value: item.calories.map { "\(Int($0))" } ?? "—",
                                                label: "Calories",
                                                color: Design.Colors.calories,
                                                icon: "flame.fill"
                                            )
                                            
                                            NutritionMetricCard(
                                                value: item.protein.map { "\(Int($0))g" } ?? "—",
                                                label: "Protein",
                                                color: Design.Colors.protein,
                                                icon: "figure.strengthtraining.traditional"
                                            )
                                            
                                            NutritionMetricCard(
                                                value: item.carbs.map { "\(Int($0))g" } ?? "—",
                                                label: "Carbs",
                                                color: Design.Colors.carbs,
                                                icon: "leaf.fill"
                                            )
                                        }
                                        
                                        HStack(spacing: 16) {
                                            NutritionMetricCard(
                                                value: item.fat.map { "\(Int($0))g" } ?? "—",
                                                label: "Fat",
                                                color: Design.Colors.fat,
                                                icon: "drop.fill"
                                            )
                                            
                                            NutritionMetricCard(
                                                value: item.sugar.map { "\(Int($0))g" } ?? "—",
                                                label: "Sugar",
                                                color: Design.Colors.sugar,
                                                icon: "sparkles"
                                            )
                                        }
                                        
                                        if let portion = item.portionSize {
                                            HStack {
                                                Image(systemName: "ruler.fill")
                                                    .foregroundColor(.secondary)
                                            Text("Portion: \(portion)")
                                                    .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            }
                                            .padding(.top, 8)
                                        }
                                    }
                                    .padding(20)
                                    .background(Design.Colors.cardBackground)
                                }
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
                                .padding(.horizontal)
                                .delayedAppear(Double(index) * 0.1 + 0.15)
                                .transition(.moveAndFade)
                            }
                                
                            VStack(spacing: 12) {
                                Button {
                                    HapticManager.shared.mediumTap()
                                    Task {
                                        await logMealImmediately(resp: resp)
                                    }
                                } label: {
                                    HStack {
                                        if isUploading {
                                            ProgressView()
                                                .tint(.white)
                                                .frame(width: 20, height: 20)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                        }
                                        Text(isUploading ? "Saving..." : "Log This Meal")
                                            .font(Design.Typography.headline)
                                        Spacer()
                                        if !isUploading {
                                            Image(systemName: "arrow.right")
                                                .font(.title3)
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .padding(18)
                                    .background(
                                        LinearGradient(
                                            colors: isUploading ? [Color.gray, Color.gray.opacity(0.8)] : [Design.Colors.primary, Design.Colors.primary.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: Design.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                .disabled(isUploading)
                                
                                // Edit Before Logging Button
                                Button {
                                    let items = resp.parsedItems ?? []
                                    editableItems = items.map { item in
                                        EditableParsedItem(
                                            name: item.name,
                                            qtyText: item.portionSize ?? "",
                                            calories: item.calories ?? 0,
                                            protein: item.protein ?? 0,
                                            carbs: item.carbs ?? 0,
                                            fat: item.fat ?? 0,
                                            sugar: item.sugar ?? 0
                                        )
                                    }
                                    showEditScreen = true
                                } label: {
                                    HStack {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.title3)
                                        Text("Edit Before Logging")
                                            .font(Design.Typography.body)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .font(.title3)
                                    }
                                    .foregroundColor(.primary)
                                    .padding(16)
                                    .background(Design.Colors.cardBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .disabled(isUploading)
                                
                                // Dismiss Button
                                Button {
                                    // Reset to allow new scan
                                    uploadResult = nil
                                    capturedImage = nil
                                    isCapturing = false
                                    // Trigger camera restart by incrementing trigger
                                    // This will cause CameraView to restart the session
                                    captureTrigger += 1
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                        Text("Scan Another Meal")
                                .font(Design.Typography.headline)
                                    }
                                    .foregroundColor(.primary)
                                    .padding(18)
                                    .background(Design.Colors.cardBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                        }
                    }
                    .background(Design.Colors.background)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if let err = errorMsg {
                    VStack(spacing: 12) {
                        Image(systemName: err.contains("No food") ? "photo.badge.exclamationmark" : "exclamationmark.triangle.fill")
                            .font(.system(size: Design.Scale.value(40, textStyle: .title3)))
                            .foregroundColor(err.contains("No food") ? .orange : .red)
                        
                    Text(err)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            // Clear error and allow retry
                            errorMsg = nil
                            capturedImage = nil
                            isCapturing = false
                        } label: {
                            Text("Try Again")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Design.Colors.primary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(24)
                        .background(Design.Colors.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Scan Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manual") {
                        showManualLog = true
                    }
                }
            }
            .onChange(of: capturedImage) { oldValue, newImage in
                // Only process if we have a new image and it's different from the old one
                guard let newImage = newImage, newImage != oldValue else {
                    return
                }
                
                // Prevent multiple simultaneous uploads
                guard !isUploading else {
                    print("⚠️ Already uploading, skipping new image")
                    return
                }
                
                // Check if user has accepted AI consent
                if !hasAcceptedAIConsent {
                    showingAIConsentSheet = true
                    return
                }
                
                    // Automatically upload immediately when photo is captured (Snapchat style)
                    // No preview needed - instant analysis
                    Task {
                        await uploadImage(newImage)
                }
            }
            .sheet(isPresented: $showPicker) {
                PHPickerWrapper(image: $capturedImage)
            }
            .sheet(isPresented: $showManualLog) {
                ManualMealLogView()
                    .environmentObject(authVM)
            }
            .sheet(isPresented: $showingAIConsentSheet) {
                AIDataConsentView()
                    .onDisappear {
                        // If user accepted consent, process the captured image
                        if hasAcceptedAIConsent, let image = capturedImage {
                            Task {
                                await uploadImage(image)
                            }
                        } else {
                            // User declined, clear the captured image
                            capturedImage = nil
                        }
                    }
            }
            .sheet(isPresented: $showEditScreen) {
                NavigationView {
                    EditParsedItemsView(items: $editableItems) { finalItems in
                            await saveFinalMeal(parsedItems: finalItems)
                    }
                }
            }
            .onAppear {
                checkCameraPermission { granted in
                    if !granted {
                        errorMsg = "Camera permission denied. Enable it in Settings."
                    } else {
                        // Verify camera is available
                        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil else {
                            errorMsg = "Camera not available on this device."
                            return
                        }
                    }
                }
            }
            .alert("Meal Logged!", isPresented: $showSaveSuccess) {
                Button("OK") {
                    // Reset to allow new scan
                    uploadResult = nil
                    capturedImage = nil
                    isCapturing = false
                }
            } message: {
                Text("Your meal has been saved successfully.")
            }
        }
    }

    // Automatic image compression and optimization - completely transparent to user
    // Resizes and compresses images to reduce upload time while maintaining quality for AI recognition
    private func compressImageAutomatically(_ image: UIImage) -> Data? {
        // Target maximum dimensions for faster upload (still high quality for food recognition)
        let maxDimension: CGFloat = 1920 // Good balance between quality and file size
        let maxFileSize: Int = 2 * 1024 * 1024 // 2MB max file size
        
        // Calculate new size maintaining aspect ratio
        var newSize = image.size
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let ratio = min(maxDimension / image.size.width, maxDimension / image.size.height)
            newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        }
        
        // Resize image if needed
        let resizedImage: UIImage
        if newSize != image.size {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }
        
        // Compress with adaptive quality - start high and reduce if needed
        var compressionQuality: CGFloat = 0.85 // Start with high quality
        var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        
        // If file is still too large, reduce quality incrementally
        if let data = imageData, data.count > maxFileSize {
            compressionQuality = 0.7
            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
            
            if let data = imageData, data.count > maxFileSize {
                compressionQuality = 0.6
                imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
            }
        }
        
        return imageData
    }
    
    // Upload image to backend which uses OpenAI vision and returns parsed items
    func uploadImage(_ image: UIImage) async {
        // Ensure we're on main actor for state updates
        await MainActor.run {
            // Prevent multiple simultaneous uploads
            guard !isUploading else {
                print("⚠️ Upload already in progress, skipping")
                return
            }
            
            isUploading = true
            errorMsg = nil
            isCapturing = false // Reset capture state
        }
        
        // Automatically compress and optimize image on background queue
        // User never sees this - it happens transparently
        let data = await Task.detached(priority: .userInitiated) {
            return await compressImageAutomatically(image)
        }.value
        
        guard let data = data else {
            await MainActor.run {
                errorMsg = "Failed to process image"
                isUploading = false
                isCapturing = false
            }
            return 
        }
        
        // Log compression stats (only in debug, user never sees this)
        #if DEBUG
        let originalSize = image.size
        let originalDataSize = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        let compressedSize = data.count
        let compressionRatio = Double(compressedSize) / Double(originalDataSize)
        print("📸 Image automatically compressed: \(Int(originalSize.width))x\(Int(originalSize.height)) → \(compressedSize/1024)KB (saved \(Int((1.0 - compressionRatio) * 100))%)")
        #endif
        
        // Check if user is logged in and has a valid token
        guard authVM.isLoggedIn else {
            await MainActor.run {
            errorMsg = "Please log in to scan meals"
                isUploading = false
            }
            return
        }
        
        guard let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty else {
            await MainActor.run {
            errorMsg = "Authentication required. Please log in again."
                isUploading = false
            }
            return
        }
        
        await MainActor.run {
            uploadResult = nil
        }
        
        defer { 
            Task { @MainActor in
                isUploading = false
            }
        }

        do {
            // Retry with exponential backoff - up to 10 attempts to get AI response
            // Keep retrying until we get a successful AI analysis
            let resp = try await RetryUtility.shared.retry(maxAttempts: 10) {
                try await NetworkManager.shared.uploadMealImage(data: data, filename: "meal.jpg", userId: authVM.userId)
            }
            await MainActor.run {
            uploadResult = resp
                errorMsg = nil // Clear any previous errors
            }
        } catch {
            // All retries failed - show error message to user
            // Do NOT use fallback data - scan meal MUST use AI only
            print("❌ All retry attempts failed for meal scanning")
            
            await MainActor.run {
                isUploading = false
                isCapturing = false
                
                // Parse error to show user-friendly message
            if let nsError = error as NSError? {
                let errorCode = nsError.code
                let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                
                    // Check for "no food detected" error (from backend)
                    if errorCode == 400 && errorMessage.contains("NO_FOOD_DETECTED") {
                        errorMsg = "🍽️ No food detected in this image.\n\nPlease take a photo of food or beverages to scan."
                    } else if errorCode == 504 || errorMessage.contains("timeout") {
                        errorMsg = "⏱️ Analysis timed out. Please try again with a clearer photo."
                    } else if errorCode == 429 || errorMessage.contains("rate limit") {
                        errorMsg = "🚦 Service is busy. Please wait a moment and try again."
                    } else if errorCode == 401 {
                        errorMsg = "🔐 Authentication failed. Please log in again."
                        authVM.logout()
                    } else {
                        errorMsg = "❌ Failed to analyze photo after multiple attempts.\n\nError: \(errorMessage)\n\nPlease try again or take a clearer photo."
                    }
                } else {
                    errorMsg = "❌ Failed to analyze photo. Please try again with a clearer image."
                }
                
                uploadResult = nil // Clear any partial results
            }
        }
    }

    // Log meal immediately without editing
    func logMealImmediately(resp: ServerMealResponse) async {
        guard let items = resp.parsedItems, !items.isEmpty else { return }
        
        await MainActor.run {
            isUploading = true
            errorMsg = nil
        }
        
        defer {
            Task { @MainActor in
                isUploading = false
            }
        }
        
        // Convert parsed items to editable items (with defaults)
        let editableItems = items.map { item in
            EditableParsedItem(
                name: item.name,
                qtyText: item.portionSize ?? "",
                calories: item.calories ?? 0,
                protein: item.protein ?? 0,
                carbs: item.carbs ?? 0,
                fat: item.fat ?? 0,
                sugar: item.sugar ?? 0
            )
        }
        
        await saveFinalMeal(parsedItems: editableItems)
    }

    // Save the final corrected meal items to backend
    func saveFinalMeal(parsedItems: [EditableParsedItem]) async {
        // Calculate totals
        let totalCalories = parsedItems.reduce(0) { $0 + $1.calories }
        let totalProtein = parsedItems.reduce(0) { $0 + $1.protein }
        let totalCarbs = parsedItems.reduce(0) { $0 + $1.carbs }
        let totalFat = parsedItems.reduce(0) { $0 + $1.fat }
        let totalSugar = parsedItems.reduce(0) { $0 + $1.sugar }
        
        // Create cached meal for immediate local storage
        let cachedItems = parsedItems.map { item in
            CachedMeal.CachedMealItem(
                name: item.name,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                sugar: item.sugar,
                portionSize: item.qtyText.isEmpty ? nil : item.qtyText
            )
        }
        
        let cachedMeal = CachedMeal(
            id: UUID().uuidString,
            timestamp: Date(),
            items: cachedItems,
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            totalSugar: totalSugar,
            mealType: "snack", // Default, can be enhanced later
            synced: false
        )
        
        // Store locally IMMEDIATELY for instant UI update
        LocalMealCache.shared.addMeal(cachedMeal)
        
        // Also save to daily log store for historical tracking
        let mealItems = parsedItems.map { item in
            MealItem(
                name: item.name,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                sugar: item.sugar,
                portionSize: nil, // portionSize is for standardized portion (not available in EditableParsedItem)
                quantity: item.qtyText.isEmpty ? nil : item.qtyText // quantity is the user-entered text like "1 cup" or "200g"
            )
        }
        
        let loggedMeal = LoggedMeal(
            timestamp: Date(),
            mealType: .snack, // Can be enhanced to allow user selection
            items: mealItems,
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            totalSugar: totalSugar
        )
        
        LocalDailyLogStore.shared.addMeal(loggedMeal)
        
        // Post notification to refresh UI immediately
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("MealSaved"), object: nil)
            showSaveSuccess = true
        }
        
        // Then sync to backend in background (non-blocking)
        Task.detached(priority: .utility) {
        do {
            // convert editable items to a DTO the backend expects
            let dto = parsedItems.map { ParsedItemDTO(name: $0.name, qtyText: $0.qtyText, calories: $0.calories, protein: $0.protein, carbs: $0.carbs, fat: $0.fat, sugar: $0.sugar) }
                let _ = try await NetworkManager.shared.saveParsedMeal(userId: authVM.userId, items: dto)
            
                // Mark as synced in local cache
                LocalMealCache.shared.markSynced(mealId: cachedMeal.id)
                print("✅ Meal synced to backend: \(cachedMeal.id)")
        } catch {
                print("⚠️ Failed to sync meal to backend: \(error.localizedDescription)")
                // Meal remains in cache with synced=false, can retry later
            }
        }
    }
}
