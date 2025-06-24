import Foundation
import SwiftUI

struct MineRequest: Encodable {
    let place_id: Int
    let qid: String
}

enum MineService {
    static func plantMine(placeID: Int, qid: String) async throws {
        print("MineService.plantMine starting...")
        print("Config.apiURL: \(Config.apiURL)")
        
        guard let url = URL(string: "\(Config.apiURL)/api/mine") else {
            print("Invalid URL: \(Config.apiURL)/api/mine")
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
        }
        
        print("URL created: \(url)")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = MineRequest(place_id: placeID, qid: qid)
        print("Request body: \(body)")
        
        do {
            req.httpBody = try JSONEncoder().encode(body)
            print("Request body encoded successfully")
        } catch {
            print("Failed to encode request body: \(error)")
            throw error
        }
        
        print("Making network request...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            
            print("Network request completed")
            print("Response data size: \(data.count) bytes")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
                print("Response headers: \(httpResponse.allHeaderFields)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
                
                if httpResponse.statusCode == 201 {
                    print("Mine planted successfully (201)")
                    return
                } else {
                    let errorMsg = "HTTP Error \(httpResponse.statusCode)"
                    print("\(errorMsg)")
                    throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                }
            } else {
                print("No HTTP response received")
                throw NSError(domain: "NoHTTPResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
            }
        } catch {
            print("Network request failed: \(error)")
            print("Error type: \(type(of: error))")
            throw error
        }
    }
}
