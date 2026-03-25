// MotionDetector.swift
// Monitors device motion and tells AppState when to show or hide the picture source view.
//
// Show rule:  rotation around X axis in the -Z direction (rotationRate.x spikes negative)
//             while |pitch| < 45° → show view; hide is then locked until |pitch| > 75°.
// Hide rule:  rotation around X axis in the +Z direction (rotationRate.x spikes positive)
//             while |pitch| < 50° → hide view; show is then locked until |pitch| > 75° AND
//             roll < -65°.

import CoreMotion
import Foundation

final class MotionDetector {

    // MARK: - Singleton

    static let shared = MotionDetector()
    private init() {}

    // MARK: - Constants

    private static let updateInterval: TimeInterval = 0.05
    private static let rotationRateThreshold: Double = 2.5    // rad/s – minimum flick speed
    private static let showPitchThreshold: Double    = 45.0   // degrees – |Y| must be below this to show
    private static let hidePitchThreshold: Double    = 50.0   // degrees – |Y| must be below this to hide
    private static let unlockPitchThreshold: Double  = 75.0   // degrees – |Y| must exceed this to unlock
    private static let unlockRollThreshold: Double   = -65.0  // degrees – Z must be below this to re-enable show after a hide

    // MARK: - Private State

    private let motionManager = CMMotionManager()

    /// After a show gesture, hiding is locked until the device pitches past 75°.
    private var hideUnlocked = true
    /// After a hide gesture, showing is locked until pitch > 75° AND roll < -65°.
    private var showUnlocked = true

    // MARK: - Public API

    /// Begin monitoring device motion. `appState` will be updated on the main queue.
    func start(appState: AppState) {
        guard motionManager.isDeviceMotionAvailable else { return }
        guard !motionManager.isDeviceMotionActive  else { return }

        // Mirror the lock state to the current visibility so spurious gestures don't
        // immediately flip the view right after launch.
        hideUnlocked = appState.isPictureSourceVisible
        showUnlocked = !appState.isPictureSourceVisible

        motionManager.deviceMotionUpdateInterval = Self.updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self, weak appState] motion, _ in
            guard let self, let motion, let appState else { return }
            self.process(motion: motion, appState: appState)
        }
    }

    /// Stop monitoring device motion.
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - Private

    private func process(motion: CMDeviceMotion, appState: AppState) {
        let rotX        = motion.rotationRate.x
        let pitchDeg    = motion.attitude.pitch * 180.0 / .pi
        let rollDeg     = motion.attitude.roll  * 180.0 / .pi

        // --- Unlock transitions ---

        // Unlock hiding once |pitch| exceeds 75° (after a show gesture)
        if !hideUnlocked && abs(pitchDeg) > Self.unlockPitchThreshold {
            hideUnlocked = true
        }

        // Unlock showing once |pitch| exceeds 75° AND roll < -65° (after a hide gesture)
        if !showUnlocked
            && abs(pitchDeg) > Self.unlockPitchThreshold
            && rollDeg < Self.unlockRollThreshold {
            showUnlocked = true
        }

        // --- Gesture detection ---

        // Show: fast negative rotation-X flick while |pitch| < 45° and show is unlocked
        if rotX < -Self.rotationRateThreshold
            && abs(pitchDeg) < Self.showPitchThreshold
            && showUnlocked {
            hideUnlocked = false            // lock hiding until |pitch| > 75°
            appState.setPictureSourceVisibility(true)
        }
        // Hide: fast positive rotation-X flick while |pitch| < 50° and hide is unlocked
        else if rotX > Self.rotationRateThreshold
            && abs(pitchDeg) < Self.hidePitchThreshold
            && hideUnlocked {
            showUnlocked = false            // lock showing until |pitch| > 75° AND roll < -65°
            appState.setPictureSourceVisibility(false)
        }
    }
}
