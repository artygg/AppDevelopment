import SwiftUI
import MapboxMaps
import CoreLocation

struct MapboxViewWrapper: UIViewRepresentable {
    @Binding var places: [Place]
    @Binding var userLocation: CLLocation?
    @Environment(\.colorScheme) var colorScheme
    @State private var isStyleLoaded = false
    
    func makeUIView(context: Context) -> MapView {
        print("Initializing MapView...")
        
        guard let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String else {
            print("Error: Mapbox access token not found in Info.plist")
            fatalError("Mapbox access token not found in Info.plist")
        }
        
        let resourceOptions = ResourceOptions(accessToken: token)
        let styleURI = colorScheme == .dark ? StyleURI.dark : StyleURI.streets
        
        let initOptions = MapInitOptions(
            resourceOptions: resourceOptions,
            styleURI: styleURI
        )
        
        let mapView = MapView(frame: .zero, mapInitOptions: initOptions)
        
        mapView.ornaments.options.attributionButton.margins = .init(x: -1000, y: 0)
        mapView.ornaments.options.logo.margins = .init(x: 0, y: -1000)
        mapView.ornaments.options.scaleBar.margins = .init(x: 0, y: -1000)
        mapView.ornaments.options.compass.margins = .init(x: 0, y: -1000)
        
        mapView.mapboxMap.onEvery(event: .styleLoaded) { [weak mapView] _ in
            guard let mapView = mapView else { return }
            DispatchQueue.main.async {
                self.isStyleLoaded = true
                self.hideAllTextLabels(mapView: mapView)
            }
        }
        
        mapView.location.options.puckType = .puck2D()
        mapView.location.options.puckBearingEnabled = true
        mapView.location.options.puckBearingSource = .heading
        
        if let userLocation = userLocation {
            let cameraOptions = CameraOptions(
                center: userLocation.coordinate,
                zoom: 15
            )
            mapView.camera.ease(to: cameraOptions, duration: 1.0)
        }
        
        context.coordinator.mapView = mapView
        return mapView
    }

    private func hideAllTextLabels(mapView: MapView) {
        guard isStyleLoaded else { return }
        
        do {
            let layers = try mapView.mapboxMap.style.allLayerIdentifiers
            try layers.forEach { layer in
                if layer.type == .symbol {
                    try mapView.mapboxMap.style.setLayerProperty(for: layer.id, property: "visibility", value: "none")
                }
            }
            
            let labelLayers = [
                "road-label", "waterway-label", "natural-label",
                "poi-label", "country-label", "settlement-label",
                "state-label", "place-label", "airport-label"
            ]
            labelLayers.forEach { layerId in
                try? mapView.mapboxMap.style.setLayerProperty(for: layerId, property: "visibility", value: "none")
            }
        } catch {
            print("Error hiding text layers: \(error)")
        }
    }

    func updateUIView(_ uiView: MapView, context: Context) {
        context.coordinator.places = places
        context.coordinator.userLocation = userLocation
        context.coordinator.updateAnnotations()
        
        let newStyleURI = colorScheme == .dark ? StyleURI.dark : StyleURI.streets
        if uiView.mapboxMap.style.uri?.rawValue != newStyleURI.rawValue {
            try? uiView.mapboxMap.style.styleManager.setStyleURIForUri(newStyleURI.rawValue)
        }
        
        uiView.ornaments.options.attributionButton.margins = .init(x: -1000, y: 0)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: MapboxViewWrapper
        var places: [Place] = []
        var userLocation: CLLocation?
        var mapView: MapView?
        var annotationManager: PointAnnotationManager?

        init(_ parent: MapboxViewWrapper) {
            self.parent = parent
        }

        func updateAnnotations() {
            guard let mapView = mapView else { return }
            
            if annotationManager == nil {
                annotationManager = mapView.annotations.makePointAnnotationManager()
            }
            
            annotationManager?.annotations = places.map { place in
                var annotation = PointAnnotation(coordinate: place.coordinate)
                annotation.textField = place.name
                annotation.iconColor = StyleColor(place.isCaptured ? .systemGreen : .systemBlue)
                return annotation
            }
        }
    }
}
