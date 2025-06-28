import Foundation

struct MineRequest: Encodable {
    let place_id: Int
    let qid:      String
    let user:     String
}

struct MineResponse: Decodable {
    let mine_balance: Int
}

struct MinedResponse: Decodable {
    let qids: [String]
}

enum MineService {

    static func plantMine(placeID: Int,
                          qid: String,
                          user: String) async throws -> Int {

        let url = URL(string: "\(Config.apiURL)/api/mine")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(
            MineRequest(place_id: placeID, qid: qid, user: user)
        )

        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(MineResponse.self, from: data).mine_balance
    }

    static func fetchBalance(for user: String) async throws -> Int {
        let url = URL(string: "\(Config.apiURL)/api/mines?user=\(user)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        struct Resp: Decodable { let balance: Int }
        return try JSONDecoder().decode(Resp.self, from: data).balance
    }

    static func fetchMined(placeID: Int) async throws -> Set<String> {
        let url = URL(string: "\(Config.apiURL)/api/mines/list?place_id=\(placeID)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return Set(try JSONDecoder().decode(MinedResponse.self, from: data).qids)
    }
}
