//
//  CategoryIconLoader.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-21.
//

import Foundation

@MainActor
class CategoryIconLoader: ObservableObject {
    @Published var mapping: [String: String] = [:]
    private let urlString = "\(Config.apiURL)/category_icons.json"

    func fetchIcons() async {
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let icons = try JSONDecoder().decode([String: String].self, from: data)
            mapping = icons
        } catch {
            print("Failed to fetch category icons:", error)
        }
    }
}

