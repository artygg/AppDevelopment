import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 56.949766, longitude: 24.118936),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    private let captureRadius: Double = 100

    @State private var places: [Place] = [
        Place(name: "Kingdom NHL STENDEN", coordinate: CLLocationCoordinate2D(latitude: 56.949766, longitude: 24.118936)),
        Place(name: "Rīgas cirks", coordinate: CLLocationCoordinate2D(latitude: 56.95385, longitude: 24.12795)),
        Place(name: "Brīvības piemineklis", coordinate: CLLocationCoordinate2D(latitude: 56.9540, longitude: 24.1133)),
        Place(name: "ORIGO TC", coordinate: CLLocationCoordinate2D(latitude: 56.947773, longitude: 24.122821)),
        Place(name: "Vecrīga", coordinate: CLLocationCoordinate2D(latitude: 56.9480, longitude: 24.1060)),
        Place(name: "Rīgas Doms", coordinate: CLLocationCoordinate2D(latitude: 56.9474, longitude: 24.1062)),
        Place(name: "Rīgas Centrāltirgus", coordinate: CLLocationCoordinate2D(latitude: 56.9484, longitude: 24.1019))
    ]

    private var capturedCount: Int { places.filter { $0.isCaptured }.count }
    private var totalCount: Int { places.count }
    private var capturedNames: [String] { places.filter { $0.isCaptured }.map { $0.name } }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $region) {
                ForEach(places) { place in
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
            if let last = places.last(where: { $0.isCaptured }) {
                VStack {
                    Spacer()
                    Text("🏆 \(last.name) захвачен!")
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
        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
