// MotionDetector.swift

import UIKit

class MotionDetector {
    
    let angleThreshold: CGFloat = 30.0 // Adjust the threshold as needed

    func detectMotion(angle: CGFloat) -> Bool {
        // Check if the angle is within the specified threshold
        return abs(angle) < angleThreshold
    }
    
    func updatePictureView(for angle: CGFloat) {
        if detectMotion(angle: angle) {
            // Logic to show the picture source view
            showPictureSourceView()
        } else {
            // Logic to hide the picture source view
            hidePictureSourceView()
        }
    }
    
    private func showPictureSourceView() {
        // Implementation to show the view
        print("Showing picture source view.")
    }
    
    private func hidePictureSourceView() {
        // Implementation to hide the view
        print("Hiding picture source view.")
    }
}