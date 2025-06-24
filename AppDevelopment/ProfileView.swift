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

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()
    private init() {}
    
    func register(username: String, email: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/register") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = RegisterRequest(username: username, email: email, password: password)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.invalidResponse))
                }
                return
            }
            
            DispatchQueue.main.async {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    do {
                        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                        self.saveUserData(from: authResponse)
                        completion(.success(authResponse))
                    } catch {
                        if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = errorResponse["message"] as? String {
                            completion(.failure(APIError.authError(message)))
                        } else {
                            completion(.failure(error))
                        }
                    }
                } else {
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorResponse["message"] as? String {
                        completion(.failure(APIError.authError(message)))
                    } else {
                        completion(.failure(APIError.serverError(httpResponse.statusCode)))
                    }
                }
            }
        }.resume()
    }
    
    func login(username: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/login") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = LoginRequest(username: username, password: password)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.invalidResponse))
                }
                return
            }
            
            DispatchQueue.main.async {
                if httpResponse.statusCode == 200 {
                    do {
                        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                        self.saveUserData(from: authResponse)
                        completion(.success(authResponse))
                    } catch {
                        if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = errorResponse["message"] as? String {
                            completion(.failure(APIError.authError(message)))
                        } else {
                            completion(.failure(error))
                        }
                    }
                } else {
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = errorResponse["message"] as? String {
                        completion(.failure(APIError.authError(message)))
                    } else {
                        completion(.failure(APIError.serverError(httpResponse.statusCode)))
                    }
                }
            }
        }.resume()
    }
    
    private func saveUserData(from authResponse: AuthResponse) {
        UserDefaults.standard.set(authResponse.token, forKey: "authToken")
        UserDefaults.standard.set(authResponse.user.username, forKey: "username")
        UserDefaults.standard.set(authResponse.user.email, forKey: "userEmail")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        
        if let mapImageUrl = authResponse.user.mapImageUrl {
            UserDefaults.standard.set(mapImageUrl, forKey: "selectedAvatarURL")
        }
    }
    
    func logout(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/logout") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.invalidResponse))
                }
                return
            }
            
            DispatchQueue.main.async {
                if httpResponse.statusCode == 200 {
                    self.clearUserData()
                    completion(.success(true))
                } else {
                    completion(.failure(APIError.serverError(httpResponse.statusCode)))
                }
            }
        }.resume()
    }
    
    private func clearUserData() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "selectedAvatarURL")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
    }
    
    func fetchProfileImages(completion: @escaping (Result<[ProfileImage], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/profile_images") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let authToken = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.invalidResponse))
                }
                return
            }
            
            DispatchQueue.main.async {
                if httpResponse.statusCode == 200 {
                    do {
                        let images = try JSONDecoder().decode([ProfileImage].self, from: data)
                        completion(.success(images))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(APIError.serverError(httpResponse.statusCode)))
                }
            }
        }.resume()
    }
    
    func updateUserMapImage(imageURL: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/user/map_image") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

         if let authToken = UserDefaults.standard.string(forKey: "authToken") {
             request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
         }
        
        let requestBody = UpdateMapImageRequest(imageURL: imageURL)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.invalidResponse))
                }
                return
            }
            
            DispatchQueue.main.async {
                if httpResponse.statusCode == 200 {
                    UserDefaults.standard.set(imageURL, forKey: "selectedAvatarURL")
                    completion(.success(true))
                } else {
                    completion(.failure(APIError.serverError(httpResponse.statusCode)))
                }
            }
        }.resume()
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case authError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .authError(let message):
            return message
        }
    }
}

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

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct PlaceCard: View {
    let place: Place
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: place.placeIcon)
                    .font(.title3)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("Lat: \(String(format: "%.4f", place.coordinate.latitude)), Lon: \(String(format: "%.4f", place.coordinate.longitude))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 4) {
                Text("No Places Captured Yet")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Start exploring to capture your first place")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 180)
        .padding(.horizontal, 32)
    }
}

struct SettingsView: View {
    @AppStorage("selectedAvatarURL") var selectedAvatarURL = ""
       @State private var avatarOptions: [ProfileImage] = []
       @State private var isLoadingAvatars = false
       @State private var showAvatarSelection = false
       @State private var errorMessage = ""
       @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile")) {
                    Button(action: {
                        fetchAvatarOptions()
                        showAvatarSelection = true
                    }) {
                        HStack {
                            Text("Change Avatar")
                            Spacer()
                            if !selectedAvatarURL.isEmpty {
                                AsyncImage(url: URL(string: selectedAvatarURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Preferences")) {
                    NavigationLink(destination: MapSettingsView()) {
                        Text("Map Settings")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Text("Notifications")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                    } label: {
                        Text("Delete Account")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAvatarSelection) {
                AvatarSelectionView(
                    avatars: avatarOptions,
                    isLoading: isLoadingAvatars,
                    selectedAvatarURL: $selectedAvatarURL
                )
            }
        }
        .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .sheet(isPresented: $showAvatarSelection) {
                        AvatarSelectionView(
                            avatars: avatarOptions,
                            isLoading: isLoadingAvatars,
                            selectedAvatarURL: $selectedAvatarURL
                        )
                    }
                    .alert("Error", isPresented: $showError) {
                        Button("OK") { }
                    } message: {
                        Text(errorMessage)
                    }
    }
    
    func fetchAvatarOptions() {
            guard avatarOptions.isEmpty else { return }
            isLoadingAvatars = true
            
            APIService.shared.fetchProfileImages { result in
                isLoadingAvatars = false
                
                switch result {
                case .success(let images):
                    avatarOptions = images
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
}

struct AvatarSelectionView: View {
    let avatars: [ProfileImage]
    let isLoading: Bool
    @Binding var selectedAvatarURL: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                    ForEach(avatars) { avatar in
                        Button {
                            selectedAvatarURL = avatar.url
                            APIService.shared.updateUserMapImage(imageURL: avatar.url) { _ in
                            }
                            dismiss()
                        } label: {
                            VStack {
                                AsyncImage(url: URL(string: avatar.url)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedAvatarURL == avatar.url ? Color.blue : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                
                                Text(avatar.name)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
}

struct MapSettingsView: View {
    @AppStorage("mapStyle") var mapStyle = "standard"
    
    var body: some View {
        Form {
            Section(header: Text("Map Display")) {
                Picker("Map Style", selection: $mapStyle) {
                    Text("Standard").tag("standard")
                    Text("Satellite").tag("satellite")
                    Text("Hybrid").tag("hybrid")
                }
            }
            
            Section(header: Text("Map Features")) {
                Toggle("Show Traffic", isOn: .constant(false))
                Toggle("Show 3D Buildings", isOn: .constant(true))
            }
        }
        .navigationTitle("Map Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @AppStorage("soundEnabled") var soundEnabled = true
    @AppStorage("vibrationEnabled") var vibrationEnabled = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }
            
            if notificationsEnabled {
                Section(header: Text("Notification Preferences")) {
                    Toggle("Sound", isOn: $soundEnabled)
                    Toggle("Vibration", isOn: $vibrationEnabled)
                }
                
                Section(header: Text("Notification Types")) {
                    Toggle("New Places Nearby", isOn: .constant(true))
                    Toggle("Friend Activity", isOn: .constant(true))
                    Toggle("Weekly Summary", isOn: .constant(true))
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(placesViewModel: DecodedPlacesViewModel())
    }
}
