import Foundation

@MainActor
class DecodedPlacesViewModel: ObservableObject {
    @Published var places: [DecodedPlace] = []
    private struct CaptureResponse: Decodable {
        let place: DecodedPlace
        let quiz:  Quiz?
    }
    private let urlString = "http://localhost:8080/places"

    func fetchPlaces(iconMapping: [String: String]) async {
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            var decodedPlaces = try JSONDecoder().decode([DecodedPlace].self, from: data)
            for idx in decodedPlaces.indices {
                let catIDString = "\(decodedPlaces[idx].category_id)"
                decodedPlaces[idx].iconName = iconMapping[catIDString] ?? "mappin.circle.fill"
            }
            self.places = decodedPlaces
        } catch {
            print("Failed to fetch places:", error)
        }
    }

    func markCaptured(_ id: Int) {
        if let idx = places.firstIndex(where: { $0.id == id }) {
            places[idx].captured = true
        }
    }

    @MainActor
    func capturePlace(id: Int, user: String) async -> Quiz? {
        guard let url = URL(string: "http://localhost:8080/api/capture") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(
            CaptureRequest(place_id: id, user: user)
        )

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            let resp = try JSONDecoder().decode(CaptureResponse.self, from: data)

            // локально отмечаем место захваченным
            markCaptured(resp.place.id)

            return resp.quiz            // может быть nil
        } catch {
            print("capturePlace error:", error)
            return nil
        }
    }
}
