// PictureSourceView.swift
// SwiftUI view that shows "Take Photo" and "Photo Library" buttons.
//
// Long-press behaviour on the camera button:
//   • Holding the camera button for ≥ 7 seconds clears the loaded image.
//   • On release the camera is NOT launched, giving the user a chance to pick
//     from the library or take a fresh photo without navigating away.
//   • A normal tap (< 7 s) opens the camera as expected.

import SwiftUI
import PhotosUI
import UIKit

// MARK: - Camera Picker (UIViewControllerRepresentable)

struct CameraPickerView: UIViewControllerRepresentable {

    var onImagePicked: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImagePicked: onImagePicked) }

    final class Coordinator: NSObject,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {

        let onImagePicked: (UIImage?) -> Void
        init(onImagePicked: @escaping (UIImage?) -> Void) { self.onImagePicked = onImagePicked }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            onImagePicked(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onImagePicked(nil)
        }
    }
}

// MARK: - Photo Library Picker (UIViewControllerRepresentable)

struct PhotoLibraryPickerView: UIViewControllerRepresentable {

    var onImagePicked: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImagePicked: onImagePicked) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {

        let onImagePicked: (UIImage?) -> Void
        init(onImagePicked: @escaping (UIImage?) -> Void) { self.onImagePicked = onImagePicked }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else { onImagePicked(nil); return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async { self?.onImagePicked(object as? UIImage) }
            }
        }
    }
}

// MARK: - Picture Source View

struct PictureSourceView: View {

    @EnvironmentObject var appState: AppState

    @State private var showCamera        = false
    @State private var showPhotoPicker   = false

    var body: some View {
        HStack(spacing: 16) {
            cameraButton
            photoLibraryButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .sheet(isPresented: $showCamera) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                CameraPickerView { image in
                    guard let image else { return }
                    appState.updateImage(image)
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoLibraryPickerView { image in
                guard let image else { return }
                appState.updateImage(image)
            }
        }
    }

    // MARK: Camera button with 7-second long-press to clear the image

    private var cameraButton: some View {
        // `onLongPressGesture(minimumDuration:pressing:perform:)`:
        //   • `pressing` closure receives true when the finger goes down, false when lifted.
        //   • `perform` closure fires exactly once after minimumDuration seconds.
        //
        // By tracking whether `perform` has fired before `pressing` goes false we can
        // decide whether to open the camera on release.
        CameraButtonView { shouldOpenCamera in
            if shouldOpenCamera {
                showCamera = true
            }
        } onClear: {
            appState.clearImage()
        }
    }

    private var photoLibraryButton: some View {
        Button {
            showPhotoPicker = true
        } label: {
            Label("Photo Library", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }
}

// MARK: - Camera Button View
// Isolated so that the long-press + tap state machine is self-contained.

private struct CameraButtonView: View {

    /// Called on release: true = open camera, the gesture finished normally.
    var onRelease: (Bool) -> Void
    /// Called when the 7-second threshold is reached.
    var onClear:   () -> Void

    /// Set to true as soon as the 7-second threshold fires.
    @State private var longPressTriggered = false

    var body: some View {
        Label("Take Photo", systemImage: "camera.fill")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .onLongPressGesture(minimumDuration: 7.0, pressing: { isPressing in
                if !isPressing {
                    // Finger lifted – open camera only when no clear was triggered.
                    let shouldOpenCamera = !longPressTriggered
                    longPressTriggered = false
                    onRelease(shouldOpenCamera)
                }
            }, perform: {
                // 7 seconds elapsed.
                longPressTriggered = true
                onClear()
            })
    }
}

// MARK: - Preview

struct PictureSourceView_Previews: PreviewProvider {
    static var previews: some View {
        PictureSourceView()
            .environmentObject(AppState())
    }
}
