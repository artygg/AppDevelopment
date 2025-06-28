//
//  ProfileModel.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-27.
//

import SwiftUI
import CoreLocation

struct APIConfig {
    static let baseURL = Config.apiURL
}


struct CapturedPlaceResponse: Decodable {
    let name:          String
    let latitude:      Double
    let longitude:     Double
    let category_id:   Int
    let captured:      Bool
    let user_captured: String
}

struct ProfileImage: Decodable, Identifiable {
    let id:         Int
    let image_url:  String
    
    var name: String {
        if let fileName = URL(string: image_url)?.lastPathComponent {
            let raw = fileName
                .replacingOccurrences(of: "\\.[^.]*$", with: "", options: .regularExpression)
            return raw.replacingOccurrences(of: "_", with: " ").capitalized
        }
        return "Avatar \(id)"
    }
    var url: String { image_url }
}

struct UpdateMapImageRequest: Codable {
    let imageURL: String
    enum CodingKeys: String, CodingKey { case imageURL = "image_url" }
}

struct RegisterRequest: Codable { let username, email, password: String }
struct LoginRequest:    Codable { let username, password: String }

struct AuthResponse: Codable {
    let user: User
    let token: String
    let refreshToken: String?
    let expiresAt: Int?
    
    enum CodingKeys: String, CodingKey {
        case user, token
        case refreshToken = "refresh_token"
        case expiresAt    = "expires_at"
    }
}

struct User: Codable {
    let id: Int
    let username, email: String
    let createdAt, updatedAt: String
    let isActive: Bool
    let lastLoginAt: String?
    let mapImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
        case createdAt    = "created_at"
        case updatedAt    = "updated_at"
        case isActive     = "is_active"
        case lastLoginAt  = "last_login_at"
        case mapImageUrl  = "map_image_url"
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @AppStorage("isLoggedIn")        var isLoggedIn        = false
    @AppStorage("username")          var username          = ""
    @AppStorage("userEmail")         var userEmail         = ""
    @AppStorage("selectedAvatarURL") var selectedAvatarURL = ""
    @AppStorage("mineCount")         var mineCount         = 0
    
    @Published var showSettings     = false
    @Published var showAuthSheet    = false
    @Published var showAllPlaces    = false
    @Published var ownerQuizSheet   = false
    @Published var loadingOwnerQuiz = false
    
    @Published var ownerQuiz: Quiz?  = nil
    
    
    @Published private(set) var capturedPlaces: [Place] = []
    
    private weak var placesVM: DecodedPlacesViewModel?
    @Published var showImagePicker = false

    
    func bind(placesVM: DecodedPlacesViewModel) {
        self.placesVM = placesVM
        refreshCapturedPlaces()
    }
    
    func refreshCapturedPlaces() {
        guard let vm = placesVM else { return }
        capturedPlaces = vm.places
            .filter { $0.captured && $0.user_captured == username }
            .map {
                Place(name:         $0.name,
                      coordinate:    $0.clCoordinate,
                      placeIcon:     $0.iconName,
                      isCaptured:    $0.captured,
                      user_captured: $0.user_captured)
            }
    }
    
    func loadOwnerQuiz(for place: Place, in vm: DecodedPlacesViewModel) async {
        guard let decoded = vm.places.first(where: {
            $0.name == place.name &&
            $0.user_captured == username
        }) else { return }
        
        loadingOwnerQuiz = true
        let q = await QuizService.fetchQuiz(placeID: decoded.id)
        ownerQuiz       = q
        ownerQuizSheet  = q != nil
        loadingOwnerQuiz = false
    }
    
    func logout() {
        APIService.shared.logout { [weak self] _ in
            Task { @MainActor in self?.clearLoginData() }
        }
    }
    
    private func clearLoginData() {
        isLoggedIn        = false
        username          = ""
        userEmail         = ""
        selectedAvatarURL = ""
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
}
