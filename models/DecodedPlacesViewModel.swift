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
    private var fetchingTask: Task<Void, Never>?
    private var iconMapping: [String: String] = [:]

    // MARK: – DTO
    private struct CaptureReq: Codable {
        let place_id: Int
        let user:     String
        let passed:   Bool
    }
    
    private struct FinishReq: Codable {
        let place_id:   Int
        let user:       String
        let correct:    Int
        let elapsed_ms: Int
    }
    
    private struct FinishResp: Codable {
        let captured: Bool
        let quiz:     Quiz?
    }

    func startPeriodicFetching(iconMapping: [String: String]) {
        self.iconMapping = iconMapping
        
        fetchingTask?.cancel()

        fetchingTask = Task {
            while true {
                await fetchPlaces()
                do {
                    try await Task.sleep(for: .seconds(5))
                } catch {
                    // Task was cancelled.
                    return
                }
            }
        }
    }

    func stopPeriodicFetching() {
        fetchingTask?.cancel()
    }
//
//    deinit {
//        stopPeriodicFetching()
//    }

    // MARK: – Fetch places
    func fetchPlaces() async {
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
                    self.iconMapping["\(decoded[i].category_id)"] ?? "mappin.circle.fill"
            }
            places = decoded
            for (index, place) in decoded.enumerated() {
                print("Place \(index + 1): Captured → \(place.captured ? "Yes" : "No")")
            }
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
    
    func finishAttempt(placeID: Int,
                       correct: Int,
                       elapsed: Int) async -> (Bool, Quiz?) {

        guard let url = URL(string: "\(baseURL)/api/finish") else { return (false,nil) }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Req: Codable {
            let place_id:   Int
            let user:       String
            let correct:    Int
            let elapsed_ms: Int
        }
        struct Resp: Codable {
            let captured: Bool
            let quiz:     Quiz?
        }

        req.httpBody = try? JSONEncoder().encode(
            Req(place_id: placeID, user: currentUser,
                correct: correct, elapsed_ms: elapsed)
        )

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let r = try JSONDecoder().decode(Resp.self, from: data)

            if r.captured {
                markCaptured(placeID)
            }
            return (r.captured, r.quiz)
        } catch {
            print("finishAttempt:", error)
            return (false, nil)
        }
    }
    
    func sendCapture(placeID: Int, passed: Bool) async {
        guard let url = URL(string: "\(baseURL)/api/capture") else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("Users: \(currentUser)")

        let payload = CaptureReq(
            place_id: placeID,
            user:     currentUser,
            passed:   passed
        )
        req.httpBody = try? JSONEncoder().encode(payload)

        _ = try? await URLSession.shared.data(for: req)
    }
}
