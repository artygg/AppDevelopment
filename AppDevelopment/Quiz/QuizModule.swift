import Foundation

let passCount = 1
let defaultTime = 15

struct Quiz: Codable {
    let place_id: Int
    var questions: [QuizQuestion]
}

struct QuizQuestion: Codable, Identifiable {
    let id: String
    let text: String
    let options: [String]
    let answer: Int
    var timeLimit: Int? = nil
}
