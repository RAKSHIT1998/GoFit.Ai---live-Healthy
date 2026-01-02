import SwiftUI

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
                .font(.system(size: 20, weight: .bold))
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

    @State private var capturedImage: UIImage? = nil
    @State private var captureTrigger: Int = 0
    @State private var showPicker = false

    @State private var isUploading = false
    @State private var uploadResult: ServerMealResponse? = nil
    @State private var errorMsg: String?

    // when server returns parsed items, we map them to editable items for UI
    @State private var editableItems: [EditableParsedItem] = []
    @State private var showEditScreen = false

    @State private var showManualLog = false
    @State private var showFlash = false
    @State private var isCapturing = false
    
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
                                showPicker = true
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
                        
                        // Capture Button - Snapchat style
                        Button(action: { 
                            // Prevent multiple captures
                            guard !isCapturing else { return }
                            isCapturing = true
                            
                            // Immediate haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // Flash effect
                            withAnimation(.easeOut(duration: 0.1)) {
                                showFlash = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showFlash = false
                            }
                            
                            // Trigger capture immediately - photo taken instantly
                            captureTrigger += 1
                            
                            // Reset capture flag after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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

                // Results Section - Beautiful, aesthetic display with log/dismiss options
                if let resp = uploadResult, let items = resp.parsedItems, !items.isEmpty {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header with success animation
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Design.Colors.primary)
                                    .symbolEffect(.bounce, value: uploadResult != nil)
                                
                                Text("Meal Detected!")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("\(items.count) item\(items.count == 1 ? "" : "s") found")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 20)
                            
                            // Beautiful meal cards with nutrition
                            ForEach(Array(items.enumerated()), id: \.element.name) { index, item in
                                VStack(spacing: 0) {
                                    // Meal name header with gradient
                                    HStack {
                                        Image(systemName: "fork.knife.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        
                                        Text(item.name)
                                            .font(.system(size: 22, weight: .bold))
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
                                    
                                    // Nutrition grid - aesthetic layout
                                    VStack(spacing: 16) {
                                        // Main nutrition metrics in a grid
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 16) {
                                            // Calories - prominent
                                            NutritionMetricCard(
                                                value: item.calories.map { "\(Int($0))" } ?? "—",
                                                label: "Calories",
                                                color: Design.Colors.calories,
                                                icon: "flame.fill"
                                            )
                                            
                                            // Protein
                                            NutritionMetricCard(
                                                value: item.protein.map { "\(Int($0))g" } ?? "—",
                                                label: "Protein",
                                                color: Design.Colors.protein,
                                                icon: "figure.strengthtraining.traditional"
                                            )
                                            
                                            // Carbs
                                            NutritionMetricCard(
                                                value: item.carbs.map { "\(Int($0))g" } ?? "—",
                                                label: "Carbs",
                                                color: Design.Colors.carbs,
                                                icon: "leaf.fill"
                                            )
                                        }
                                        
                                        // Secondary metrics
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
                                        
                                        // Portion size
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
                            }
                            
                            // Action buttons - Log or Dismiss
                            VStack(spacing: 12) {
                                // Log Meal Button
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
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                        Text("Log This Meal")
                                            .font(.system(size: 18, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .font(.title3)
                                    }
                                    .foregroundColor(.white)
                                    .padding(18)
                                    .background(
                                        LinearGradient(
                                            colors: [Design.Colors.primary, Design.Colors.primary.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: Design.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                
                                // Dismiss Button
                                Button {
                                    // Reset to allow new scan
                                    uploadResult = nil
                                    capturedImage = nil
                                    isCapturing = false
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                        Text("Scan Another Meal")
                                            .font(.system(size: 18, weight: .medium))
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
                    Text(err)
                        .foregroundColor(.red)
                        .padding()
                        .background(Design.Colors.cardBackground)
                        .cornerRadius(12)
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
                if let newImage = newImage, newImage != oldValue {
                    // Automatically upload immediately when photo is captured (Snapchat style)
                    // No preview needed - instant analysis
                    Task {
                        await uploadImage(newImage)
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PHPickerWrapper(image: $capturedImage)
            }
            .sheet(isPresented: $showManualLog) {
                ManualMealLogView()
                    .environmentObject(authVM)
            }
            .sheet(isPresented: $showEditScreen) {
                NavigationView {
                    EditParsedItemsView(items: $editableItems) { finalItems in
                        Task {
                            await saveFinalMeal(parsedItems: finalItems)
                            showEditScreen = false
                        }
                    }
                }
            }
            .onAppear {
                checkCameraPermission { granted in
                    if !granted {
                        errorMsg = "Camera permission denied. Enable it in Settings."
                    }
                }
            }
        }
    }

    // Upload image to backend which uses Gemini vision and returns parsed items
    func uploadImage(_ image: UIImage) async {
        // Optimize image for faster upload - use slightly lower quality for speed
        // Still good enough for food recognition
        guard let data = image.jpegData(compressionQuality: 0.75) else { 
            await MainActor.run {
                errorMsg = "Failed to process image"
                isCapturing = false
            }
            return 
        }
        
        // Check if user is logged in and has a valid token
        guard authVM.isLoggedIn else {
            errorMsg = "Please log in to scan meals"
            return
        }
        
        guard let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty else {
            errorMsg = "Authentication required. Please log in again."
            return
        }
        
        await MainActor.run {
            isUploading = true
            errorMsg = nil
            uploadResult = nil
            isCapturing = false // Reset capture state
        }
        
        defer { 
            Task { @MainActor in
                isUploading = false
            }
        }

        do {
            let resp = try await NetworkManager.shared.uploadMealImage(data: data, filename: "meal.jpg", userId: authVM.userId)
            uploadResult = resp
        } catch {
            // Better error handling
            if let nsError = error as NSError? {
                let errorCode = nsError.code
                let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                
                // Check for timeout errors
                if errorCode == NSURLErrorTimedOut || errorMessage.contains("timeout") || errorMessage.contains("timed out") {
                    errorMsg = "Analysis timed out. Please try again with a clearer photo."
                }
                // Check for authentication errors
                else if errorCode == 401 {
                    errorMsg = "Authentication failed. Please log in again."
                    // Optionally log out the user
                    await MainActor.run {
                        authVM.logout()
                    }
                } else if errorMessage.contains("token") || errorMessage.contains("Token") || errorMessage.contains("Invalid token") {
                    errorMsg = "Session expired. Please log in again."
                    await MainActor.run {
                        authVM.logout()
                    }
                } else if errorMessage.contains("no food items") || errorMessage.contains("no items") {
                    errorMsg = "Could not identify food items. Please try a clearer photo."
                } else if errorMessage.contains("Gemini") || errorMessage.contains("GEMINI_API_KEY") || errorMessage.contains("not configured") || errorMessage.contains("Food recognition service") || errorMessage.contains("Food recognition") || errorMessage.contains("recognition service") {
                    // Use the backend error message if it contains helpful information, otherwise show a generic message
                    if errorMessage.contains("Food recognition") || errorMessage.contains("recognition service") || errorMessage.contains("GEMINI_API_KEY") || errorMessage.contains("environment variable") {
                        errorMsg = errorMessage
                    } else {
                        errorMsg = "Food recognition service is not configured. Please contact support."
                    }
                } else if errorMessage.contains("authentication failed") || errorMessage.contains("API key") {
                    errorMsg = "Service configuration error. Please contact support."
                } else if errorMessage.contains("Rate limit") || errorMessage.contains("currently busy") {
                    errorMsg = "Service is busy. Please try again in a moment."
                } else if errorMessage.contains("OpenAI") {
                    errorMsg = "AI service unavailable. Please try again later."
                } else {
                    errorMsg = "Upload error: \(errorMessage)"
                }
            } else {
                let errorDesc = error.localizedDescription
                if errorDesc.contains("timeout") {
                    errorMsg = "Analysis timed out. Please try again."
                } else {
                    errorMsg = "Upload error: \(errorDesc)"
                }
            }
        }
    }

    // Save the final corrected meal items to backend
    func saveFinalMeal(parsedItems: [EditableParsedItem]) async {
        isUploading = true
        defer { isUploading = false }
        do {
            // convert editable items to a DTO the backend expects
            let dto = parsedItems.map { ParsedItemDTO(name: $0.name, qtyText: $0.qtyText, calories: $0.calories, protein: $0.protein, carbs: $0.carbs, fat: $0.fat, sugar: $0.sugar) }
            let saved = try await NetworkManager.shared.saveParsedMeal(userId: authVM.userId, items: dto)
            // set uploadResult from returned saved response if needed
            uploadResult = saved
            
            // Post notification to refresh meal history
            NotificationCenter.default.post(name: NSNotification.Name("MealSaved"), object: nil)
        } catch {
            errorMsg = "Save error: \(error.localizedDescription)"
        }
    }
}
