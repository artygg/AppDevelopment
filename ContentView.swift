import SwiftUI
import MapKit
import CoreLocation


struct PlaceDTO: Codable {
  let name: String
  let coordinate: Coordinate
}
struct Coordinate: Codable {
  let latitude: Double
  let longitude: Double
}


struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var vm = PlacesViewModel()
    @State private var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.78, longitude: 6.9),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    private let captureRadius: Double = 100

    @State private var places: [Place] = [
        Place(
            name: "Wildlands Adventure Zoo",
            coordinate: CLLocationCoordinate2D(latitude: 52.780748, longitude: 6.887516),
            placeIcon: "pawprint.fill"
        ),
        Place(
            name: "Station Emmen",
            coordinate: CLLocationCoordinate2D(latitude: 52.790453, longitude: 6.899715),
            placeIcon: "train.side.front.car"
        ),
        Place(
            name: "Rensenpark",
            coordinate: CLLocationCoordinate2D(latitude: 52.785692, longitude: 6.897980),
            placeIcon: "tree.fill"
        ),
        Place(
            name: "Emmerdennen Bos",
            coordinate: CLLocationCoordinate2D(latitude: 52.794587, longitude: 6.917414),
            placeIcon: "leaf.fill"
        ),
        Place(
            name: "Winkelcentrum De Weiert",
            coordinate: CLLocationCoordinate2D(latitude: 52.782382, longitude: 6.894363),
            placeIcon: "bag.fill"
        ),
        Place(
            name: "NHL Stenden Emmen",
            coordinate: CLLocationCoordinate2D(latitude: 52.778150, longitude: 6.911960),
            placeIcon: "graduationcap.fill"
        ),
        Place(
            name: "Danackers 70",
            coordinate: CLLocationCoordinate2D(latitude: 52.780455, longitude: 6.94272),
            placeIcon: "house.fill"
        )
    ]

    private var capturedCount: Int { places.filter { $0.isCaptured }.count }
    private var totalCount: Int { places.count }
    private var capturedNames: [String] { places.filter { $0.isCaptured }.map { $0.name } }
    private var capturedPlaces: [Place] { places.filter { $0.isCaptured } }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $region) {
                ForEach(vm.places) { place in
                    Marker(place.name, coordinate: place.coordinate)
                        .tint(place.isCaptured ? .green : .blue)
                }
                UserAnnotation()
            }
            .ignoresSafeArea()

            
               GameOverlayView(
                    capturedCount: capturedCount,
                    totalCount: totalCount,
                    capturedPlaces: capturedNames
                )
            UserProfile(username: "Test User", lvl: 12, capturedPlaces: capturedPlaces)
            
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
    private let urlString = "http://localhost:8080/places"

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
                    )
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
