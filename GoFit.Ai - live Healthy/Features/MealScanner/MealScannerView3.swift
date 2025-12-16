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
                Button(action: { isTaking = true }) { Label("Capture", systemImage: "camera") }
                Button(action: {
                    if let _ = capturedImage { showPreview = true }
                }) { Label("Preview", systemImage: "eye") }
            }
            .padding(.bottom)

            if isUploading { ProgressView("Uploading & analyzing...") }

            if let resp = uploadResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Parsed items:")
                        .font(.headline)
                    if let items = resp.parsedItems, !items.isEmpty {
                        ForEach(items, id: \.name) { it in
                            HStack {
                                Text(it.name)
                                Spacer()
                                if let cal = it.calories { Text("\(Int(cal)) kcal") }
                            }
                        }
                        Button("Edit & Save") {
                            // map to editable and show editor
                            let items = resp.parsedItems ?? []
                            editableItems = items.map { item in
                                EditableParsedItem(
                                    name: item.name,
                                    qtyText: "", // ParsedItem doesn't have qtyText, will be editable in EditParsedItemsView
                                    calories: item.calories ?? 0,
                                    protein: item.protein ?? 0,
                                    carbs: item.carbs ?? 0,
                                    fat: item.fat ?? 0
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
            let dto = parsedItems.map { ParsedItemDTO(name: $0.name, qtyText: $0.qtyText, calories: $0.calories, protein: $0.protein, carbs: $0.carbs, fat: $0.fat) }
            let saved = try await NetworkManager.shared.saveParsedMeal(userId: authVM.userId, items: dto)
            // set uploadResult from returned saved response if needed
            uploadResult = saved
        } catch {
            errorMsg = "Save error: \(error.localizedDescription)"
        }
    }
}
