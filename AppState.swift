// AppState.swift

// Imports and other code...

class AppState {
    var isImageLoaded: Bool = false
    var motionStateTracking: Bool = false

    // Initializes the AppState
    init() {
        initializePictureSourceVisibility()
    }

    private func initializePictureSourceVisibility() {
        if isImageLoaded {
            // Set visibility of picture source accordingly
        } else {
            // Handle case when no image is loaded
        }
    }

    // Other methods...
}