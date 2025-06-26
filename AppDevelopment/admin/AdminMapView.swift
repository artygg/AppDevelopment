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
    @Binding var autoFocusEnabled: Bool

    @State private var shouldFocusOnUser = true

    @AppStorage("username") private var currentUser = "player1"
    @Environment(\.colorScheme) var colorScheme

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
                },
                shouldFocusOnUser: $shouldFocusOnUser,
                autoFocusEnabled: autoFocusEnabled,
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
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(colorScheme == .dark ? Color.yellow : Color.blue)
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
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Text("\(mapCenter.longitude, specifier: "%.4f")")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            colorScheme == .dark ?
                            Color.black.opacity(0.7) :
                            Color.white.opacity(0.9)
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    colorScheme == .dark ?
                                    Color.gray.opacity(0.3) :
                                    Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: colorScheme == .dark ?
                            .white.opacity(0.1) :
                            .black.opacity(0.1),
                            radius: 2, x: 0, y: 1
                        )
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
                        .background(
                            colorScheme == .dark ?
                            Color.black.opacity(0.9) :
                            Color.white
                        )
                        .foregroundColor(
                            colorScheme == .dark ? .white : .black
                        )
                        .cornerRadius(8)
                        .shadow(radius: 8)
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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Crosshair lines
            Rectangle()
                .fill(colorScheme == .dark ? Color.yellow : Color.red)
                .frame(width: 2, height: 40)
            
            Rectangle()
                .fill(colorScheme == .dark ? Color.yellow : Color.red)
                .frame(width: 40, height: 2)
            
            // Center dot
            Circle()
                .fill(colorScheme == .dark ? Color.yellow : Color.red)
                .frame(width: 8, height: 8)
            
            // Outer circle for better visibility
            Circle()
                .stroke(
                    colorScheme == .dark ? Color.black : Color.white,
                    lineWidth: 2
                )
                .frame(width: 60, height: 60)
            
            Circle()
                .stroke(
                    colorScheme == .dark ? Color.yellow : Color.red,
                    lineWidth: 1
                )
                .frame(width: 60, height: 60)
        }
        .shadow(
            color: colorScheme == .dark ?
            .white.opacity(0.3) :
            .black.opacity(0.3),
            radius: 2, x: 0, y: 1
        )
    }
}

// Alternative crosshair design with theme support
struct CrosshairViewAlt: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Target-style crosshair
            Image(systemName: "plus.circle")
                .font(.system(size: 50))
                .foregroundColor(colorScheme == .dark ? .yellow : .red)
                .background(
                    Circle()
                        .fill(
                            colorScheme == .dark ?
                            Color.black.opacity(0.8) :
                            Color.white.opacity(0.8)
                        )
                        .frame(width: 60, height: 60)
                )
                .shadow(
                    color: colorScheme == .dark ?
                    .white.opacity(0.3) :
                    .black.opacity(0.3),
                    radius: 4, x: 0, y: 2
                )
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

// MARK: - Theme Extensions and Utilities

extension Color {
    // Custom theme colors
    static let primaryButton = Color("PrimaryButton") // Define in Assets.xcassets
    static let secondaryBackground = Color("SecondaryBackground")
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    
    // Dynamic colors that adapt to color scheme
    static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// Theme-aware button style
struct ThemedButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    let backgroundColor: Color?
    let foregroundColor: Color?
    
    init(backgroundColor: Color? = nil, foregroundColor: Color? = nil) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(
                foregroundColor ?? (colorScheme == .dark ? .black : .white)
            )
            .background(
                backgroundColor ?? (colorScheme == .dark ? Color.yellow : Color.blue)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Theme-aware card background
struct ThemedCardBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                colorScheme == .dark ?
                Color.black.opacity(0.7) :
                Color.white.opacity(0.9)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        colorScheme == .dark ?
                        Color.gray.opacity(0.3) :
                        Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: colorScheme == .dark ?
                .white.opacity(0.1) :
                .black.opacity(0.1),
                radius: 2, x: 0, y: 1
            )
    }
}

extension View {
    func themedCardBackground() -> some View {
        modifier(ThemedCardBackground())
    }
}
