//
//  FinishRequest.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-18.
//

import Foundation
import SwiftUI

struct FinishRequest: Codable {
    let place_id: Int
    let user:     String
    let correct:  Int
    let elapsed_ms: Int
}

struct FinishResp: Codable {
    let captured:      Bool
    let mine_balance:  Int?
    let quiz:          Quiz?
}

enum ResultService {
    static func send(_ body: FinishRequest) async throws -> FinishResp {
        let url = URL(string: "\(Config.apiURL)/api/finish")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(FinishResp.self, from: data)
    }
}
