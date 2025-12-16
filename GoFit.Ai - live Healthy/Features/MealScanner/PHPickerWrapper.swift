import SwiftUI
import PhotosUI

struct PHPickerWrapper: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var filter: PHPickerFilter = .images
    var selectionLimit: Int = 1

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var conf = PHPickerConfiguration(photoLibrary: .shared())
        conf.filter = filter
        conf.selectionLimit = selectionLimit
        let picker = PHPickerViewController(configuration: conf)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerWrapper
        init(_ parent: PHPickerWrapper) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first else { return }
            if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
                item.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let ui = image as? UIImage { self.parent.image = ui }
                    }
                }
            }
        }
    }
}
