    //
    //  AdminMapView.swift
    //  AppDevelopment
    //
    //  Created by Artyom Grishayev on 13/05/2025.
    //
    import SwiftUI
    import MapKit
    import CoreLocation

    struct AdminMapView: View {
        @Binding var places: [DecodedPlace]
        @Binding var region: MapCameraPosition
        @State private var currentCenter = CLLocationCoordinate2D(latitude: 52.78, longitude: 6.90)
        let isAdmin: Bool
        
        @State private var isEditing = false
        @State private var showingAddSheet = false
        @State private var newPlaceName = ""
        @State private var newPlaceCoord: CLLocationCoordinate2D?
        
        @State private var isSaving = false
        @State private var saveError: String?
        
        
        var body: some View {
            ZStack {
                Map(position: $region) {
                    ForEach(places) { place in
                        Annotation(place.name, coordinate: place.clCoordinate) {
                            VStack(spacing: 0) {
                                CategoryIconView(
                                    categoryID: place.category_id,
                                    iconName:   place.iconName
                                )
                                .foregroundColor(place.captured ? .green : .blue)
                                
                            }
                        }
                    }
                    UserAnnotation()
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                            currentCenter = context.region.center
                          }
                .ignoresSafeArea()
                
                if isEditing {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                        .offset(y: -22)
                    
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button("Add Place") {
                                newPlaceCoord = currentCenter
                                showingAddSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                            Spacer()
                        }
                    }
                    
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
                        isEditing = false
                    },
                    onSave: { finalName, chosenCategoryID in
                        guard let coord = newPlaceCoord, !finalName.isEmpty else {
                            showingAddSheet = false
                            isEditing = false
                            return
                        }
                        
                        let requestBody = CreatePlaceRequest(
                            name: finalName,
                            latitude: coord.latitude,
                            longitude: coord.longitude,
                            category_id: chosenCategoryID
                        )
                        
                        isSaving = true
                        saveError = nil
                        

                        createPlace(requestBody) { result in
                            isSaving = false
                            switch result {
                            case .success(let placeResponse):

                                let iconForCategory = allCategories
                                    .first(where: { $0.id == placeResponse.category_id })?
                                    .iconName
                                ?? "mappin.circle.fill" // fallback
                                
                                let decoded = DecodedPlace(
                                    id:            placeResponse.id,
                                    name:          placeResponse.name,
                                    latitude:      placeResponse.latitude,
                                    longitude:     placeResponse.longitude,
                                    category_id:   placeResponse.category_id,
                                    captured:      placeResponse.captured,
                                    user_captured: placeResponse.user_captured,
                                    iconName:      iconForCategory
                                )
                                places.append(decoded)
                                showingAddSheet = false
                                isEditing = false
                                
                            case .failure(let error):
                                saveError = error.localizedDescription

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
