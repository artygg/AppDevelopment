//
//  DecodedPlacesViewModel.swift
//  AppDevelopment
//
//  Created by Ekaterina Tarlykova on 2025-05-21.
//

import Foundation

@MainActor
class DecodedPlacesViewModel: ObservableObject {
    @Published var places: [DecodedPlace] = []
    private let urlString = "http://localhost:8080/places" // Change if backend address differs

    func fetchPlaces() async {
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let loadedPlaces = try JSONDecoder().decode([DecodedPlace].self, from: data)
            places = loadedPlaces
        } catch {
            print("Failed to fetch places:", error)
        }
    }
}
