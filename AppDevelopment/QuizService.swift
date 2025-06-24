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
        } catch { return nil }
    }

    static func handleQuizForPlace(
        _ place: DecodedPlace,
        setLoading: @escaping (Bool) -> Void,
        setQuiz: @escaping (Quiz?) -> Void
    ) async {
        let loadedQuiz = await QuizService.fetchQuiz(placeID: place.id)
        await MainActor.run {
            setLoading(false)
            setQuiz(loadedQuiz)
        }
    }
}
