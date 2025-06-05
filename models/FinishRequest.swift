//
//  FinishRequest.swift
//  AppDevelopment
//
//  Created by Ekaterina on 05/06/2025.
//


import Foundation
import SwiftUI

struct FinishRequest: Codable {
    let place_id: Int
    let user:     String
    let correct:  Int
    let elapsed_ms: Int
}

enum ResultService {
    static func send(_ body: FinishRequest) async -> Bool {
        guard let url = URL(string: "http://localhost:8080/api/finish") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(body)
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            return (try? JSONDecoder().decode([String:Bool].self, from: data))?["captured"] ?? false
        } catch { return false }
    }
}
