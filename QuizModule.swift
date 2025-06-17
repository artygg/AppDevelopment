//
//  QuizModule.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-22.
//

import SwiftUI

private let defaultTime = 15
private let minedTime   = 5

struct Quiz: Codable {
    let place_id: Int
    let questions: [QuizQuestion]
}

struct QuizQuestion: Codable, Identifiable {
    let id: UUID
    let text: String
    let options: [String]
    let answer: Int
    var timeLimit: Int? = nil
}

struct QuizView: View {
    let quiz: Quiz
    let place: DecodedPlace
    var onDismiss: (_ captured: Bool) -> Void
    let currentUser: String

    @State private var selected: Int? = nil
    @State private var questionIndex: Int = 0
    @State private var correctCount: Int = 0
    @State private var showResult: Bool = false

    @State private var secondsLeft = defaultTime
    @State private var timer: Timer? = nil

    @State private var startTime = DispatchTime.now()
    @State private var elapsedMs = 0

    private let passCount = 5

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: 0)

            if !showResult { questionCard }

            Spacer()

            footer
        }
        .background(Color(white: 0.95).ignoresSafeArea())
        .onDisappear { timer?.invalidate() }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button { onDismiss(false) } label: {
                    Image(systemName: "xmark")
                        .font(.title)
                        .foregroundColor(.blue)
                        .padding(.horizontal)
                }
                Spacer()
            }
            Text(place.name)
                .font(.title)
                .fontWeight(.heavy)
                .foregroundColor(.blue)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)

            Text("Question \(questionIndex + 1) of \(quiz.questions.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("⏱ \(secondsLeft)s")
                .font(.subheadline)
                .foregroundColor(.red)

            Divider()
        }
        .padding(.bottom, 12)
        .background(Color.white.ignoresSafeArea(edges: .top))
    }

    private var questionCard: some View {
        let q = quiz.questions[questionIndex]

        return VStack(spacing: 18) {
            Text(q.text)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(18)
                .padding(.horizontal, 20)

            ForEach(q.options.indices, id: \.self) { i in
                Button {
                    withAnimation { selected = i }
                } label: {
                    Text(q.options[i])
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selected == i ? Color.blue : Color.white)
                        .foregroundColor(selected == i ? .white : .blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .disabled(selected != nil)
            }
        }
        .onAppear {
            if questionIndex == 0 { startTime = .now() }
            startTimer(for: q)
        }
        .animation(.easeInOut, value: selected)
        .padding(.bottom, 28)
    }

    private var footer: some View {
        VStack {
            Divider()
            if showResult { resultView } else { nextButton }
        }
        .background(Color.white)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.07), radius: 7, x: 0, y: -4)
        .padding(.top, 8)
    }

    private var nextButton: some View {
        Button {
            guard let sel = selected else { return }
            if sel == quiz.questions[questionIndex].answer { correctCount += 1 }
            proceedAfterAnswer()
        } label: {
            Text(
                questionIndex + 1 == quiz.questions.count
                ? "Finish"
                : (selected == nil ? "Select an answer" : "Next")
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .disabled(selected == nil)
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Text("Quiz Complete!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            Text("You answered \(correctCount) / \(quiz.questions.count) correctly!")
                .font(.headline)

            if correctCount >= passCount {
                Text("🎉 You captured the place!")
                    .font(.title2)
                    .foregroundColor(.green)

                Button("Done") {
                    Task {
                        let captured = await ResultService.send(
                            FinishRequest(
                                place_id:   quiz.place_id,
                                user:       currentUser,
                                correct:    correctCount,
                                elapsed_ms: elapsedMs
                            )
                        )
                        onDismiss(captured)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

            } else {
                Text("Try again to capture the place!")
                    .font(.title3)
                    .foregroundColor(.red)

                Button("Close") { onDismiss(false) }
                    .buttonStyle(.bordered)
                    .tint(.gray)
            }
        }
        .padding(.vertical, 16)
    }

    private func startTimer(for question: QuizQuestion) {
        timer?.invalidate()
        secondsLeft = question.timeLimit ?? defaultTime
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsLeft > 0 { secondsLeft -= 1 }
            if secondsLeft == 0 {
                timer?.invalidate()
                selected = -1
                proceedAfterAnswer()
            }
        }
    }

    private func proceedAfterAnswer() {
        func finishQuiz() {
            elapsedMs = Int(
                (DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
            )
            showResult = true
            timer?.invalidate()
        }

        if questionIndex + 1 < quiz.questions.count {
            questionIndex += 1
            selected = nil
            startTimer(for: quiz.questions[questionIndex])
        } else {
            finishQuiz()
        }
    }
}
