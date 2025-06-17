import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    // MARK: – State / Models
    @StateObject private var locationManager   = LocationManager()
    @StateObject private var decodedVM         = DecodedPlacesViewModel()
    @StateObject private var iconLoader        = CategoryIconLoader()
    @StateObject private var webSocketManager  = WebSocketManager()
    @AppStorage("mineCount") private var mineCount: Int = 0

    @State private var showImageSheet = false
    @State private var retrievedImage: UIImage? = nil
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

    private let currentUser = "player1"

    @State private var ownerQuiz: Quiz?
    @State private var showOwnerQuiz = false

    private var capturedCount: Int { decodedVM.places.filter(\.captured).count }
    private var totalCount:    Int { decodedVM.places.count }
    private var capturedNames: [String] { decodedVM.places.filter(\.captured).map(\.name) }

    func fetchImage(for placeID: Int) {
        ImageService.fetchImage(for: placeID) { image in
            self.retrievedImage = image
            self.showImageSheet = true
        }
    }

    private func annotationTapped(_ place: DecodedPlace) {
        guard place.captured, place.user_captured == currentUser else { return }
        Task {
            if let q = await QuizService.fetchQuiz(for: place.name) {
                ownerQuiz   = q
                showOwnerQuiz = true
            }
        }
    }

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
                                .onTapGesture { annotationTapped(place) }

                                Text(place.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
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
                capturedPlaces: capturedNames,
                mineCount:     mineCount
            )

            SideButtonsView(
                fetchImage: { fetchImage(for: 1) },
                openCamera: { showCamera = true }
            )

            .sheet(isPresented: $showCamera, onDismiss: {
                if let image = capturedImage,
                   let imageData = image.jpegData(compressionQuality: 0.8) {
                    ImageService.uploadImage(imageData)
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
                    QuizView(
                        quiz: quiz,
                        place: capturingPlace,
                        onDismiss: { passed in
                            if passed {
                                decodedVM.markCaptured(capturingPlace.id)
                                mineCount += 1
                                Task {
                                    if let newQuiz = await decodedVM.capturePlace(
                                        id: capturingPlace.id,
                                        user: currentUser
                                    ) {
                                        ownerQuiz    = newQuiz
                                        showOwnerQuiz = true
                                    }
                                }
                            } else {
                                skippedPlaces.insert(capturingPlace.name)
                            }
                            loadingQuiz = false
                            showQuiz = false
                        },
                        currentUser: currentUser
                    )
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
        .sheet(isPresented: $showImageSheet) {
            if let image = retrievedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            } else {
                Text("Failed to load image.")
            }
        }
        .sheet(isPresented: $showOwnerQuiz) {
            if let q = ownerQuiz {
                OwnerQuizView(
                    mineCount: $mineCount,
                    quiz: q
                ) {
                    showOwnerQuiz = false
                }
            }
        }
    }
}

struct C_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
