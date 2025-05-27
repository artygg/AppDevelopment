//
//  DecodedPlacesViewModel.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-21.
//

import Foundation

@MainActor
class DecodedPlacesViewModel: ObservableObject {
    @Published var places: [DecodedPlace] = []
    private let urlString = "http://localhost:8080/places"
    func fetchPlaces() async {
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            places = try JSONDecoder().decode([DecodedPlace].self, from: data)
        } catch {
            print("Failed to fetch places:", error)
        }
    }
    func markCaptured(_ id: UUID) {
        if let idx = places.firstIndex(where: { $0.id == id }) {
            places[idx].isCaptured = true
        }
    }
}
