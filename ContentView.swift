import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager   = LocationManager()
    @StateObject private var decodedVM         = DecodedPlacesViewModel()
    @StateObject private var iconLoader        = CategoryIconLoader()
    @StateObject private var webSocketManager  = WebSocketManager()
    
    @State private var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.78, longitude: 6.9),
            span:  MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    @State private var showCamera = false
    @State private var capturedImage: UIImage?

    
    var isAdmin: Bool = true // FOR DEV PURPOSES

    private let captureRadius: Double = 100
    @State private var showCapturePopup = false
    @State private var placeToCapture: DecodedPlace?
    @State private var showQuiz = false
    @State private var quiz: Quiz? = nil
    @State private var loadingQuiz = false
    @State private var skippedPlaces = Set<String>()
    
    private var capturedCount: Int { decodedVM.places.filter(\.captured).count }
    private var totalCount: Int     { decodedVM.places.count }
    private var capturedNames: [String] {
        decodedVM.places.filter(\.captured).map(\.name)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            if isAdmin {
                AdminMapView(
                    places: $vm.places,
                    region: $region,
                    isAdmin: true,
                )
            } else {
                Map(position: $region) {
                    ForEach(vm.places) { place in
                        Marker(place.name, coordinate: place.coordinate)
                            .tint(place.isCaptured ? .green : .blue)
// =======
//             Map(position: $region) {
//                 ForEach(decodedVM.places) { place in
//                     Annotation(place.name, coordinate: place.clCoordinate) {
//                         VStack(spacing: 0) {
//                             CategoryIconView(
//                                 categoryID: place.category_id,
//                                 iconName: place.iconName
//                             )
//                             .foregroundColor(place.captured ? .green : .blue)
//                             Text(place.name)
//                                 .font(.caption2)
//                                 .padding(.horizontal, 6)
//                         }
// >>>>>>> test/merge-main
                    }
                }
                UserAnnotation()
            }
            .ignoresSafeArea()
            
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
                                setQuiz: { self.quiz = $0 }
                            )
                        }
                    }
                )
            }
            
            GameOverlayView(
                capturedCount: capturedCount,
                totalCount: totalCount,
                capturedPlaces: capturedNames
            )
            
// <<<<<<< dev
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
            .sheet(isPresented: $showCamera) {
                CameraView(image: $capturedImage)
            }


            if showCaptureBanner,
               let last = vm.places.last(where: { $0.isCaptured }) {
// =======
//             if let last = decodedVM.places.last(where: \.captured) {
//                 VStack {
//                     Spacer()
//                     Text("🏆 \(last.name) captured!")
//                         .padding()
//                         .background(Color.green.opacity(0.8))
//                         .cornerRadius(10)
//                         .foregroundColor(.white)
//                         .font(.headline)
//                         .padding(.bottom, 40)
//                 }
//                 .transition(.scale)
//                 .animation(.easeIn, value: capturedCount)
//             }
//         }
//         .fullScreenCover(isPresented: $showQuiz) {
//             ZStack {
//                 if loadingQuiz {
//                     VStack {
//                         Spacer()
//                         ProgressView("Loading Quiz…")
//                         Button("Close") {
//                             loadingQuiz = false
//                             showQuiz = false
//                         }
//                         .padding(.top, 12)
//                         Spacer()
//                     }
//                 } else if let quiz = quiz, let capturingPlace = placeToCapture {
//                     QuizView(quiz: quiz, place: capturingPlace) { passed in
//                         if passed {
//                             decodedVM.markCaptured(capturingPlace.id)
//                             Task {
//                                 await decodedVM.capturePlace(id: capturingPlace.id)
//                             }
//                         } else {
//                             skippedPlaces.insert(capturingPlace.name)
//                         }
//                         loadingQuiz = false
//                         showQuiz = false
//                     }
//                 } else {
// >>>>>>> test/merge-main
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
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { userLocation in
            // Only open popup if within radius and not captured/skipped, but DON'T auto-capture!
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
        .task {
            await iconLoader.fetchIcons()
            await decodedVM.fetchPlaces(iconMapping: iconLoader.mapping)
            webSocketManager.connect()
        }
// <<<<<<< dev
        .task { await vm.fetchPlaces()}

    }
}

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
}

@MainActor
class PlacesViewModel: ObservableObject {
    @Published var places: [Place] = []
    private let urlString = "http://172.20.10.2:8080/places"

    func fetchPlaces() async {
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let dtos = try JSONDecoder().decode([PlaceDTO].self, from: data)
            let mapped = dtos.map { dto in
                Place(
                    name: dto.name,
                    coordinate: CLLocationCoordinate2D(
                        latitude:  dto.coordinate.latitude,
                        longitude: dto.coordinate.longitude
                    ),
                    placeIcon:"house.fill"
                )
            }

            places = mapped
        } catch {
            print("Fetch failed:", error)
// =======
//         .onDisappear {
//             webSocketManager.disconnect()
// >>>>>>> test/merge-main
        }
    }
}
