import SwiftUI

struct MealScannerView2: View {
    @State private var capturedImage: UIImage? = nil
    @State private var isTaking = false
    @State private var showPreview = false
    @State private var isUploading = false
    @State private var uploadResult: ServerMealResponse? = nil
    @State private var errorMsg: String?

    var body: some View {
        VStack {
            ZStack {
                CameraView(capturedImage: $capturedImage, isTaking: $isTaking)
                    .frame(height: 420)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(lineWidth: 2)
                            .foregroundColor(.white)
                            .opacity(0.15)
                    )
                // Square guide
                GeometryReader { geo in
                    let width = geo.size.width.isFinite && !geo.size.width.isNaN ? geo.size.width : 0
                    let height = geo.size.height.isFinite && !geo.size.height.isNaN ? geo.size.height : 0
                    let size = min(width, height) * 0.6
                    let validSize = size.isFinite && !size.isNaN && size > 0 ? size : 100
                    Rectangle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .frame(width: validSize, height: validSize)
                        .foregroundColor(.white)
                        .opacity(0.6)
                        .position(x: width > 0 ? width/2 : 0, y: height > 0 ? height/2 : 0)
                }
            }
            .padding()

            HStack(spacing: 20) {
                Button(action: {
                    isTaking = true
                }) {
                    Label("Capture", systemImage: "camera.circle")
                        .font(.title2)
                }

                Button(action: {
                    if capturedImage != nil { showPreview = true }
                }) {
                    Label("Preview", systemImage: "photo")
                }
            }
            .padding(.bottom)

            if isUploading { ProgressView("Uploading & analyzing...") }

            if let resp = uploadResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected:")
                        .font(.headline)
                    if let items = resp.parsedItems {
                        ForEach(items, id: \.name) { it in
                            HStack {
                                Text(it.name)
                                Spacer()
                                if let cal = it.calories { Text("\(Int(cal)) kcal") }
                            }
                        }
                    } else {
                        Text("No parsed items returned.")
                    }

                    if let rec = resp.recommendations {
                        Text("Recommendation:")
                            .font(.headline)
                        Text(rec)
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
                            Task {
                                await uploadImage(img)
                                showPreview = false
                            }
                        }
                    }
                    .padding()
                }
                .padding()
            } else {
                Text("No image")
            }
        }
        .onAppear {
            checkCameraPermission { granted in
                if !granted {
                    errorMsg = "Camera permission denied. Go to Settings → Privacy → Camera and enable."
                }
            }
        }
    }

    func uploadImage(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        isUploading = true
        errorMsg = nil
        defer { isUploading = false }

        do {
            // if you maintain a userId in your local auth, pass it here
            let userId: String? = nil
            let resp = try await NetworkManager.shared.uploadMealImage(data: data, filename: "meal.jpg", userId: userId)
            uploadResult = resp
        } catch {
            errorMsg = "Upload error: \(error.localizedDescription)"
        }
    }
}
