//
//  QuizService.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-22.
//



import Foundation

struct QuizService {
    static func fetchQuiz(placeID: Int) async -> Quiz? {
        guard let url = URL(string: "\(Config.apiURL)/quiz?place_id=\(placeID)") else { return nil }
        do {
            let (d, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(Quiz.self, from: d)
        } catch {
            print("⚠️ fetchQuiz error:", error)
            return nil
        }
    }

    static func handleQuizForPlace(
        _ place: DecodedPlace,
        setLoading: @escaping (Bool) -> Void,
        setQuiz: @escaping (Quiz?) -> Void
    ) async {
        let loadedQuiz = await fetchQuiz(placeID: place.id)
        guard var q = loadedQuiz else {
            print("⚠️ No quiz returned for place \(place.id)")
            await MainActor.run {
                setLoading(false)
                setQuiz(nil)
            }
            return
        }

        let allIDs = q.questions.map(\.id)
        print("🧩 Fetched quiz for place \(place.id):\n • \(q.questions.count) questions\n • IDs: \(allIDs)")

        do {
            let mined = try await MineService.fetchMined(placeID: place.id)
            print("⛏️ Mined IDs from backend (\(mined.count)):", mined)

            var matched: [String] = []
            for i in q.questions.indices {
                let id = q.questions[i].id
                if mined.contains(id) {
                    q.questions[i].timeLimit = 5
                    matched.append(id)
                }
            }
            print("✅ Questions re-timed (5s) count: \(matched.count), IDs:", matched)
        } catch {
            print("⚠️ handleQuizForPlace – fetchMined error:", error)
        }

        await MainActor.run {
            setLoading(false)
            setQuiz(q)
        }
    }
}
