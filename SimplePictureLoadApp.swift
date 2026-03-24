import SwiftUI

@main
struct SimplePictureLoadApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: $appState)
        }
    }
}

class AppState: ObservableObject {
    // Add your app state properties and methods here
}