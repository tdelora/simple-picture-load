import SwiftUI

class AppState: ObservableObject {
    @Published var image: UIImage?
    @Published var isCameraButtonPressed: Bool = false
    @Published var isPictureSourceVisible: Bool = true // Initialize picture source visibility

    func loadImage(from source: String) {
        // Logic to load the image from the provided source
    }

    func clearImage() {
        self.image = nil
        self.isPictureSourceVisible = true // Ensure picture source is visible again
    }

    func handleCameraButtonLongPress() {
        self.isCameraButtonPressed = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            if self.isCameraButtonPressed {
                self.clearImage() 
                self.isCameraButtonPressed = false
            }
        }
    }
}