import SwiftUI
import CoreLocation

struct PlaceDTO: Codable {
    let name: String
    let coordinate: Coordinate
}

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
}

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager error: \(error.localizedDescription)")
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var vm = PlacesViewModel()
    private let captureRadius: Double = 100

    var body: some View {
        ZStack(alignment: .top) {
            MapboxViewWrapper(places: $vm.places, userLocation: $locationManager.lastLocation)
                .edgesIgnoringSafeArea(.all)

            GameOverlayView(
                capturedCount: vm.capturedCount,
                totalCount: vm.totalCount,
                capturedPlaces: vm.capturedNames
            )

            UserProfile(username: "Test User", lvl: 12, capturedPlaces: vm.capturedPlaces)

            if let last = vm.places.last(where: { $0.isCaptured }) {
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
                .animation(.easeIn, value: vm.capturedCount)
            }
        }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { userLocation in
            for index in vm.places.indices where !vm.places[index].isCaptured {
                let distance = userLocation.distance(
                    from: CLLocation(
                        latitude: vm.places[index].coordinate.latitude,
                        longitude: vm.places[index].coordinate.longitude
                    )
                )
                if distance < captureRadius {
                    vm.places[index].isCaptured = true
                }
            }
        }
        .task { await vm.fetchPlaces() }
    }
}


@MainActor
class PlacesViewModel: ObservableObject {
    @Published var places: [Place] = []
    private let urlString = "http://localhost:8080/places"

    var capturedCount: Int {
        places.filter { $0.isCaptured }.count
    }

    var totalCount: Int {
        places.count
    }

    var capturedNames: [String] {
        places.filter { $0.isCaptured }.map { $0.name }
    }

    var capturedPlaces: [Place] {
        places.filter { $0.isCaptured }
    }

    func fetchPlaces() async {
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let dtos = try JSONDecoder().decode([PlaceDTO].self, from: data)
            let mapped = dtos.map { dto in
                Place(
                    name: dto.name,
                    coordinate: CLLocationCoordinate2D(
                        latitude: dto.coordinate.latitude,
                        longitude: dto.coordinate.longitude
                    ),
                    placeIcon: "house.fill"
                )
            }

            places = mapped
        } catch {
            print("Fetch failed:", error)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
