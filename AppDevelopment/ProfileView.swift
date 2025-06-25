import SwiftUI
import CoreLocation

// MARK: - Global Configuration
struct APIConfig {
    static let baseURL = Config.apiURL
}

// MARK: - Data Models
struct CapturedPlaceResponse: Decodable {
    let name: String
    let latitude: Double
    let longitude: Double
    let category_id: Int
    let captured: Bool
    let user_captured: String
}

struct ProfileImage: Decodable, Identifiable {
    let id: Int
    let image_url: String
    
    var name: String {
        if let fileName = URL(string: image_url)?.lastPathComponent {
            let nameWithoutExtension = fileName.replacingOccurrences(of: "\\.[^.]*$", with: "", options: .regularExpression)
            return nameWithoutExtension.replacingOccurrences(of: "_", with: " ").capitalized
        }
        return "Avatar \(id)"
    }
    
    var url: String {
        return image_url
    }
}

struct UpdateMapImageRequest: Codable {
    let imageURL: String
    
    enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
    }
}

// MARK: - Authentication Models
struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct AuthResponse: Codable {
    let user: User
    let token: String
    let refreshToken: String?
    let expiresAt: Int?
    
    enum CodingKeys: String, CodingKey {
        case user, token
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
    }
}

struct User: Codable {
    let id: Int
    let username: String
    let email: String
    let createdAt: String
    let updatedAt: String
    let isActive: Bool
    let lastLoginAt: String?
    let mapImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isActive = "is_active"
        case lastLoginAt = "last_login_at"
        case mapImageUrl = "map_image_url"
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @ObservedObject var placesViewModel: DecodedPlacesViewModel
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("username") var username = ""
    @AppStorage("userEmail") var userEmail = ""
    @AppStorage("selectedAvatarURL") var selectedAvatarURL = ""
    @AppStorage("mineCount") private var mineCount: Int = 0

    @State private var showSettings = false
    @State private var showingAuth = false
    @State private var showAllPlaces = false
    @State private var showOwnerQuiz = false
    @State private var loadingOwnerQuiz = false
    @State private var ownerQuiz: Quiz? = nil
    @State private var selectedPlace: Place? = nil

    private var capturedPlaces: [Place] {
        placesViewModel.places
            .filter { $0.captured && $0.user_captured == username }
            .map {
                Place(
                    name: $0.name,
                    coordinate: $0.clCoordinate,
                    placeIcon: $0.iconName,
                    isCaptured: $0.captured,
                    user_captured: $0.user_captured
                )
            }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if isLoggedIn {
                        profileContent
                    } else {
                        authContent
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAuth) {
                AuthenticationView()
            }
            .sheet(isPresented: $showAllPlaces) {
                AllCapturedPlacesView(capturedPlaces: capturedPlaces)
            }
            .sheet(isPresented: $showOwnerQuiz) {
                if let quiz = ownerQuiz {
                    OwnerQuizView(mineCount: $mineCount, quiz: quiz) {
                        showOwnerQuiz = false
                    }
                }
            }
        }
        .overlay(
            Group {
                if loadingOwnerQuiz {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Loading Quiz...")
                            .padding(24)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                    }
                }
            }
        )
    }
    
    private var profileContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    if !selectedAvatarURL.isEmpty {
                        AsyncImage(url: URL(string: selectedAvatarURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                )
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Text(String(username.prefix(1)).uppercased())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 4) {
                    Text(username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Explorer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Places Captured",
                    value: "\(capturedPlaces.count)",
                    icon: "mappin.circle.fill",
                    color: .green
                )
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Captured Places")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !capturedPlaces.isEmpty {
                        Button("View All") {
                            showAllPlaces = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                if capturedPlaces.isEmpty {
                    EmptyStateView()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(capturedPlaces.prefix(5)) { place in
                            PlaceCard(place: place)
                                .onTapGesture {
                                    selectedPlace = place
                                    loadingOwnerQuiz = true
                                    Task {
                                        if let decoded = placesViewModel.places.first(where: { $0.name == place.name && $0.captured && $0.user_captured == username }) {
                                            let quiz = await QuizService.fetchQuiz(placeID: decoded.id)
                                            await MainActor.run {
                                                self.ownerQuiz = quiz
                                                self.loadingOwnerQuiz = false
                                                self.showOwnerQuiz = quiz != nil
                                            }
                                        } else {
                                            await MainActor.run {
                                                self.loadingOwnerQuiz = false
                                            }
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
                    
            Button(action: {
                logout()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }
    
    private var authContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Not Logged In")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Log in to view your profile and track your progress.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAuth = true
            } label: {
                Text("Log In or Sign Up")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(32)
    }
    
    private func logout() {
        APIService.shared.logout { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.clearLoginData()
                }
            case .failure(let error):
                print("Logout failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.clearLoginData()
                }
            }
        }
    }

    
    private func clearLoginData() {
        isLoggedIn = false
        username = ""
        userEmail = ""
        selectedAvatarURL = ""
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(placesViewModel: DecodedPlacesViewModel())
    }
}
