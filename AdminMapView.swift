import SwiftUI
import MapboxMaps
import CoreLocation

struct AdminMapView: View {
    @Binding var places: [DecodedPlace]
    @State private var showingAddSheet = false
    @State private var newPlaceName = ""
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 52.78, longitude: 6.90)

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
                currentUser: currentUser,
                onCameraChange: { newCenter in
                    mapCenter = newCenter
                }
            )
            .ignoresSafeArea()

            // Static crosshair in the center
            CrosshairView()
            
            // UI Controls
            VStack {
                // Top area - could add other controls here
                HStack {
                    Spacer()
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Bottom controls
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Add Place button
                        Button(action: {
                            showingAddSheet = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 44))
                                Text("Add Place")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        // Current coordinates display
                        VStack(spacing: 2) {
                            Text("Center Location:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(mapCenter.latitude, specifier: "%.4f")")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("\(mapCenter.longitude, specifier: "%.4f")")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddPlaceForm(
                name: newPlaceName,
                onCancel: {
                    showingAddSheet = false
                },
                onSave: { finalName, chosenCategoryID in
                    guard !finalName.isEmpty else {
                        showingAddSheet = false
                        return
                    }

                    let requestBody = CreatePlaceRequest(
                        name: finalName,
                        latitude: mapCenter.latitude,
                        longitude: mapCenter.longitude,
                        category_id: chosenCategoryID
                    )

                    print("Creating place at lat: \(mapCenter.latitude), lon: \(mapCenter.longitude)")

                    isSaving = true
                    saveError = nil

                    createPlace(requestBody) { result in
                        DispatchQueue.main.async {
                            isSaving = false
                            switch result {
                            case .success(let pr):
                                let icon = allCategories
                                    .first(where: { $0.id == pr.category_id })?
                                    .iconName ?? "mappin.circle.fill"

                                let decoded = DecodedPlace(
                                    id: pr.id,
                                    name: pr.name,
                                    latitude: pr.latitude,
                                    longitude: pr.longitude,
                                    category_id: pr.category_id,
                                    captured: pr.captured,
                                    user_captured: pr.user_captured,
                                    cooldown_until: nil,
                                    iconName: icon
                                )
                                places.append(decoded)
                                showingAddSheet = false

                            case .failure(let err):
                                saveError = err.localizedDescription
                                print("Failed to create place: \(err)")
                            }
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
        .alert("Error", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }
}

struct CrosshairView: View {
    var body: some View {
        ZStack {
            // Crosshair lines
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: 40)
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 40, height: 2)
            
            // Center dot
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            
            // Outer circle for better visibility
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 60, height: 60)
            
            Circle()
                .stroke(Color.red, lineWidth: 1)
                .frame(width: 60, height: 60)
        }
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

// Alternative crosshair design
struct CrosshairViewAlt: View {
    var body: some View {
        ZStack {
            // Target-style crosshair
            Image(systemName: "plus.circle")
                .font(.system(size: 50))
                .foregroundColor(.red)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 60, height: 60)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
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
