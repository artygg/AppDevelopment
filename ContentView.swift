import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var decodedVM = DecodedPlacesViewModel()
    @StateObject private var iconLoader = CategoryIconLoader()
    @State private var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.78, longitude: 6.9),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    private let captureRadius: Double = 100

    @State private var places: [Place] = [
        Place(name: "Station Emmen", coordinate: CLLocationCoordinate2D(latitude: 52.790453, longitude: 6.899715)),
        Place(name: "Emmerdennen Bos", coordinate: CLLocationCoordinate2D(latitude: 52.794587, longitude: 6.917414)),
        Place(name: "Winkelcentrum De Weiert", coordinate: CLLocationCoordinate2D(latitude: 52.782382, longitude: 6.894363)),
        Place(name: "NHL Stenden Emmen", coordinate: CLLocationCoordinate2D(latitude: 52.778150, longitude: 6.911960)),
        Place(name: "Danackers 70", coordinate: CLLocationCoordinate2D(latitude: 52.780455, longitude: 6.94272)),
    ]

    // Quiz and popup state
    @State private var showCapturePopup: Bool = false
    @State private var placeToCapture: DecodedPlace?
    @State private var showQuiz: Bool = false
    @State private var quiz: Quiz? = nil
    @State private var loadingQuiz: Bool = false
    @State private var skippedPlaces = Set<String>()

    // Captured stats
    private var capturedCount: Int { places.filter { $0.isCaptured }.count }
    private var totalCount: Int { places.count }
    private var capturedNames: [String] { places.filter { $0.isCaptured }.map { $0.name } }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $region) {
                // Local game places
                ForEach(places) { place in
                    Marker(place.name, coordinate: place.coordinate)
                        .tint(place.isCaptured ? .green : .blue)
                }
                // Backend places with icons
                ForEach(decodedVM.places) { place in
                    Annotation(place.name, coordinate: CLLocationCoordinate2D(
                        latitude: place.coordinate.latitude,
                        longitude: place.coordinate.longitude
                    )) {
                        VStack(spacing: 0) {
                            CategoryIconView(categoryID: place.category_id, mapping: iconLoader.mapping)
                                .foregroundColor(.blue)
                            Text(place.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                        }
                    }
                }
                UserAnnotation()
            }
            .ignoresSafeArea()

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
            if let last = places.last(where: { $0.isCaptured }) {
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
        // Quiz fullscreen cover
        .fullScreenCover(isPresented: $showQuiz) {
            ZStack {
                if loadingQuiz {
                    VStack {
                        Spacer()
                        ProgressView("Loading Quiz...")
                        Button("Close") {
                            loadingQuiz = false
                            showQuiz = false
                        }
                        .padding(.top, 12)
                        Spacer()
                    }
                } else if let quiz = quiz, let capturingPlace = placeToCapture {
                    QuizView(quiz: quiz, place: capturingPlace) { _ in
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
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { userLocation in
            // Local places (existing logic)
            for index in places.indices where !places[index].isCaptured {
                let distance = userLocation.distance(
                    from: CLLocation(
                        latitude: places[index].coordinate.latitude,
                        longitude: places[index].coordinate.longitude
                    )
                )
                if distance < captureRadius {
                    places[index].isCaptured = true
                }
            }
            // Backend places: check proximity for popup (show only one at a time)
            if !showQuiz && !showCapturePopup {
                if let nearby = decodedVM.places.first(where: { place in
                    let d = userLocation.distance(
                        from: CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                    )
                    return d < captureRadius && !skippedPlaces.contains(place.name)
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
            await decodedVM.fetchPlaces()
        }
    }
}
