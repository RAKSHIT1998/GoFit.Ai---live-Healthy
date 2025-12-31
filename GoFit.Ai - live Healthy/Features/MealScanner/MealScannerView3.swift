import SwiftUI

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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Camera View - Full Screen
                ZStack {
                    CameraView(capturedImage: $capturedImage, captureTrigger: captureTrigger)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                    
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
                        
                        // Capture Button
                        Button(action: { 
                            captureTrigger += 1
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                        }
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

                // Results Section
                if let resp = uploadResult {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("AI Analysis Results")
                                .font(Design.Typography.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if let items = resp.parsedItems, !items.isEmpty {
                                ForEach(items, id: \.name) { it in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(it.name)
                                            .font(Design.Typography.headline)
                                            .fontWeight(.bold)
                                        
                                        HStack(spacing: 16) {
                                            if let cal = it.calories {
                                                VStack {
                                                    Text("\(Int(cal))")
                                                        .font(Design.Typography.headline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(Design.Colors.calories)
                                                    Text("Cal")
                                                        .font(Design.Typography.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            if let prot = it.protein {
                                                VStack {
                                                    Text("\(Int(prot))g")
                                                        .font(Design.Typography.headline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(Design.Colors.protein)
                                                    Text("Protein")
                                                        .font(Design.Typography.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            if let carbs = it.carbs {
                                                VStack {
                                                    Text("\(Int(carbs))g")
                                                        .font(Design.Typography.headline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(Design.Colors.carbs)
                                                    Text("Carbs")
                                                        .font(Design.Typography.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            if let fat = it.fat {
                                                VStack {
                                                    Text("\(Int(fat))g")
                                                        .font(Design.Typography.headline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(Design.Colors.fat)
                                                    Text("Fat")
                                                        .font(Design.Typography.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            if let sugar = it.sugar {
                                                VStack {
                                                    Text("\(Int(sugar))g")
                                                        .font(Design.Typography.headline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(Design.Colors.sugar)
                                                    Text("Sugar")
                                                        .font(Design.Typography.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        
                                        if let portion = it.portionSize {
                                            Text("Portion: \(portion)")
                                                .font(Design.Typography.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(Design.Colors.cardBackground)
                                    .cornerRadius(12)
                                    .shadow(color: Color.primary.opacity(0.06), radius: 8, x: 0, y: 2)
                                }
                                .padding(.horizontal)
                                
                                Button("Edit & Save Meal") {
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
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Design.Colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .font(Design.Typography.headline)
                                .padding(.horizontal)
                                .padding(.top)
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(Design.Colors.background)
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
                if newImage != nil {
                    // Automatically upload when photo is captured
                    Task {
                        await uploadImage(newImage!)
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

    // Upload image to backend which uses OpenAI vision etc and returns parsed items
    func uploadImage(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { 
            errorMsg = "Failed to process image"
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
        
        isUploading = true
        errorMsg = nil
        uploadResult = nil
        defer { isUploading = false }

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
                    errorMsg = errorMessage.contains("Food recognition") ? errorMessage : "Food recognition service is not configured. Please contact support."
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
        } catch {
            errorMsg = "Save error: \(error.localizedDescription)"
        }
    }
}
