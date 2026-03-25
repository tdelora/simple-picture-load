// ContentView.swift
// Root SwiftUI view. Displays the loaded image (or a placeholder) and shows
// the PictureSourceView overlay when the motion detector says it should be visible.

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen image area
            Group {
                if let image = appState.loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("No image selected")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .secondarySystemBackground))

            // Picture source view – shown/hidden by motion gestures and app state
            if appState.isPictureSourceVisible {
                PictureSourceView()
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppState())
    }
}
