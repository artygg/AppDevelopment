import SwiftUI

struct CapturePopup: View {
    let place: DecodedPlace
    let onClose: () -> Void
    let onCapture: () -> Void

    @State private var image: Image? = nil
    @State private var imageLoaded = false

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 18) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)

                VStack(spacing: 8) {
                    if let image = image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(12)
                            .shadow(radius: 5)

                        Text("Photo made by previous user")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if !imageLoaded {
                        ProgressView()
                            .frame(height: 200)
                    } else {
                        // Placeholder
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .foregroundColor(.gray)
                            .opacity(0.5)

                        Text("Photo made by previous user")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text("You can capture \"\(place.name)\"")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Button("Capture", action: onCapture)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .shadow(radius: 12)
            .padding(.horizontal, 36)
            Spacer().frame(height: 200)
        }
        .transition(.scale)
        .zIndex(10)
        .onAppear {
            fetchImage()
        }
    }

    private func fetchImage() {
        guard let url = URL(string: "\(Config.apiURL)/get-image?place_id=\(place.id)") else {
            imageLoaded = true
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            imageLoaded = true
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = Image(uiImage: uiImage)
                }
            } else {
                print("Image fetch error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
}
