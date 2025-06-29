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
    var currentUser: String
    @Environment(\.colorScheme) var colorScheme
    @State private var isStyleLoaded = false
    var onMapTap: ((CLLocationCoordinate2D) -> Void)? = nil
    var onCameraChange: ((CLLocationCoordinate2D) -> Void)? = nil
    
    @Binding var shouldFocusOnUser: Bool
    var autoFocusEnabled: Bool
    var onAnnotationTap: ((Place) -> Void)? = nil

    @State private var hasInitiallyFocused = false
    
    func makeUIView(context: Context) -> MapView {
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
                
                context.coordinator.registerIcons(for: self.colorScheme)
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
        context.coordinator.autoFocusEnabled = autoFocusEnabled
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        mapView.mapboxMap.onEvery(event: .cameraChanged) { [mapView] _ in
            let center = mapView.cameraState.center
            self.onCameraChange?(center)
        }
        
        // Add background/foreground observers
        context.coordinator.setupBackgroundObservers()
        
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
        context.coordinator.places = places
        context.coordinator.userLocation = userLocation
        context.coordinator.autoFocusEnabled = autoFocusEnabled
        
        if !hasInitiallyFocused && userLocation != nil && isStyleLoaded && autoFocusEnabled {
            hasInitiallyFocused = true
            
            context.coordinator.focusOnUser()
        }
        
        if shouldFocusOnUser && autoFocusEnabled {
            context.coordinator.focusOnUser()
            DispatchQueue.main.async {
                shouldFocusOnUser = false
            }
        }
        
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

    class Coordinator: NSObject, AnnotationInteractionDelegate {
        var parent: MapboxViewWrapper
        var places: [Place] = []
        var userLocation: CLLocation?
        var mapView: MapView?
        var annotationManager: PointAnnotationManager?
        var iconsRegistered = false
        var currentColorScheme: ColorScheme = .light
        var registeredIcons: Set<String> = []
        var autoFocusEnabled: Bool = true
        
        // Properties for background handling
        private var backgroundObserver: NSObjectProtocol?
        private var foregroundObserver: NSObjectProtocol?
        private var needsAnnotationRefresh = false
        
        init(_ parent: MapboxViewWrapper) {
            self.parent = parent
        }
        
        deinit {
            // Clean up observers
            if let backgroundObserver = backgroundObserver {
                NotificationCenter.default.removeObserver(backgroundObserver)
            }
            if let foregroundObserver = foregroundObserver {
                NotificationCenter.default.removeObserver(foregroundObserver)
            }
        }
        
        // MARK: - Background/Foreground Handling
        func setupBackgroundObservers() {
            backgroundObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            
            foregroundObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
        }
        
        private func handleAppDidEnterBackground() {
            print("App entering background - marking annotations for refresh")
            needsAnnotationRefresh = true
        }
        
        private func handleAppWillEnterForeground() {
            print("App entering foreground - checking if annotations need refresh")
            
            // Add a small delay to ensure the map is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.refreshAnnotationsIfNeeded()
            }
        }
        
        private func refreshAnnotationsIfNeeded() {
            guard needsAnnotationRefresh else { return }
            
            print("Refreshing annotations after returning from background")
            
            // Reset the annotation manager
            annotationManager = nil
            iconsRegistered = false
            registeredIcons.removeAll()
            
            // Re-register icons and update annotations
            registerIcons(for: currentColorScheme)
            updateAnnotations(for: currentColorScheme)
            
            needsAnnotationRefresh = false
        }
        
        // MARK: - Focus on User Implementation
        func focusOnUser() {
            guard autoFocusEnabled else {
                return
            }
            
            guard let mapView = mapView else {
                return
            }
            
            guard let userLocation = userLocation else {
                return
            }
                        
            let cameraOptions = CameraOptions(
                center: userLocation.coordinate,
                zoom: 16,
                bearing: mapView.cameraState.bearing,
                pitch: mapView.cameraState.pitch
            )
            
            mapView.camera.ease(
                to: cameraOptions,
                duration: 1.2,
                curve: .easeInOut
            ) { [weak self] _ in
                if self?.autoFocusEnabled == true {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }
        }
        
        func registerIcons(for colorScheme: ColorScheme) {
            guard let mapView = mapView else { return }
            
            // Check if icons are already registered for this color scheme
            let themeSuffix = colorScheme == .dark ? "dark" : "light"
            let testIconId = "mappin.circle.fill_\(themeSuffix)"
            
            if registeredIcons.contains(testIconId) {
                print("Icons already registered for \(themeSuffix) theme")
                return
            }
            
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
                        let themedIconId = "\(iconName)_\(themeSuffix)"
                        try mapView.mapboxMap.style.addImage(themedImage, id: themedIconId)
                        registeredIcons.insert(themedIconId)
                        print("Successfully registered icon: \(themedIconId)")
                    } catch {
                        print("Failed to register themed icon '\(iconName)': \(error.localizedDescription)")
                    }
                } else {
                    print("Failed to create themed UIImage for SF Symbol: \(iconName)")
                }
            }
            
            iconsRegistered = true
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
            guard let mapView = mapView else {
                print("MapView is nil, cannot update annotations")
                return
            }
            
            guard !places.isEmpty else {
                print("No places to display")
                return
            }
            
            // Ensure icons are registered first
            if !iconsRegistered {
                registerIcons(for: colorScheme)
            }
            
            // Create or recreate annotation manager if needed
            if annotationManager == nil {
                annotationManager = mapView.annotations.makePointAnnotationManager()
                annotationManager?.delegate = self
                print("Created new annotation manager")
            } else {
                annotationManager?.delegate = self
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
                
                let colorIcon: UIColor
                if place.isCaptured {
                    if let capturedUser = place.user_captured, capturedUser == parent.currentUser {
                        colorIcon = .green
                    } else {
                        colorIcon = .red
                    }
                } else {
                    colorIcon = colorScheme == .dark ? .white : .black
                }
                annotation.textColor = StyleColor(colorIcon)
                annotation.textHaloWidth = 1.0
                
                newAnnotations.append(annotation)
            }
            
            // Update annotations
            annotationManager?.annotations = newAnnotations
            print("Updated \(newAnnotations.count) annotations")
            
            debugAvailableIcons(for: colorScheme)
        }
        
        func debugAvailableIcons(for colorScheme: ColorScheme) {
            guard let mapView = mapView else { return }
                        
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
        
        func annotationManager(_ manager: AnnotationManager, didDetectTappedAnnotations annotations: [Annotation]) {
            for annotation in annotations {
                if let pointAnnotation = annotation as? PointAnnotation {
                    if let tappedPlace = places.first(where: { place in
                        place.coordinate.latitude == pointAnnotation.point.coordinates.latitude &&
                        place.coordinate.longitude == pointAnnotation.point.coordinates.longitude
                    }) {
                        parent.onAnnotationTap?(tappedPlace)
                    }
                }
            }
        }
    }
}