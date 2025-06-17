import Foundation

@MainActor
class DecodedPlacesViewModel: ObservableObject {
    @Published var places: [DecodedPlace] = []
    
    private struct CaptureResponse: Decodable {
        let place: DecodedPlace
        let quiz: Quiz?
    }
    
    private let urlString = "\(Config.apiURL)/places"

    func fetchPlaces(iconMapping: [String: String]) async {
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print("data: ", data)
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

    func capturePlace(id: Int, user: String = "player1") async -> Quiz? {
        guard let url = URL(string: "\(Config.apiURL)/api/capture") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = CaptureRequest(place_id: id, user: user)
        request.httpBody = try? JSONEncoder().encode(payload)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                let resp = try JSONDecoder().decode(CaptureResponse.self, from: data)
                // локально отмечаем место захваченным
                markCaptured(resp.place.id)
                return resp.quiz            // может быть nil
            }
            return nil
        } catch {
            print("Failed to capture place on backend:", error)
            return nil
        }
    }
}
