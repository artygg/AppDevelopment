//
//  MapBoxViewWrapper.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 18/06/2025.
//

import SwiftUI
import MapboxMaps
import CoreLocation

struct MapboxViewWrapper: UIViewRepresentable {
    @Binding var places: [Place]
    @Binding var userLocation: CLLocation?
    @Environment(\.colorScheme) var colorScheme
    @State private var isStyleLoaded = false
    var onMapTap: ((CLLocationCoordinate2D) -> Void)? = nil
    
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
                print("Style loaded, updating annotations...")
                context.coordinator.updateAnnotations()
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
        context.coordinator.places = places
        print("Set mapView and initial places (\(places.count)) in coordinator")
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
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
        print("UpdateUIView called with \(places.count) places")
        
        context.coordinator.places = places
        context.coordinator.userLocation = userLocation
        
        if !places.isEmpty {
            context.coordinator.updateAnnotations()
        } else {
            print("No places to update, skipping annotation update")
        }
        
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
            print("🔍 updateAnnotations called")
            print("   - mapView is nil: \(mapView == nil)")
            print("   - places count: \(places.count)")
            
            guard let mapView = mapView else {
                print("MapView is nil")
                return
            }
            
            guard !places.isEmpty else {
                print("No places to display")
                return
            }
            
            print("Starting annotation update with \(places.count) places")
            
            if annotationManager == nil {
                annotationManager = mapView.annotations.makePointAnnotationManager()
                print("Created annotation manager")
            }
            
            let knownSymbols = ["mappin.circle.fill", "building.2"]
            
            for symbol in knownSymbols {
                if let image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 32)) {
                    do {
                        try mapView.mapboxMap.style.addImage(image, id: symbol)
                        print("Registered symbol: \(symbol)")
                    } catch {
                        print("Symbol registration info for \(symbol): \(error.localizedDescription)")
                    }
                } else {
                    print("Failed to create UIImage for: \(symbol)")
                }
            }
            
            var newAnnotations: [PointAnnotation] = []
            
            for (index, place) in places.enumerated() {
                let symbolName = knownSymbols.contains(place.placeIcon) ? place.placeIcon : "mappin.circle.fill"
                
                var annotation = PointAnnotation(coordinate: place.coordinate)
                annotation.iconImage = symbolName
                annotation.textField = place.name
                
                print("📍 [\(index)] \(place.name) -> \(symbolName) at \(place.coordinate)")
                newAnnotations.append(annotation)
            }
            
            annotationManager?.annotations = newAnnotations
            print("Applied \(newAnnotations.count) annotations to manager")
        }
        
        func debugAvailableIcons() {
            guard let mapView = mapView else { return }
            
            print("Checking registered icons...")
            
            let testSymbols = ["mappin.circle.fill", "building.2"]
            for symbol in testSymbols {
                do {
                    let image = try mapView.mapboxMap.style.image(withId: symbol)
                    print("Icon '\(symbol)' is registered and available")
                } catch {
                    print("Icon '\(symbol)' is NOT available: \(error)")
                }
            }
        }


        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView, gesture.state == .ended else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.mapboxMap.coordinate(for: point)
            parent.onMapTap?(coordinate)
        }
    }
}
