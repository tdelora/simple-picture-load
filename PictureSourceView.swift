import SwiftUI

struct PictureSourceView: View {
    var body: some View {
        VStack {
            Text("Select a Picture Source")
                .font(.headline)
                .padding()

            Button(action: {
                // Action for selecting from the Camera
                print("Camera selected")
            }) {
                Text("Camera")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()

            Button(action: {
                // Action for selecting from the Photo Roll
                print("Photo Roll selected")
            }) {
                Text("Photo Roll")
                    .font(.title)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}

struct PictureSourceView_Previews: PreviewProvider {
    static var previews: some View {
        PictureSourceView()
    }
}