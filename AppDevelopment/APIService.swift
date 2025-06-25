//
//  APIService.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 25/06/2025.
//

import SwiftUI

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
