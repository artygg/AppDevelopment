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
    @State private var showCaptureBanner = false
    @State private var region = MapCameraPosition.region(
      MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.78, longitude: 6.9),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
      )
    )

    @State private var showCamera = false
    @State private var capturedImage: UIImage?

    
    var isAdmin: Bool = true // FOR DEV PURPOSES
    private let captureRadius: Double = 100

    private var capturedCount: Int { vm.places.filter { $0.isCaptured }.count }
    private var totalCount: Int { vm.places.count }
    private var capturedNames: [String] { vm.places.filter { $0.isCaptured }.map { $0.name } }
    private var capturedPlaces: [Place] { vm.places.filter { $0.isCaptured } }

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
                    }
                    UserAnnotation()
                }
                .ignoresSafeArea()
            }
            
            GameOverlayView(
                capturedCount: capturedCount,
                totalCount: totalCount,
                capturedPlaces: capturedNames
            )
            UserProfile(username: "Test User", lvl: 12, capturedPlaces: capturedPlaces)
            
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
        .onChange(of: capturedCount) {
            showCaptureBanner = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showCaptureBanner = false }
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
