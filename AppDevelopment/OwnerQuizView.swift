import SwiftUI

let minedTime = 5

struct OwnerQuizView: View {
    @Binding var mineCount: Int

    @State private var mined: Set<String>
    @State private var quiz: Quiz
    let onClose: () -> Void

    init(mineCount: Binding<Int>, quiz: Quiz, onClose: @escaping () -> Void) {
        self._mineCount = mineCount
        self._quiz      = State(initialValue: quiz)
        self.onClose    = onClose

        let preMined = quiz.questions
            .filter { $0.timeLimit == minedTime }
            .map(\.id)

        _mined = State(initialValue: Set(preMined))
        
        print("OwnerQuizView init - placeID: \(quiz.place_id), questions: \(quiz.questions.count), preMined: \(preMined)")
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(quiz.questions) { q in
                    HStack {
                        Text(q.text)
                            .font(.body)
                            .lineLimit(2)
                        Spacer()

                        if mined.contains(q.id) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        } else {
                            Button("Mine (\(mineCount))") {
                                print("Button tapped for q.id: \(q.id)")
                                print("Current mineCount: \(mineCount)")
                                print("Already mined: \(mined.contains(q.id))")
                                
                                guard !mined.contains(q.id), mineCount > 0 else {
                                    print("Guard failed - already mined: \(mined.contains(q.id)), mineCount: \(mineCount)")
                                    return
                                }
                                
                                print("Starting mine task...")
                                
                                Task {
                                    do {
                                        print("Calling MineService.plantMine...")
                                        print("API URL: \(Config.apiURL)")
                                        print("PlaceID: \(quiz.place_id), QID: \(q.id)")
                                        
                                        try await MineService.plantMine(
                                            placeID: quiz.place_id,
                                            qid: q.id
                                        )
                                        
                                        print("MineService.plantMine completed successfully")
                                        
                                        await MainActor.run {
                                            print("Updating UI state...")
                                            mined.insert(q.id)
                                            mineCount -= 1
                                            
                                            if let idx = quiz.questions.firstIndex(where: { $0.id == q.id }) {
                                                quiz.questions[idx].timeLimit = minedTime
                                                print("Updated question timeLimit at index \(idx)")
                                            }
                                            
                                            print("UI state updated - new mineCount: \(mineCount)")
                                        }
                                        
                                        print("Planted mine on q.id: \(q.id)")
                                    } catch {
                                        print("Failed to plant mine: \(error)")
                                        print("Error details: \(error.localizedDescription)")
                                        if let nsError = error as NSError? {
                                            print("Error domain: \(nsError.domain), code: \(nsError.code)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowSeparator(.hidden)
                    .onAppear {
                        print("Rendering question id: \(q.id), already mined: \(mined.contains(q.id))")
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Plant mines")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
        .onAppear {
            print("OwnerQuizView appeared")
        }
    }
}
