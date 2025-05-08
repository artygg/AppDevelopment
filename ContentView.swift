import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.78, longitude: 6.9),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    private let captureRadius: Double = 100

    @State private var places: [Place] = [
        Place(name: "Wildlands Adventure Zoo", coordinate: CLLocationCoordinate2D(latitude: 52.780748, longitude: 6.887516)),
        Place(name: "Station Emmen", coordinate: CLLocationCoordinate2D(latitude: 52.790453, longitude: 6.899715)),
        Place(name: "Rensenpark", coordinate: CLLocationCoordinate2D(latitude: 52.785692, longitude: 6.897980)),
        Place(name: "Emmerdennen Bos", coordinate: CLLocationCoordinate2D(latitude: 52.794587, longitude: 6.917414)),
        Place(name: "Winkelcentrum De Weiert", coordinate: CLLocationCoordinate2D(latitude: 52.782382, longitude: 6.894363)),
        Place(name: "NHL Stenden Emmen", coordinate: CLLocationCoordinate2D(latitude: 52.778150, longitude: 6.911960)),
        Place(name: "Danackers 70", coordinate: CLLocationCoordinate2D(latitude: 52.780455, longitude: 6.94272)),
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
            UserProfile(username: "Test User", lvl: 12)
            
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
