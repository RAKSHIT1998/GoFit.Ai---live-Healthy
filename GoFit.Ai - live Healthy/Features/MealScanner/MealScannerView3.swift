import SwiftUI

struct MealScannerView3: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var capturedImage: UIImage? = nil
    @State private var isTaking = false
    @State private var showPreview = false
    @State private var showPicker = false

    @State private var isUploading = false
    @State private var uploadResult: ServerMealResponse? = nil
    @State private var errorMsg: String?

    // when server returns parsed items, we map them to editable items for UI
    @State private var editableItems: [EditableParsedItem] = []
    @State private var showEditScreen = false

    @State private var showManualLog = false
    
    var body: some View {
        VStack {
            ZStack {
                CameraView(capturedImage: $capturedImage, isTaking: $isTaking)
                    .frame(height: 420)
                    .cornerRadius(12)

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showPicker = true
                        } label: {
                            Image(systemName: "photo.on.rectangle.angled")
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
            .padding()

            HStack(spacing: 20) {
                Button(action: { isTaking = true }) { 
                    Label("Capture", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.2, green: 0.7, blue: 0.6))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                Button(action: { showManualLog = true }) { 
                    Label("Manual Log", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            if let img = capturedImage {
                Button(action: { showPreview = true }) {
                    Label("Preview & Upload", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }

            if isUploading { ProgressView("Uploading & analyzing...") }

            if let resp = uploadResult {
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Analysis Results")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    if let items = resp.parsedItems, !items.isEmpty {
                        ForEach(items, id: \.name) { it in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(it.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                HStack(spacing: 12) {
                                    if let cal = it.calories {
                                        Label("\(Int(cal))", systemImage: "flame.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    if let prot = it.protein {
                                        Label("\(Int(prot))g", systemImage: "p.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    if let carbs = it.carbs {
                                        Label("\(Int(carbs))g", systemImage: "c.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    if let fat = it.fat {
                                        Label("\(Int(fat))g", systemImage: "f.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    }
                                    if let sugar = it.sugar {
                                        Label("\(Int(sugar))g", systemImage: "s.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                if let portion = it.portionSize {
                                    Text("Portion: \(portion)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        Button("Edit & Save Meal") {
                            // map to editable and show editor
                            let items = resp.parsedItems ?? []
                            editableItems = items.map { item in
                                EditableParsedItem(
                                    name: item.name,
                                    qtyText: item.portionSize ?? "", // Use portionSize if available
                                    calories: item.calories ?? 0,
                                    protein: item.protein ?? 0,
                                    carbs: item.carbs ?? 0,
                                    fat: item.fat ?? 0,
                                    sugar: item.sugar ?? 0 // Include sugar
                                )
                            }
                            showEditScreen = true
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    } else {
                        Text("No parsed items.")
                    }
                }
                .padding()
            }

            if let err = errorMsg {
                Text(err).foregroundColor(.red).padding()
            }

            Spacer()
        }
        .sheet(isPresented: $showPreview) {
            if let img = capturedImage {
                VStack {
                    Image(uiImage: img).resizable().scaledToFit()
                    HStack {
                        Button("Retake") { capturedImage = nil; showPreview = false }
                        Spacer()
                        Button("Upload") {
                            Task { await uploadImage(img) ; showPreview = false }
                        }
                    }
                    .padding()
                }
                .padding()
            } else {
                Text("No image")
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

    // Upload image to backend which uses OpenAI vision etc and returns parsed items
    func uploadImage(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        isUploading = true
        errorMsg = nil
        uploadResult = nil
        defer { isUploading = false }

        do {
            let resp = try await NetworkManager.shared.uploadMealImage(data: data, filename: "meal.jpg", userId: authVM.userId)
            uploadResult = resp
        } catch {
            errorMsg = "Upload error: \(error.localizedDescription)"
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
