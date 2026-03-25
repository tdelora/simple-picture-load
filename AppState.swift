// AppState.swift
// Central observable state for the app.
//
// Responsibilities:
//  - Hold the currently loaded UIImage and persist it to the Documents directory.
//  - Track whether the picture source view is currently visible.
//  - Manage the 7-second long-press timer for the camera button.
//
// Startup behaviour:
//  - If a saved image exists the picture source view starts hidden.
//  - If no saved image exists the picture source view starts visible.

import UIKit
import Combine

final class AppState: ObservableObject {

    // MARK: - Published State

    /// The currently loaded image, or nil if none is loaded.
    @Published private(set) var loadedImage: UIImage?

    /// Whether the picture source view (camera / photo-library buttons) is visible.
    @Published private(set) var isPictureSourceVisible: Bool

    // MARK: - Private

    private static let savedImageFilename = "savedImage.jpg"

    private var savedImageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.savedImageFilename)
    }

    /// Timer that fires after 7 seconds of continuous camera-button press.
    private var longPressTimer: Timer?

    /// True from the moment the 7-second long-press fires until the press ends.
    private(set) var longPressDidClearImage = false

    // MARK: - Init

    init() {
        // Initialize stored properties first so `savedImageURL` (a computed property on self)
        // is accessible in phase 2.
        self.loadedImage = nil
        self.isPictureSourceVisible = true

        // Phase 2: reload any previously saved image and set initial visibility.
        let saved = AppState.loadImage(from: savedImageURL)
        self.loadedImage = saved
        // Show the source picker at startup only when there is no image to display.
        self.isPictureSourceVisible = (saved == nil)
    }

    // MARK: - Image Management

    /// Store a newly captured or selected image and hide the picture source view.
    func updateImage(_ image: UIImage) {
        loadedImage = image
        isPictureSourceVisible = false
        persistImage(image)
    }

    /// Remove the loaded image and show the picture source view.
    func clearImage() {
        loadedImage = nil
        isPictureSourceVisible = true
        try? FileManager.default.removeItem(at: savedImageURL)
    }

    // MARK: - Picture Source Visibility

    /// Explicitly set the visibility of the picture source view (called by MotionDetector).
    func setPictureSourceVisibility(_ visible: Bool) {
        isPictureSourceVisible = visible
    }

    // MARK: - Long Press Timer (Camera Button)

    /// Call when the user begins pressing the camera button.
    func cameraButtonPressStarted() {
        longPressDidClearImage = false
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false) { [weak self] _ in
            self?.longPressDidClearImage = true
            self?.clearImage()
        }
    }

    /// Call when the user lifts off the camera button.
    /// Returns `true` if the camera should open, `false` if the press cleared the image.
    @discardableResult
    func cameraButtonPressEnded() -> Bool {
        longPressTimer?.invalidate()
        longPressTimer = nil
        let shouldOpenCamera = !longPressDidClearImage
        longPressDidClearImage = false
        return shouldOpenCamera
    }

    // MARK: - Private Helpers

    private func persistImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        do {
            try data.write(to: savedImageURL)
        } catch {
            print("AppState: Failed to save image – \(error.localizedDescription)")
        }
    }

    private static func loadImage(from url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}
