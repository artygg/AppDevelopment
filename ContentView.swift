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
    @State private var showProfile = false
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

    private var mapboxPlaces: [Place] {
        let mappedPlaces = decodedVM.places.map { dp in
            Place(
                name: dp.name,
                coordinate: dp.clCoordinate,
                placeIcon: dp.iconName,
                isCaptured: dp.captured,
                user_captured: dp.user_captured
            )
        }
        print("MapboxPlaces computed: \(mappedPlaces.count) places")
        return mappedPlaces
    }
    
    @State private var userLocation: CLLocation? = nil

    private var myCaptured: [DecodedPlace] { decodedVM.places.filter { $0.captured && $0.user_captured == currentUser } }
    private var capturedCount: Int { myCaptured.count }
    private var capturedNames: [String] { myCaptured.map(\.name) }
    private var totalCount: Int { decodedVM.places.count }

    var body: some View {
        Group {
            if isAdmin {
                adminView
            } else {
                gameView
            }
        }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { loc in
            userLocation = loc
            if !isAdmin {
                handleLocation(loc)
            }
        }
        .task { await startup() }
        .onDisappear {
            webSocketManager.disconnect()
            decodedVM.stopPeriodicFetching()
        }
    }
    
    // MARK: - Admin View
    var adminView: some View {
        VStack {
            HStack {
                Text("Admin Mode")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Button("Switch to Game") {
                    isAdmin = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
            
            AdminMapView(places: $decodedVM.places)
        }
    }
    
    // MARK: - Game View
    var gameView: some View {
        ZStack(alignment: .top) {
            mapLayer
            
            if let p = placeToCapture, showCapturePopup {
                capturePopup(for: p)
            }
            
            GameOverlayView(
                capturedCount: capturedCount,
                totalCount:    totalCount,
                capturedPlaces: capturedNames,
                mineCount:     mineCount,
                openBoard:     { showLeaderboard = true }
            )
            
            SideButtonsView(
                fetchImage: { fetchImage(for: 1) },
                openCamera: { showCamera = true },
                openProfile: { showProfile = true }
            )
            
            bannerView
            
            // Admin toggle button (you can remove this if you don't want easy switching)
            VStack {
                HStack {
                    Button("Admin") {
                        isAdmin = true
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .font(.caption)
                    
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.leading, 20)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showQuiz) { quizCover }
        .sheet(isPresented: $showCamera, onDismiss: uploadPhoto) {
            CameraView(image: $capturedImage)
        }
        .sheet(isPresented: $showImageSheet) {
            if let img = retrievedImage {
                Image(uiImage: img).resizable().scaledToFit().padding()
            } else {
                Text("Failed to load image.")
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showOwnerQuiz) {
            if let q = ownerQuiz {
                OwnerQuizView(mineCount: $mineCount, quiz: q) {
                    showOwnerQuiz = false
                }
            }
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView()
        }
    }

    var mapLayer: some View {
        MapboxViewWrapper(
            places: .constant(mapboxPlaces),
            userLocation: $userLocation,
            currentUser: currentUser
        )
        .ignoresSafeArea()
        .onAppear {
            print("MapLayer appeared with \(mapboxPlaces.count) places")
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
                QuizView(quiz: q, place: place) { correct, elapsed in
                    Task { @MainActor in
                        let (captured, newQuiz) =
                          await decodedVM.finishAttempt(placeID: place.id,
                                                        correct: correct,
                                                        elapsed: elapsed)

                        if captured {
                            mineCount += 1
                            showBanner(place)
                            if let nq = newQuiz { openOwnerQuiz(nq) }
                        } else {
                            skippedPlaces.insert(place.name)
                        }

                        loadingQuiz = false
                        showQuiz    = false
                        quiz        = nil
                    }
                }
                .id(q.place_id)
                .environmentObject(decodedVM)
            } else {
                VStack { Spacer(); Text("No quiz."); Spacer() }
            }
        }
        .background(Color.white.opacity(0.98).ignoresSafeArea())
    }
    
    private func openOwnerQuiz(_ quiz: Quiz) {
        ownerQuiz     = quiz
        showOwnerQuiz = true
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

    func fetchImage(for placeID: Int) {
        ImageService.fetchImage(for: placeID) { img in
            retrievedImage = img
            showImageSheet = true
        }
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
            return d < captureRadius && !skippedPlaces.contains(p.name) && p.user_captured != currentUser && !cd
        }) {
            placeToCapture = near
            showCapturePopup = true
        } else {
            showCapturePopup = false
        }
    }

    func startup() async {
        await iconLoader.fetchIcons()
        decodedVM.startPeriodicFetching(iconMapping: iconLoader.mapping)
        webSocketManager.connect()
    }

    func annotationTapped(_ place: DecodedPlace) {
        guard place.user_captured == currentUser else { return }
        Task {
            if let q = await QuizService.fetchQuiz(placeID: place.id) {
                openOwnerQuiz(q)
            }
        }
    }

    func uploadPhoto() {
        if let img = capturedImage, let data = img.jpegData(compressionQuality: 0.8) {
            ImageService.uploadImage(data)
        }
    }

    func quizFinished(_ passed: Bool) {
        guard let target = placeToCapture else { return }
        Task {
            await decodedVM.sendCapture(placeID: target.id, passed: passed)
            await decodedVM.fetchPlaces()
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
}

struct Content_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
