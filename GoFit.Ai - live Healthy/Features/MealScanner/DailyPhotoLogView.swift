import SwiftUI
import UIKit

struct DailyPhotoLogView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthViewModel

    @State private var capturedImage: UIImage?
    @State private var isSaving = false
    @State private var showCamera = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Design.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: Design.Spacing.lg) {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Design.Colors.primary)

                    Text("Daily Photo Log")
                        .font(Design.Typography.title2)
                        .fontWeight(.bold)

                    Text("Take a quick photo to log your day. This will appear in Meal History.")
                        .font(Design.Typography.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Design.Typography.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button {
                        HapticManager.shared.mediumTap()
                        showCamera = true
                    } label: {
                        Text("Take Photo")
                            .font(Design.Typography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(Design.Spacing.md)
                            .background(Design.Colors.primary)
                            .cornerRadius(Design.Radius.medium)
                    }
                    .buttonStyle(SmoothButtonStyle())
                    .disabled(isSaving)
                }
                .padding(Design.Spacing.lg)
            }
            .navigationTitle("Daily Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraImagePicker(image: $capturedImage, cameraDevice: .front)
            }
            .onChange(of: capturedImage) { _, newValue in
                if let image = newValue {
                    saveDailyPhoto(image)
                }
            }
        }
    }

    private func saveDailyPhoto(_ image: UIImage) {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        let mealId = UUID().uuidString
        let mealName = "Daily Photo"

        guard let imageData = image.compressedData(quality: 0.8) else {
            isSaving = false
            errorMessage = "Could not process photo. Please try again."
            return
        }

        let filename = MealImageManager.shared.saveMealPhoto(imageData, mealId: mealId, mealName: mealName)

        let cachedItem = CachedMeal.CachedMealItem(
            name: mealName,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            sugar: 0,
            portionSize: nil
        )

        let cachedMeal = CachedMeal(
            id: mealId,
            timestamp: Date(),
            items: [cachedItem],
            totalCalories: 0,
            totalProtein: 0,
            totalCarbs: 0,
            totalFat: 0,
            totalSugar: 0,
            mealType: "snack",
            synced: true
        )

        LocalMealCache.shared.addMeal(cachedMeal)

        let loggedMealItem = MealItem(
            name: mealName,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            sugar: 0,
            portionSize: nil,
            quantity: nil
        )

        let loggedMeal = LoggedMeal(
            id: mealId,
            timestamp: Date(),
            mealType: .snack,
            items: [loggedMealItem],
            totalCalories: 0,
            totalProtein: 0,
            totalCarbs: 0,
            totalFat: 0,
            totalSugar: 0,
            imageUrl: filename.isEmpty ? nil : filename
        )

        LocalDailyLogStore.shared.addMeal(loggedMeal)

        NotificationCenter.default.post(name: NSNotification.Name("MealSaved"), object: nil)

        isSaving = false
        dismiss()
    }
}
