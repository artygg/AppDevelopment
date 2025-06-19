//
//  AdminMapView.swift
//  AppDevelopment
//
//  Created by Artyom Grishayev on 13/05/2025.
//

import SwiftUI
import MapboxMaps
import CoreLocation

struct AdminMapView: View {
    @Binding var places: [DecodedPlace]
    @State private var isEditing = false
    @State private var showingAddSheet = false
    @State private var newPlaceName = ""
    @State private var newPlaceCoord: CLLocationCoordinate2D?
    @State private var selectedPinCoord: CLLocationCoordinate2D? = nil

    @State private var isSaving = false
    @State private var saveError: String?

    @AppStorage("username") private var currentUser = "player1"

    private var mapboxPlaces: [Place] {
        places.map { dp in
            Place(
                name: dp.name,
                coordinate: dp.clCoordinate,
                placeIcon: dp.iconName,
                isCaptured: dp.captured
            )
        }
    }
    @State private var userLocation: CLLocation? = nil

    var body: some View {
        ZStack {
            MapboxViewWrapper(
                places: .constant(mapboxPlaces),
                userLocation: .constant(userLocation),
                onMapTap: isEditing ? { coord in
                    selectedPinCoord = coord
                    newPlaceCoord = coord
                } : nil
            )
            .ignoresSafeArea()

            if isEditing, let pinCoord = selectedPinCoord {
                PinOverlayView(coordinate: pinCoord)
            }

            VStack {
                Spacer()
                HStack {
                    Button { isEditing.toggle() } label: {
                        Image(systemName: isEditing ? "xmark.circle" : "plus.circle")
                            .font(.largeTitle)
                            .padding()
                    }
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddPlaceForm(
                name: newPlaceName,
                onCancel: {
                    showingAddSheet = false
                    isEditing       = false
                    selectedPinCoord = nil
                },
                onSave: { finalName, chosenCategoryID in
                    guard let coord = newPlaceCoord, !finalName.isEmpty else {
                        showingAddSheet = false
                        isEditing       = false
                        selectedPinCoord = nil
                        return
                    }

                    let requestBody = CreatePlaceRequest(
                        name: finalName,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        category_id: chosenCategoryID
                    )

                    isSaving  = true
                    saveError = nil

                    createPlace(requestBody) { result in
                        isSaving = false
                        switch result {
                        case .success(let pr):
                            let icon = allCategories
                                .first(where: { $0.id == pr.category_id })?
                                .iconName ?? "mappin.circle.fill"

                            let decoded = DecodedPlace(
                                id:            pr.id,
                                name:          pr.name,
                                latitude:      pr.latitude,
                                longitude:     pr.longitude,
                                category_id:   pr.category_id,
                                captured:      pr.captured,
                                user_captured: pr.user_captured,
                                cooldown_until: nil,
                                iconName:      icon
                            )
                            places.append(decoded)
                            showingAddSheet = false
                            isEditing       = false
                            selectedPinCoord = nil

                        case .failure(let err):
                            saveError = err.localizedDescription
                            selectedPinCoord = nil
                        }
                    }
                }
            )
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Saving…")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct PinOverlayView: View {
    let coordinate: CLLocationCoordinate2D
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        GeometryReader { geo in
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(colorScheme == .dark ? .yellow : .blue)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .allowsHitTesting(false)
    }
}
