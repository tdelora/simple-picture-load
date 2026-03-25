// SimplePictureLoadApp.swift
// SwiftUI app entry point.
// Creates the shared AppState and starts motion detection on launch.

import SwiftUI

@main
struct SimplePictureLoadApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    MotionDetector.shared.start(appState: appState)
                }
        }
    }
}
