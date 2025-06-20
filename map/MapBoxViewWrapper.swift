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
    var onCameraChange: ((CLLocationCoordinate2D) -> Void)? = nil
    
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
                print("Style loaded!")
                self.isStyleLoaded = true
                self.hideAllTextLabels(mapView: mapView)
                
                context.coordinator.registerIcons(for: self.colorScheme)
                
                print("Style loaded, updating annotations...")
                context.coordinator.updateAnnotations(for: self.colorScheme)
            }
        }
        
        mapView.location.options.puckType = .puck2D()
        mapView.location.options.puckBearingEnabled = true
        mapView.location.options.puckBearing = .heading
        
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

        mapView.mapboxMap.onEvery(event: .cameraChanged) { [mapView] _ in
            let center = mapView.cameraState.center
            self.onCameraChange?(center)
        }
        
        return mapView
    }

    private func hideAllTextLabels(mapView: MapView) {
        guard isStyleLoaded else { return }
        
        let layers = mapView.mapboxMap.style.allLayerIdentifiers
        layers.forEach { layer in
            if layer.type == .symbol {
                try? mapView.mapboxMap.style.setLayerProperty(for: layer.id, property: "visibility", value: "none")
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
    }

    func updateUIView(_ uiView: MapView, context: Context) {
        print("UpdateUIView called with \(places.count) places")
        
        context.coordinator.places = places
        context.coordinator.userLocation = userLocation
        
        if context.coordinator.currentColorScheme != colorScheme {
            context.coordinator.currentColorScheme = colorScheme
            context.coordinator.registeredIcons.removeAll()
            context.coordinator.iconsRegistered = false
        }
        
        if isStyleLoaded {
            context.coordinator.registerIcons(for: colorScheme)
        }
        
        if !places.isEmpty && isStyleLoaded {
            context.coordinator.updateAnnotations(for: colorScheme)
        } else {
            print("Skipping annotation update - places: \(places.count), styleLoaded: \(isStyleLoaded)")
        }
        
        let newStyleURI = colorScheme == .dark ? StyleURI.dark : StyleURI.streets
        if uiView.mapboxMap.style.uri?.rawValue != newStyleURI.rawValue {
            uiView.mapboxMap.style.styleManager.setStyleURIForUri(newStyleURI.rawValue)
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
        var iconsRegistered = false
        var currentColorScheme: ColorScheme = .light
        var registeredIcons: Set<String> = []
        
        init(_ parent: MapboxViewWrapper) {
            self.parent = parent
        }
        
        func registerIcons(for colorScheme: ColorScheme) {
            guard let mapView = mapView else { return }
            
            print("🔧 Registering icons for \(colorScheme == .dark ? "dark" : "light") theme...")
            
            let allIcons = Set(places.map { $0.placeIcon })
            
            let knownSymbols = [
                "mappin.circle.fill",
                "building.2",
                "fork.knife.circle.fill",
                "die.face.5.fill",
                "house.fill",
                "car.fill",
                "airplane",
                "bed.double.fill",
                "bag.fill",
                "cart.fill",
                "heart.fill",
                "star.fill",
                "flag.fill",
                "camera.fill",
                "phone.fill",
                "envelope.fill"
            ]
            
            let iconsToRegister = allIcons.union(Set(knownSymbols))
            
            let iconColor: UIColor = colorScheme == .dark ? .white : .black
            let backgroundColor: UIColor = colorScheme == .dark ? .black : .white
            
            for iconName in iconsToRegister {
                if let themedImage = createThemedIcon(
                    symbolName: iconName,
                    iconColor: iconColor,
                    backgroundColor: backgroundColor,
                    colorScheme: colorScheme
                ) {
                    do {
                        let themedIconId = "\(iconName)_\(colorScheme == .dark ? "dark" : "light")"
                        try mapView.mapboxMap.style.addImage(themedImage, id: themedIconId)
                        print("Successfully registered themed icon: \(themedIconId)")
                    } catch {
                        print("Failed to register themed icon '\(iconName)': \(error.localizedDescription)")
                    }
                } else {
                    print("Failed to create themed UIImage for SF Symbol: \(iconName)")
                }
            }
            
            iconsRegistered = true
            print("Themed icon registration completed")
        }
        
        private func createThemedIcon(
            symbolName: String,
            iconColor: UIColor,
            backgroundColor: UIColor,
            colorScheme: ColorScheme
        ) -> UIImage? {
            let size = CGSize(width: 40, height: 40)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { context in
                let cgContext = context.cgContext
                
                guard let symbolImage = UIImage(
                    systemName: symbolName,
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
                ) else { return }
                
                let circleRect = CGRect(x: 4, y: 4, width: 32, height: 32)
                cgContext.setFillColor(backgroundColor.cgColor)
                cgContext.fillEllipse(in: circleRect)
                
                cgContext.setStrokeColor(iconColor.withAlphaComponent(0.3).cgColor)
                cgContext.setLineWidth(1.0)
                cgContext.strokeEllipse(in: circleRect)
                
                let iconRect = CGRect(x: 8, y: 8, width: 24, height: 24)
                cgContext.saveGState()
                cgContext.setFillColor(iconColor.cgColor)
                
                let coloredSymbol = symbolImage.withTintColor(iconColor, renderingMode: .alwaysOriginal)
                coloredSymbol.draw(in: iconRect)
                
                cgContext.restoreGState()
            }
        }
        
        func updateAnnotations(for colorScheme: ColorScheme) {
            print("UpdateAnnotations called for \(colorScheme == .dark ? "dark" : "light") theme")
            print("   - mapView is nil: \(mapView == nil)")
            print("   - places count: \(places.count)")
            print("   - registered icons count: \(registeredIcons.count)")
            
            guard let mapView = mapView else {
                print("MapView is nil")
                return
            }
            
            guard !places.isEmpty else {
                print("No places to display")
                return
            }
            
            registerIcons(for: colorScheme)
            
            print("Starting annotation update with \(places.count) places")
            
            if annotationManager == nil {
                annotationManager = mapView.annotations.makePointAnnotationManager()
                print("Created annotation manager")
            }
            
            var newAnnotations: [PointAnnotation] = []
            
            for (index, place) in places.enumerated() {
                let baseIconName = place.placeIcon.isEmpty ? "mappin.circle.fill" : place.placeIcon
                
                let themedIconName = "\(baseIconName)_\(colorScheme == .dark ? "dark" : "light")"
                
                var annotation = PointAnnotation(coordinate: place.coordinate)
                annotation.iconImage = themedIconName
                annotation.textField = place.name
                
                annotation.iconSize = 1.0
                
                annotation.textAnchor = .top
                annotation.textOffset = [0, 1.5]
                
                annotation.textSize = 12
                annotation.textColor = StyleColor(colorScheme == .dark ? .white : .black)
                annotation.textHaloColor = StyleColor(colorScheme == .dark ? .black : .white)
                annotation.textHaloWidth = 1.0
                
                print("[\(index)] \(place.name) -> \(themedIconName) at \(place.coordinate)")
                newAnnotations.append(annotation)
            }
            
            annotationManager?.annotations = newAnnotations
            print("Applied \(newAnnotations.count) themed annotations to manager")
            
            debugAvailableIcons(for: colorScheme)
        }
        
        func debugAvailableIcons(for colorScheme: ColorScheme) {
            guard let mapView = mapView else { return }
            
            print("Checking registered themed icons...")
            
            let baseIcons = Set(places.map { $0.placeIcon }).union(["mappin.circle.fill", "building.2"])
            let themeSuffix = colorScheme == .dark ? "dark" : "light"
            
            for baseIconName in baseIcons {
                let themedIconName = "\(baseIconName)_\(themeSuffix)"
                if let _ = mapView.mapboxMap.style.image(withId: themedIconName) {
                    print("Themed icon '\(themedIconName)' is registered and available")
                } else {
                    print("Themed icon '\(themedIconName)' is NOT available")
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
