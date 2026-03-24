import CoreMotion

class MotionDetector {
    private let motionManager = CMMotionManager()
    
    func startMotionDetection() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in  
                guard let unwrappedData = data, error == nil else { return }
                let acceleration = unwrappedData.userAcceleration
                self.detectMotion(acceleration: acceleration)
            }
        }
    }
    
    private func detectMotion(acceleration: CMAcceleration) {
        let threshold: Double = 0.5
        if abs(acceleration.x) > threshold || abs(acceleration.y) > threshold || abs(acceleration.z) > threshold {
            // Device has been shaken
            togglePictureSourceView(shouldShow: true)
        } else {
            togglePictureSourceView(shouldShow: false)
        }
    }
    
    private func togglePictureSourceView(shouldShow: Bool) {
        if shouldShow {
            print("Show Picture Source View")
            // Logic to show the picture source view
        } else {
            print("Hide Picture Source View")
            // Logic to hide the picture source view
        }
    }
    
    func stopMotionDetection() {
        motionManager.stopDeviceMotionUpdates()
    }
}