import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager  = LocationManager()
    @StateObject private var decodedVM        = DecodedPlacesViewModel()
    @StateObject private var iconLoader       = CategoryIconLoader()
    @StateObject private var webSocketManager = WebSocketManager()
    @AppStorage("username")  private var currentUser: String = "player1"
    @AppStorage("mineCount") private var mineCount: Int = 0

    @State private var isAdmin = true
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showImageSheet = false
    @State private var retrievedImage: UIImage?
    @State private var showLeaderboard = false

    @State private var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: .init(latitude: 52.78, longitude: 6.90),
            span:  .init(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    private let captureRadius: Double = 100
    @State private var showCapturePopup = false
    @State private var placeToCapture: DecodedPlace?
    @State private var skippedPlaces   = Set<String>()

    @State private var showQuiz = false
    @State private var loadingQuiz = false
    @State private var quiz: Quiz?

    @State private var ownerQuiz: Quiz?
    @State private var showOwnerQuiz = false

    @State private var bannerPlace: DecodedPlace?
    @State private var bannerTask: Task<Void, Never>?

    private var myCaptured: [DecodedPlace] { decodedVM.places.filter { $0.captured && $0.user_captured == currentUser } }
    private var capturedCount: Int { myCaptured.count }
    private var capturedNames: [String] { myCaptured.map(\.name) }
    private var totalCount: Int { decodedVM.places.count }

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            if let p = placeToCapture, showCapturePopup { capturePopup(for: p) }
            GameOverlayView(
                capturedCount: capturedCount,
                totalCount:    totalCount,
                capturedPlaces: capturedNames,
                mineCount:     mineCount,
                openBoard:     { showLeaderboard = true }
            )
            SideButtonsView(
                fetchImage: { fetchImage(for: 1) },
                openCamera: { showCamera = true }
            )
            bannerView
        }
        .fullScreenCover(isPresented: $showQuiz) { quizCover }
        .sheet(isPresented: $showCamera, onDismiss: uploadPhoto) { CameraView(image: $capturedImage) }
        .sheet(isPresented: $showImageSheet) {
            if let img = retrievedImage {
                Image(uiImage: img).resizable().scaledToFit().padding()
            } else { Text("Failed to load image.") }
        }
        .sheet(isPresented: $showOwnerQuiz) {
            if let q = ownerQuiz {
                OwnerQuizView(mineCount: $mineCount, quiz: q) { showOwnerQuiz = false }
            }
        }
        .sheet(isPresented: $showLeaderboard) { LeaderboardView() }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }, perform: handleLocation)
        .task { await startup() }
        .onDisappear { webSocketManager.disconnect() }
    }
}

private extension ContentView {

    var mapLayer: some View {
        Group {
            if isAdmin {
                AdminMapView(places: $decodedVM.places, region: $region, isAdmin: true)
            } else {
                Map(position: $region) {
                    ForEach(decodedVM.places) { place in
                        Annotation(place.name, coordinate: place.clCoordinate) {
                            VStack(spacing: 0) {
                                CategoryIconView(categoryID: place.category_id, iconName: place.iconName)
                                    .foregroundColor(place.iconColor(for: currentUser))
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
        }
    }

    func capturePopup(for place: DecodedPlace) -> some View {
        CapturePopup(
            place: place,
            onClose: {
                skippedPlaces.insert(place.name)
                showCapturePopup = false
            },
            onCapture: {
                showCapturePopup = false
                loadingQuiz = true
                showQuiz = true
                Task {
                    await QuizService.handleQuizForPlace(
                        place,
                        setLoading: { loadingQuiz = $0 },
                        setQuiz:    { quiz = $0 }
                    )
                }
            }
        )
    }

    var quizCover: some View {
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
            } else if let q = quiz, let place = placeToCapture {
                QuizView(quiz: q, place: place, onDismiss: quizFinished(_:), currentUser: currentUser)
            } else {
                VStack { Spacer(); Text("No quiz."); Spacer() }
            }
        }
        .background(Color.white.opacity(0.98).ignoresSafeArea())
    }

    func quizFinished(_ passed: Bool) {
        guard let target = placeToCapture else { return }
        Task {
            await decodedVM.sendCapture(placeID: target.id, passed: passed)
            await decodedVM.fetchPlaces(iconMapping: iconLoader.mapping)
        }
        if passed {
            decodedVM.markCaptured(target.id)
            mineCount += 1
            showBanner(target)
        } else {
            skippedPlaces.insert(target.name)
        }
        loadingQuiz = false
        showQuiz = false
        quiz = nil
    }

    var bannerView: some View {
        Group {
            if let p = bannerPlace {
                VStack {
                    Spacer()
                    Text("🏆 \(p.name) captured!")
                        .padding()
                        .background(.green.opacity(0.85))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: bannerPlace != nil)
    }

    func showBanner(_ place: DecodedPlace) {
        bannerPlace = place
        bannerTask?.cancel()
        bannerTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            bannerPlace = nil
        }
    }

    func handleLocation(_ loc: CLLocation) {
        guard !showQuiz && !showCapturePopup else { return }
        if let near = decodedVM.places.first(where: { p in
            let d = loc.distance(from: .init(latitude: p.latitude, longitude: p.longitude))
            let cd = p.cooldown_until != nil && p.cooldown_until! > Date()
            return d < captureRadius && !skippedPlaces.contains(p.name) && !p.captured && !cd
        }) {
            placeToCapture = near
            showCapturePopup = true
        } else {
            showCapturePopup = false
        }
    }

    func startup() async {
        await iconLoader.fetchIcons()
        await decodedVM.fetchPlaces(iconMapping: iconLoader.mapping)
        webSocketManager.connect()
    }

    func annotationTapped(_ place: DecodedPlace) {
        guard place.captured, place.user_captured == currentUser else { return }
        Task {
            if let q = await QuizService.fetchQuiz(for: place.name) {
                ownerQuiz = q
                showOwnerQuiz = true
            }
        }
    }

    func fetchImage(for placeID: Int) {
        ImageService.fetchImage(for: placeID) { img in
            retrievedImage = img
            showImageSheet = true
        }
    }

    func uploadPhoto() {
        if let img = capturedImage, let data = img.jpegData(compressionQuality: 0.8) {
            ImageService.uploadImage(data)
        }
    }
}
