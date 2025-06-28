import Foundation

let passCount   = 1
let defaultTime = 15  

struct Quiz: Codable {
    let place_id: Int
    var questions: [QuizQuestion]
}

struct QuizQuestion: Identifiable, Codable {
    let id: String
    let text: String
    let options: [String]
    let answer: Int
    var timeLimit: Int

    enum CodingKeys: String, CodingKey { case id,text,options,answer,timeLimit }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(String.self, forKey: .id)
        text      = try c.decode(String.self, forKey: .text)
        options   = try c.decode([String].self, forKey: .options)
        answer    = try c.decode(Int.self,    forKey: .answer)
        timeLimit = try c.decodeIfPresent(Int.self, forKey: .timeLimit) ?? defaultTime
    }

    init(id: String,
         text: String,
         options: [String],
         answer: Int,
         timeLimit: Int = defaultTime) {

        self.id = id
        self.text = text
        self.options = options
        self.answer = answer
        self.timeLimit = timeLimit
    }
}
