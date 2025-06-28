//
//  OwnerQuizView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 08-06-2025.
//

import SwiftUI

private let minedTime = 5
private let corner    = CGFloat(22)

struct OwnerQuizView: View {
    @Binding var mineCount: Int
    let        onClose: () -> Void

    @State private var quiz:  Quiz
    @State private var mined: Set<String>

    @Environment(\.colorScheme)      private var scheme
    @Environment(\.dismiss)          private var dismiss

    init(mineCount: Binding<Int>, quiz: Quiz, onClose: @escaping () -> Void) {
        _mineCount = mineCount
        _quiz      = State(initialValue: quiz)
        self.onClose = onClose

        let alreadyMined = quiz.questions
            .filter { $0.timeLimit == minedTime }
            .map(\.id)
        _mined = State(initialValue: Set(alreadyMined))
        print("💣 OwnerQuizView init – place \(quiz.place_id) – pre-mined \(alreadyMined.count)")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background
                
                VStack(spacing: 24) {
                    minesLeftChip
                    questionsList
                }
            }
            .navigationTitle("Plant traps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { closeToolbar }
            .task { print("🟢 OwnerQuizView task – loaded \(quiz.questions.count) questions") }
        }
    }


    private var background: some View {
        LinearGradient(colors: scheme == .dark
                       ? [.black, .indigo]
                       : [.white, .blue.opacity(0.25)],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
        .ignoresSafeArea()
    }

    private var minesLeftChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.title3.weight(.bold))
            Text("\(mineCount)")
                .font(.title3.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.pink.gradient, in: Capsule())
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        .padding(.top, 4)
    }

    private var questionsList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(quiz.questions) { q in
                    QuestionRow(question: q,
                                mined: mined.contains(q.id),
                                canMine: mineCount > 0,
                                scheme: scheme)
                    {
                        plantMine(for: q)
                    }
                    .animation(.spring(), value: mined)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
    }

    @ToolbarContentBuilder
    private var closeToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { onClose() } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
            }
        }
    }


    private func plantMine(for q: QuizQuestion) {
        guard !mined.contains(q.id), mineCount > 0 else { return }
        Task {
            do {
                try await MineService.plantMine(placeID: quiz.place_id, qid: q.id)
                await MainActor.run {
                    mined.insert(q.id)
                    mineCount -= 1
                    if let idx = quiz.questions.firstIndex(where: { $0.id == q.id }) {
                        quiz.questions[idx].timeLimit = minedTime
                    }
                }
            } catch {
                print("❌ Failed to place mine:", error.localizedDescription)
            }
        }
    }
}

private struct QuestionRow: View {
    let question: QuizQuestion
    let mined:    Bool
    let canMine:  Bool
    let scheme:   ColorScheme
    let action:   () -> Void

    @State private var showOptions = false

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(question.text)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                
                Capsule()
                    .fill(.primary.opacity(0.08))
                    .frame(height: 2)
            }

            HStack {
                if mined {
                    Label("Mined", systemImage: "checkmark.seal.fill")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.green.opacity(0.15))
                        )
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Button {
                        action()
                    } label: {
                        Text(canMine ? "Plant mine" : "No mines left")
                            .font(.callout.weight(.bold))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                (canMine
                                 ? Color.accentColor
                                 : Color.secondary.opacity(0.2)),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(canMine ? .white : .secondary)
                    .opacity(canMine ? 1 : 0.6)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(showOptions ? 90 : 0))
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut, value: showOptions)
                    .onTapGesture { withAnimation { showOptions.toggle() } }
            }
        }
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .shadow(color: .black.opacity(scheme == .dark ? 0.6 : 0.15),
                radius: 8, y: 4)
        .onTapGesture { withAnimation(.easeOut) { showOptions.toggle() } }
    }

    private var cardBackground: some View {
        (scheme == .dark ? Color.white.opacity(0.05) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
    }
}
