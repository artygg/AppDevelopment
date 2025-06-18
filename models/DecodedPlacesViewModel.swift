//
//  DecodedPlacesViewModel.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-22.
//

import Foundation
import SwiftUI

@MainActor
class DecodedPlacesViewModel: ObservableObject {
    @Published var places: [DecodedPlace] = []

    @AppStorage("username") private var currentUser: String = "player1"
    private let baseURL = Config.apiURL

    // MARK: – DTO
    private struct CaptureReq: Codable {
        let place_id: Int
        let user:     String
        let passed:   Bool
    }

    // MARK: – Fetch places
    func fetchPlaces(iconMapping: [String: String]) async {
        guard let url = URL(string: "\(baseURL)/places") else { return }

        var req = URLRequest(url: url)
        req.setValue(currentUser, forHTTPHeaderField: "X-Player")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)

            let iso: ISO8601DateFormatter = {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f
            }()
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { d in
                let s = try String(from: d)
                if let t = iso.date(from: s) { return t }
                throw DecodingError.dataCorrupted(
                    .init(codingPath: d.codingPath,
                          debugDescription: "Bad date: \(s)"))
            }

            var decoded = try decoder.decode([DecodedPlace].self, from: data)
            for i in decoded.indices {
                decoded[i].iconName =
                    iconMapping["\(decoded[i].category_id)"] ?? "mappin.circle.fill"
            }
            places = decoded
        } catch {
            print("fetchPlaces:", error)
        }
    }

    // MARK: – Local state helpers
    func markCaptured(_ id: Int) {
        if let idx = places.firstIndex(where: { $0.id == id }) {
            places[idx].captured      = true
            places[idx].user_captured = currentUser
        }
    }

    // MARK: – Inform backend (success / fail)
    func sendCapture(placeID: Int, passed: Bool) async {
        guard let url = URL(string: "\(baseURL)/api/capture") else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = CaptureReq(
            place_id: placeID,
            user:     currentUser,
            passed:   passed
        )
        req.httpBody = try? JSONEncoder().encode(payload)

        _ = try? await URLSession.shared.data(for: req)
    }
}
