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

    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
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
    private var buttonsVisible = true

    // MARK: - Lifecycle

    override func viewDidLoad() {
        // Added comment to practice commits and pushes to Github.
        // Second try at push
        // Third Try.
        super.viewDidLoad()
        title = "Simple Picture Load"
        view.backgroundColor = .systemBackground
        setupLayout()
        setupActions()
        startMotionUpdates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopDeviceMotionUpdates()
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
        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            // gravity.z in device frame represents how much the screen faces away from the user:
            //   > 0.3 : device tilted back / screen facing away (X-axis rotated in -Z direction) → hide buttons
            //  <= 0.3 : device upright or screen facing toward user (X-axis rotated in +Z direction) → show buttons
            self.updateButtonVisibility(visible: motion.gravity.z <= 0.3)
        }
    }

    private func updateButtonVisibility(visible: Bool) {
        guard visible != buttonsVisible else { return }
        buttonsVisible = visible
        if visible { buttonStack.isHidden = false }
        UIView.animate(withDuration: 0.3, animations: {
            self.buttonStack.alpha = visible ? 1.0 : 0.0
        }, completion: { _ in
            self.buttonStack.isHidden = !visible
        })
    }

    // MARK: - Helpers

    private func displayImage(_ image: UIImage) {
        imageView.image = image
        placeholderLabel.isHidden = true
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
