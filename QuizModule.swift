//
//  QuizModule.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-22.
//

import SwiftUI

struct Quiz: Codable {
    let place_id: String
    let questions: [QuizQuestion]
}

struct QuizQuestion: Codable {
    let text: String
    let options: [String]
    let answer: Int
}

struct QuizView: View {
    let quiz: Quiz
    let place: DecodedPlace
    var onDismiss: (_ captured: Bool) -> Void

    @State private var selected: Int? = nil
    @State private var questionIndex: Int = 0
    @State private var correctCount: Int = 0
    @State private var showResult: Bool = false

    let passCount = 5

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack {
                    Button(action: { onDismiss(false) }) {
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
                    .padding(.bottom, 2)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                Text("Question \(questionIndex + 1) of \(quiz.questions.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                Divider()
            }
            .background(Color.white.ignoresSafeArea(edges: .top))
            .padding(.bottom, 12)

            Spacer(minLength: 0)

            if !showResult {
                let q = quiz.questions[questionIndex]
                VStack(spacing: 18) {
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
                        Button(action: {
                            withAnimation { selected = i }
                        }) {
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
                                .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        .disabled(selected != nil)
                    }
                }
                .animation(.easeInOut, value: selected)
                .padding(.bottom, 28)
            }

            Spacer()

            VStack {
                Divider()
                if showResult {
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
                            Button("Done") { onDismiss(true) }
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
                } else {
                    Button(action: {
                        if let selected = selected {
                            if selected == quiz.questions[questionIndex].answer { correctCount += 1 }
                            if questionIndex + 1 < quiz.questions.count {
                                questionIndex += 1
                                self.selected = nil
                            } else {
                                showResult = true
                            }
                        }
                    }) {
                        Text(questionIndex + 1 == quiz.questions.count ? "Finish" : (selected == nil ? "Select an answer" : "Next"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .disabled(selected == nil)
                }
            }
            .background(Color.white)
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(color: .black.opacity(0.07), radius: 7, x: 0, y: -4)
            .padding(.top, 8)
        }
        .background(Color(white: 0.95).ignoresSafeArea())
    }
}
