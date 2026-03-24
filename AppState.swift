import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var loadedImage: UIImage?
    @Published var isPictureSourceVisible: Bool = false

    private let imageKey = "loadedImage"
    private let visibilityKey = "isPictureSourceVisible"

    init() {
        self.loadState()
    }

    private func loadState() {
        if let imageData = UserDefaults.standard.data(forKey: imageKey) {
            self.loadedImage = UIImage(data: imageData)
        }
        self.isPictureSourceVisible = UserDefaults.standard.bool(forKey: visibilityKey)
    }

    func updateImage(_ image: UIImage?) {
        self.loadedImage = image
        if let image = image, let data = image.pngData() {
            UserDefaults.standard.set(data, forKey: imageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: imageKey)
        }
    }

    func togglePictureSourceVisibility() {
        isPictureSourceVisible.toggle()
        UserDefaults.standard.set(isPictureSourceVisible, forKey: visibilityKey)
    }
}