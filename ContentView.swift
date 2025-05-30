//

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
    
    private let captureRadius: Double = 100
    
    @State private var showCapturePopup = false
    @State private var placeToCapture: DecodedPlace?
    @State private var showQuiz = false
    @State private var quiz: Quiz? = nil
    @State private var loadingQuiz = false
    @State private var skippedPlaces = Set<String>()
    
    private var capturedCount: Int { decodedVM.places.filter(\.isCaptured).count }
    private var totalCount: Int     { decodedVM.places.count }
    private var capturedNames: [String] {
        decodedVM.places.filter(\.isCaptured).map(\.name)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $region) {
                ForEach(decodedVM.places) { place in
                    Annotation(place.name, coordinate: place.clCoordinate) {
                        VStack(spacing: 0) {
                            CategoryIconView(categoryID: place.category_id,
                                             mapping: iconLoader.mapping)
                                .foregroundColor(place.isCaptured ? .green : .blue)
                            Text(place.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                        }
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
            
            if let last = decodedVM.places.last(where: \.isCaptured) {
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
                } else if let quiz = quiz, let capturingPlace = placeToCapture {
                    QuizView(quiz: quiz, place: capturingPlace) { passed in
                        if passed {
                            decodedVM.markCaptured(capturingPlace.id)
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
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { userLocation in
            for idx in decodedVM.places.indices where !decodedVM.places[idx].isCaptured {
                let d = userLocation.distance(
                    from: CLLocation(latitude: decodedVM.places[idx].coordinate.latitude,
                                     longitude: decodedVM.places[idx].coordinate.longitude)
                )
                if d < captureRadius {
                    decodedVM.places[idx].isCaptured = true
                }
            }
            if !showQuiz && !showCapturePopup {
                if let nearby = decodedVM.places.first(where: { place in
                    let d = userLocation.distance(
                        from: CLLocation(latitude: place.coordinate.latitude,
                                         longitude: place.coordinate.longitude)
                    )
                    return d < captureRadius &&
                           !skippedPlaces.contains(place.name) &&
                           !place.isCaptured
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
            webSocketManager.connect()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }
}
