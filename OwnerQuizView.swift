//  OwnerQuizView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-18.
//

import SwiftUI
let minedTime = 5

struct OwnerQuizView: View {
    @Binding var mineCount: Int

    // ❶ Populate mined from the quiz we get from the server
    @State private var mined: Set<String>

    
    @State private var quiz: Quiz
    let onClose: () -> Void

    // ❷ Custom init so we can seed mined
    init(mineCount: Binding<Int>, quiz: Quiz, onClose: @escaping () -> Void) {
        self._mineCount = mineCount
        self._quiz      = State(initialValue: quiz)
        self.onClose    = onClose

        // every question with the 5-second limit was mined before
        let preMined = quiz.questions
            .filter { $0.timeLimit == minedTime }
            .map(\.id)

        _mined = State(initialValue: Set(preMined))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(quiz.questions) { q in
                    HStack {
                        Text(q.text).font(.body).lineLimit(2)
                        Spacer()
                        if mined.contains(q.id) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        } else if mineCount > 0 {
                            Button {
                                mined.insert(q.id)
                                mineCount -= 1
                                if let idx = quiz.questions.firstIndex(where: { $0.id == q.id }) {
                                        quiz.questions[idx].timeLimit = minedTime
                                    }
                                Task {
                                    await MineService.plantMine(
                                        placeID: quiz.place_id,
                                        qid:     q.id
                                    )
                                }
                            } label: {
                                Image(systemName: "burst.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Plant mines")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
    }
}
