// Updated ContentView.swift to display loaded image

import SwiftUI

struct ContentView: View {
    @State private var image: UIImage? = nil
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
            } else {
                Text("Loading...")
            }
            Text(appState.pictureSource)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .onAppear(perform: loadImage)
    }

    private func loadImage() {
        // Assuming MotionDetector and AppState would provide the necessary functionality to load the image
        // Simulated image loading logic here: Replace with actual loading code.
        MotionDetector.detectImageSource { source in
            self.appState.pictureSource = source
            guard let url = URL(string: source) else { return }
            let data = try? Data(contentsOf: url)
            self.image = data.flatMap { UIImage(data: $0) }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppState())
    }
}