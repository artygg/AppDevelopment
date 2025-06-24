//
//  LeaderboardViewModel.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-18.
//

import Foundation

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var rows: [LeaderboardEntry] = []

    func fetch(limit: Int = 100) async {
        guard let url = URL(string: "\(Config.apiURL)/leaderboard?limit=\(limit)") else { return }
        do {
            let (d, _) = try await URLSession.shared.data(from: url)
            rows = try JSONDecoder().decode([LeaderboardEntry].self, from: d)
        } catch { rows = [] }
    }
}
