//
//  MineService.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-18.
//

import Foundation
import SwiftUI

struct MineRequest: Encodable {
    let place_id: Int
    let qid: String
}

enum MineService {
    static func plantMine(placeID: Int, qid: UUID) async {
        guard let url = URL(string: "http://localhost:8080/api/mine") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = MineRequest(place_id: placeID, qid: qid.uuidString)
        req.httpBody = try? JSONEncoder().encode(body)
        _ = try? await URLSession.shared.data(for: req)
    }
}
