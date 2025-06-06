import SwiftUI
import MapKit
import CoreLocation

func uploadImage(_ imageData: Data, fileName: String = "photo.jpg") {
    let url = URL(string: "http://localhost:8080/upload-file")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()

    // Add image data
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n".data(using: .utf8)!)

    // Close boundary
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)

    request.httpBody = body

    // Upload task
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Upload error: \(error)")
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("No HTTP response.")
            return
        }

        print("Upload finished with status: \(httpResponse.statusCode)")
    }.resume()
}


struct ContentView: View {
    // MARK: – State / Models
    @StateObject private var locationManager   = LocationManager()
    @StateObject private var decodedVM         = DecodedPlacesViewModel()
    @StateObject private var iconLoader        = CategoryIconLoader()
    @StateObject private var webSocketManager  = WebSocketManager()

    @State private var isAdmin = true
    @State private var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.78, longitude: 6.9),
            span:  MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    // MARK: – Gameplay / Camera
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    private let captureRadius: Double = 100

    @State private var showCapturePopup = false
    @State private var placeToCapture: DecodedPlace?
    @State private var showQuiz = false
    @State private var quiz: Quiz? = nil
    @State private var loadingQuiz = false
    @State private var skippedPlaces = Set<String>()

    private var capturedCount: Int { decodedVM.places.filter(\.captured).count }
    private var totalCount:    Int { decodedVM.places.count }
    private var capturedNames: [String] { decodedVM.places.filter(\.captured).map(\.name) }

    // MARK: – Body
    var body: some View {
        ZStack(alignment: .top) {
            if isAdmin {
                AdminMapView(
                    places: $decodedVM.places,
                    region: $region,
                    isAdmin: true
                )
            } else {
                Map(position: $region) {
                    ForEach(decodedVM.places) { place in
                        Annotation(place.name, coordinate: place.clCoordinate) {
                            VStack(spacing: 0) {
                                CategoryIconView(
                                    categoryID: place.category_id,
                                    iconName:   place.iconName
                                )
                                .foregroundColor(place.captured ? .green : .blue)
                            }
                        }
                    }
                    UserAnnotation()
                }
                .ignoresSafeArea()
            }

            // Capture popup
            if let place = placeToCapture, showCapturePopup {
                CapturePopup(
                    place: place,
                    onClose: {
                        skippedPlaces.insert(place.name)
                        showCapturePopup = false
                    },
                    onCapture: {
                        showCapturePopup = false
                        loadingQuiz = true
                        quiz = nil
                        showQuiz = true
                        Task {
                            await QuizService.handleQuizForPlace(
                                place,
                                setLoading: { self.loadingQuiz = $0 },
                                setQuiz:    { self.quiz = $0 }
                            )
                        }
                    }
                )
            }

            GameOverlayView(
                capturedCount: capturedCount,
                totalCount:    totalCount,
                capturedPlaces: capturedNames
            )

//            UserProfile(username: "Test User", lvl: 12, capturedPlaces: capturedNames)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showCamera = true
                    }) {
                        Image(systemName: "camera")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    Spacer()
                }
                .padding(.bottom, 30)
            }
            .sheet(isPresented: $showCamera, onDismiss: {
                if let image = capturedImage,
                   let imageData = image.jpegData(compressionQuality: 0.8) {
                    uploadImage(imageData)
                }
            }) {
                CameraView(image: $capturedImage)
            }

            if let last = decodedVM.places.last(where: \.captured) {
                VStack {
                    Spacer()
                    Text("🏆 \(last.name) captured!")
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.bottom, 40)
                }
                .transition(.scale)
                .animation(.easeIn, value: capturedCount)
            }
        }

        // Quiz screen
        .fullScreenCover(isPresented: $showQuiz) {
            ZStack {
                if loadingQuiz {
                    VStack {
                        Spacer()
                        ProgressView("Loading Quiz…")
                        Button("Close") {
                            loadingQuiz = false
                            showQuiz = false
                        }
                        .padding(.top, 12)
                        Spacer()
                    }
                } else if let quiz,
                          let capturingPlace = placeToCapture {
                    QuizView(quiz: quiz, place: capturingPlace) { passed in
                        if passed {
                            decodedVM.markCaptured(capturingPlace.id)
                            Task { await decodedVM.capturePlace(id: capturingPlace.id) }
                        } else {
                            skippedPlaces.insert(capturingPlace.name)
                        }
                        loadingQuiz = false
                        showQuiz = false
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("No quiz loaded.")
                        Button("Close") {
                            loadingQuiz = false
                            showQuiz = false
                        }
                        Spacer()
                    }
                }
            }
            .background(Color.white.opacity(0.98).ignoresSafeArea())
        }

        // Location update logic
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { userLocation in
            if !showQuiz && !showCapturePopup {
                if let nearby = decodedVM.places.first(where: { place in
                    let d = userLocation.distance(
                        from: CLLocation(latitude: place.latitude, longitude: place.longitude)
                    )
                    return d < captureRadius &&
                        !skippedPlaces.contains(place.name) &&
                        !place.captured
                }) {
                    placeToCapture = nearby
                    showCapturePopup = true
                } else {
                    showCapturePopup = false
                }
            }
        }

        // Startup tasks
        .task {
            await iconLoader.fetchIcons()
            await decodedVM.fetchPlaces(iconMapping: iconLoader.mapping)
            webSocketManager.connect()
        }

        .onDisappear {
            webSocketManager.disconnect()
        }
    }
}

struct C_Previews: PreviewProvider {
    static var previews: some View {
        
            ContentView()
                
    }
}
