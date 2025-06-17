//
//  OwnerQuizView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-18.
//

import SwiftUI

struct OwnerQuizView: View {
    @Binding var mineCount: Int
    @State private var mined: Set<UUID> = []

    let quiz: Quiz
    let onClose: () -> Void

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
                        } else if mineCount > 0 {
                            Button {
                                mined.insert(q.id)
                                mineCount -= 1
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
