//
//  QuizService.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-22.
//

import Foundation

struct QuizService {
    /// Fetch a quiz for a given place, retrying if needed.
    static func fetchQuiz(for placeName: String, maxAttempts: Int = 3) async -> Quiz? {
        let urlString = "http://localhost:8080/quiz?place=\(placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        for attempt in 1...maxAttempts {
            do {
                guard let url = URL(string: urlString) else { return nil }
                let (data, _) = try await URLSession.shared.data(from: url)
                let quiz = try JSONDecoder().decode(Quiz.self, from: data)
                if !quiz.questions.isEmpty && quiz.questions.allSatisfy({ !$0.text.isEmpty }) {
                    return quiz
                }
            } catch {
                print("Attempt \(attempt): Quiz fetch/decode failed, retrying...")
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        print("Failed to get valid quiz after \(maxAttempts) attempts.")
        return nil
    }

    /// Helper to fetch quiz and assign to state in MainActor
    static func handleQuizForPlace(
        _ place: DecodedPlace,
        setLoading: @escaping (Bool) -> Void,
        setQuiz: @escaping (Quiz?) -> Void
    ) async {
        let loadedQuiz = await fetchQuiz(for: place.name)
        await MainActor.run {
            setLoading(false)
            setQuiz(loadedQuiz)
        }
    }
}

