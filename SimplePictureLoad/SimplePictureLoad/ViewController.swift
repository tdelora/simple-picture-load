import UIKit
import PhotosUI
import CoreMotion

class ViewController: UIViewController {

    // MARK: - UI Elements

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "No image selected"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // buttonStack starts hidden; visibility is controlled by motion gestures and app state
    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
        stack.alpha = 0.0
        return stack
    }()

    private let cameraButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Take Photo"
        config.image = UIImage(systemName: "camera.fill")
        config.imagePadding = 8
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let libraryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Photo Library"
        config.image = UIImage(systemName: "photo.on.rectangle")
        config.imagePadding = 8
        config.cornerStyle = .medium
        config.baseBackgroundColor = .systemGreen
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Motion

    private let motionManager = CMMotionManager()
    private var buttonsVisible = false

    // Locking state: after a show gesture, hiding is locked until Y > 75°.
    // After a hide gesture, showing is locked until Y > 75° AND Z < -65°.
    private var hideUnlocked = true
    private var showUnlocked = true

    // Thresholds for motion gesture detection
    private static let rotationRateThreshold: Double = 2.5   // rad/s
    private static let showPitchThreshold: Double    = 45.0  // degrees – Y must be < this to trigger show
    private static let hidePitchThreshold: Double    = 50.0  // degrees – Y must be < this to trigger hide
    private static let unlockPitchThreshold: Double  = 75.0  // degrees – Y must exceed this to unlock
    private static let unlockRollThreshold: Double   = -65.0 // degrees – Z must be < this to unlock show (after hide gesture)

    // MARK: - Persistence

    private var savedImageURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("savedImage.jpg")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Simple Picture Load"
        view.backgroundColor = .systemBackground
        setupLayout()
        setupActions()
        restoreState()
        startMotionUpdates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - State Restoration

    private func restoreState() {
        if let image = loadSavedImage() {
            // Image exists: display it and keep picture source view hidden
            displayImage(image, save: false)
        } else {
            // No image: show the picture source view
            setButtonsVisible(true, animated: false)
        }
    }

    // MARK: - Persistence Helpers

    private func saveImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        do {
            try data.write(to: savedImageURL)
        } catch {
            print("SimplePictureLoad: Failed to save image – \(error.localizedDescription)")
        }
    }

    private func loadSavedImage() -> UIImage? {
        guard FileManager.default.fileExists(atPath: savedImageURL.path) else { return nil }
        return UIImage(contentsOfFile: savedImageURL.path)
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(imageView)
        imageView.addSubview(placeholderLabel)
        view.addSubview(buttonStack)
        buttonStack.addArrangedSubview(cameraButton)
        buttonStack.addArrangedSubview(libraryButton)

        NSLayoutConstraint.activate([
            // Image view fills the full safe area; button stack overlays at the bottom
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            // Placeholder label centered in the image view
            placeholderLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),

            // Button stack overlaid at the bottom of the safe area
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            buttonStack.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions

    private func setupActions() {
        cameraButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
        libraryButton.addTarget(self, action: #selector(openPhotoLibrary), for: .touchUpInside)

        // Long-press gesture on the camera button: holding for 7 seconds clears the loaded
        // image without subsequently launching the camera app (cancelsTouchesInView = true
        // prevents the touchUpInside from firing after the gesture is recognised).
        let longPress = UILongPressGestureRecognizer(target: self,
                                                     action: #selector(cameraButtonLongPress(_:)))
        longPress.minimumPressDuration = 7.0
        cameraButton.addGestureRecognizer(longPress)
    }

    @objc private func cameraButtonLongPress(_ gesture: UILongPressGestureRecognizer) {
        // .began fires exactly once, when the minimum press duration has elapsed.
        if gesture.state == .began {
            clearLoadedImage()
        }
    }

    @objc private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Camera Unavailable",
                      message: "This device does not have a camera, or camera access is restricted.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func openPhotoLibrary() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Motion

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }

            // rotationRate.x is rotation around the device X axis (positive = top moving away from user)
            let rotX = motion.rotationRate.x
            // attitude.pitch maps to the "Y value" (tilt forward/backward); signed degrees
            let pitchDegrees = motion.attitude.pitch * 180.0 / .pi
            // attitude.roll maps to the "Z value" (tilt sideways); signed degrees
            let rollDegrees  = motion.attitude.roll  * 180.0 / .pi

            // Unlock hiding: once Y exceeds 75° (in either direction) after a show gesture
            if !self.hideUnlocked && abs(pitchDegrees) > Self.unlockPitchThreshold {
                self.hideUnlocked = true
            }

            // Unlock showing: once Y exceeds 75° AND Z < -65° after a hide gesture
            if !self.showUnlocked
                && abs(pitchDegrees) > Self.unlockPitchThreshold
                && rollDegrees < Self.unlockRollThreshold {
                self.showUnlocked = true
            }

            // Show: flick around X axis in -Z direction (rotX spikes negative) with |pitch| < 45°
            // Only fires when the show gesture is currently unlocked
            if rotX < -Self.rotationRateThreshold
                && abs(pitchDegrees) < Self.showPitchThreshold
                && self.showUnlocked {
                self.hideUnlocked = false   // lock hiding until Y > 75°
                self.setButtonsVisible(true)
            }
            // Hide: flick around X axis in +Z direction (rotX spikes positive) with |pitch| < 50°
            // Only fires when the hide gesture is currently unlocked
            else if rotX > Self.rotationRateThreshold
                && abs(pitchDegrees) < Self.hidePitchThreshold
                && self.hideUnlocked {
                self.showUnlocked = false   // lock showing until Y > 75° AND Z < -65°
                self.setButtonsVisible(false)
            }
        }
    }

    private func setButtonsVisible(_ visible: Bool, animated: Bool = true) {
        guard visible != buttonsVisible else { return }
        buttonsVisible = visible
        if visible { buttonStack.isHidden = false }
        let duration = animated ? 0.3 : 0.0
        UIView.animate(withDuration: duration, animations: {
            self.buttonStack.alpha = visible ? 1.0 : 0.0
        }, completion: { _ in
            self.buttonStack.isHidden = !visible
        })
    }

    // MARK: - Helpers

    private func displayImage(_ image: UIImage, save: Bool = true) {
        imageView.image = image
        placeholderLabel.isHidden = true
        if save { saveImage(image) }
        setButtonsVisible(false)
    }

    /// Clears the currently loaded image and shows the picture source view.
    private func clearLoadedImage() {
        imageView.image = nil
        placeholderLabel.isHidden = false
        try? FileManager.default.removeItem(at: savedImageURL)
        setButtonsVisible(true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate (Camera)

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            displayImage(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate (Photo Library)

extension ViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                if let image = object as? UIImage {
                    self?.displayImage(image)
                } else if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
}
