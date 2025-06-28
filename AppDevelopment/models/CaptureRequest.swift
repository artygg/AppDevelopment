//
//  CaptureRequest.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-03.
//

import Foundation

struct CaptureRequest: Encodable {
    let place_id: Int
    let user:     String
    let passed:   Bool
}

struct CaptureResponse: Decodable {
    let captured:     Bool
    let quiz:         Quiz?
    let mine_balance: Int
}

enum CaptureService {
    static func send(_ body: CaptureRequest) async throws -> CaptureResponse {
        guard let url = URL(string: "\(Config.apiURL)/api/capture") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(CaptureResponse.self, from: data)
    }
}
