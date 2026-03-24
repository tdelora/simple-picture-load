import SwiftUI

struct ContentView: View {
    @State private var isLoading = false
    @State private var image: Image? = nil
    @State private var imageUrl: String = ""
    @State private var showImageView = false

    var body: some View {
        VStack {
            if showImageView, let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else if isLoading {
                ProgressView()
            } else {
                Text("Enter Image URL:")
                    .font(.headline)
                TextField("URL", text: $imageUrl)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button(action: loadImage) {
                    Text("Load Image")
                }
                .padding()
            }
        }
        .padding()
    }

    private func loadImage() {
        guard let url = URL(string: imageUrl) else { return }
        isLoading = true
        image = nil
        showImageView = false

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async { 
                    self.image = Image(uiImage: uiImage)
                    self.isLoading = false
                    self.showImageView = true
                }
            } else {
                DispatchQueue.main.async { 
                    self.isLoading = false
                }
            }
        }
        task.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}