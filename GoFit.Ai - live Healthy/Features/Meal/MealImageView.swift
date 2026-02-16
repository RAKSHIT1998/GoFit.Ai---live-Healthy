import SwiftUI
import PhotosUI

/// View for displaying and managing meal photos
struct MealImageView: View {
    let mealId: String
    let mealName: String
    @ObservedObject private var imageManager = MealImageManager.shared
    @State private var mealPhotos: [UIImage] = []
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Meal Photos")
                .font(.headline)
                .fontWeight(.bold)
            
            if mealPhotos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No photos yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: { showingPhotoPicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Photo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(mealPhotos.enumerated()), id: \.offset) { index, photo in
                            MealPhotoThumbnail(
                                image: photo,
                                index: index,
                                onDelete: { deletePhoto(at: index) }
                            )
                        }
                        
                        Button(action: { showingPhotoPicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text("Add")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 120)
            }
        }
        .onAppear {
            loadMealPhotos()
        }
        .onChange(of: selectedPhoto) { oldPhoto, newPhoto in
            if let photo = newPhoto {
                saveMealPhoto(photo)
                selectedPhoto = nil
            }
        }
    }
    
    private func loadMealPhotos() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let photos = imageManager.getMealPhotos(mealId: mealId)
            DispatchQueue.main.async {
                self.mealPhotos = photos
                isLoading = false
            }
        }
    }
    
    private func saveMealPhoto(_ image: UIImage) {
        guard let imageData = image.compressedData(quality: 0.75) else { return }
        
        let filename = imageManager.saveMealPhoto(imageData, mealId: mealId, mealName: mealName)
        if !filename.isEmpty {
            AppLogger.shared.meal("Photo saved for meal: \(mealName)")
            loadMealPhotos()
        }
    }
    
    private func deletePhoto(at index: Int) {
        // In production, would delete by filename
        mealPhotos.remove(at: index)
        AppLogger.shared.meal("Deleted photo for meal: \(mealName)")
    }
}

/// Thumbnail view for a meal photo with delete option
struct MealPhotoThumbnail: View {
    let image: UIImage
    let index: Int
    let onDelete: () -> Void
    @State private var showingDelete = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                .clipped()
            
            Button(action: { showingDelete = true }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                    )
            }
            .padding(4)
            .confirmationDialog(
                "Delete Photo",
                isPresented: $showingDelete,
                actions: {
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                },
                message: {
                    Text("Remove this photo?")
                }
            )
        }
    }
}

/// Card view for displaying meal with photo
struct MealCardWithImageView: View {
    let meal: MealEntry
    @State private var mealImage: UIImage?
    @State private var isLoadingImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(formatDate(meal.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(Int(meal.calories)) cal")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(meal.mealType.capitalized)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Meal Photo if available
            if let image = mealImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .cornerRadius(8)
                    .clipped()
            } else {
                ZStack {
                    Color(.systemGray5)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("No photo")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 150)
                .cornerRadius(8)
            }
            
            // Nutrition Info
            HStack(spacing: 12) {
                NutritionBadge(label: "Protein", value: "\(Int(meal.protein))g", color: .blue)
                NutritionBadge(label: "Carbs", value: "\(Int(meal.carbs))g", color: .green)
                NutritionBadge(label: "Fat", value: "\(Int(meal.fat))g", color: .red)
            }
            
            if let notes = meal.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    Text(notes)
                        .font(.caption)
                        .lineLimit(2)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onAppear {
            loadMealImage()
        }
    }
    
    private func loadMealImage() {
        isLoadingImage = true
        DispatchQueue.global(qos: .userInitiated).async {
            let image = MealImageManager.shared.getLatestMealThumbnail(mealId: meal.id)
            DispatchQueue.main.async {
                self.mealImage = image
                isLoadingImage = false
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Small nutrition badge
struct NutritionBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

/// View for browsing all meal photos
struct MealPhotoBrowserView: View {
    @State private var mealPhotos: [UIImage] = []
    @State private var selectedPhoto: UIImage?
    @State private var isLoading = false
    @ObservedObject private var imageManager = MealImageManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 150))],
                    spacing: 12
                ) {
                    ForEach(Array(mealPhotos.enumerated()), id: \.offset) { index, photo in
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .cornerRadius(8)
                            .clipped()
                            .onTapGesture {
                                selectedPhoto = photo
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Meal Photos")
            .sheet(isPresented: .constant(selectedPhoto != nil), onDismiss: { selectedPhoto = nil }) {
                if let photo = selectedPhoto {
                    MealPhotoDetailView(image: photo)
                }
            }
        }
    }
}

/// Detail view for a single meal photo
struct MealPhotoDetailView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .padding()
                
                VStack(spacing: 8) {
                    Button(action: { showingShareSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Photo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [image])
            }
        }
    }
}

/// Share sheet for exporting meal photos
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    MealCardWithImageView(
        meal: MealEntry(
            name: "Grilled Chicken with Rice",
            calories: 550,
            protein: 40,
            carbs: 60,
            fat: 12,
            mealType: "lunch"
        )
    )
    .padding()
}
