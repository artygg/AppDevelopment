import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {

    @StateObject private var locationManager  = LocationManager()
    @StateObject private var decodedVM        = DecodedPlacesViewModel()
    @StateObject private var iconLoader       = CategoryIconLoader()
    @StateObject private var webSocketManager = WebSocketManager()


    @AppStorage("mineCount") private var mineCount: Int = 0


    @State private var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.78, longitude: 6.9),
            span:  MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )


    private let captureRadius: Double = 100
    @State private var showCapturePopup = false
    @State private var placeToCapture: DecodedPlace?

    @State private var showQuiz   = false
    @State private var quiz: Quiz?
    @State private var loadingQuiz = false

    @State private var skippedPlaces = Set<String>()

    @State private var ownerQuiz: Quiz?
    @State private var showOwnerQuiz = false

  
    private var capturedCount: Int { decodedVM.places.filter(\.captured).count }
    private var totalCount: Int    { decodedVM.places.count }
    private var capturedNames: [String] {
        decodedVM.places.filter(\.captured).map(\.name)
    }


    private let currentUser = "player1"

 
    private func annotationTapped(_ place: DecodedPlace) {
        guard place.captured,
              place.user_captured == currentUser else { return }

        Task {
            if let q = await QuizService.fetchQuiz(for: place.name) {
                ownerQuiz   = q
                showOwnerQuiz = true
            }
        }
    }

  
    var body: some View {
        ZStack(alignment: .top) {

           
            Map(position: $region) {
                ForEach(decodedVM.places) { place in
                    Annotation(place.name, coordinate: place.clCoordinate) {
                        VStack(spacing: 0) {
                            CategoryIconView(categoryID: place.category_id,
                                             iconName: place.iconName)
                                .foregroundColor(place.iconColor)
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
                } else if let quiz = quiz,
                          let capturingPlace = placeToCapture {

                   
                    QuizView(
                        quiz:  quiz,
                        place: capturingPlace,
                        onDismiss: { captured in
                            if captured {
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
                            showQuiz    = false
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

   
        .sheet(isPresented: $showOwnerQuiz) {
            if let q = ownerQuiz {
                OwnerQuizView(mineCount: $mineCount,
                              quiz: q) {
                    showOwnerQuiz = false
                }
            }
        }

       
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { userLoc in
            if !showQuiz && !showCapturePopup {
                if let nearby = decodedVM.places.first(where: { place in
                    let d = userLoc.distance(from: .init(latitude: place.latitude,
                                                         longitude: place.longitude))
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
        .onDisappear { webSocketManager.disconnect() }
    }
}
