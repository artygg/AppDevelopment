//
//  CreatePlaceRequest.swift
//  AppDevelopment
//
//  Created by Artyom Grishayev on 05/06/2025.
//
import Foundation

struct CreatePlaceRequest: Encodable {
    let name: String
    let latitude: Double
    let longitude: Double
    let category_id: Int
}


struct PlaceResponse: Decodable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let category_id: Int
    let captured: Bool
    let user_captured: String?
}


func createPlace(
    _ requestBody: CreatePlaceRequest,
    completion: @escaping (Result<PlaceResponse, Error>) -> Void
) {
    guard let url = URL(string: "\(Config.apiURL)/api/places") else {
        completion(.failure(NSError(
            domain: "PlaceAPI",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
        )))
        return
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    if let token = UserDefaults.standard.string(forKey: "authToken") {
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    } else {
        completion(.failure(NSError(
            domain: "PlaceAPI",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "No JWT token found. Please log in."]
        )))
        return
    }
    
    do {
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(requestBody)
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: urlRequest) { data, response, error in
        if let error = error {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            let msg = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            DispatchQueue.main.async {
                let err = NSError(
                    domain: "PlaceAPI",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Server returned \(http.statusCode): \(msg)"]
                )
                completion(.failure(err))
            }
            return
        }
        
        guard let data = data else {
            let err = NSError(
                domain: "PlaceAPI",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No data returned"]
            )
            DispatchQueue.main.async {
                completion(.failure(err))
            }
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let placeResponse = try decoder.decode(PlaceResponse.self, from: data)
            DispatchQueue.main.async {
                completion(.success(placeResponse))
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }.resume()
}
