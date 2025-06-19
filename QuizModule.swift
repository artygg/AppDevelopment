import SwiftUI

private let passCount = 1
private let defaultTime = 15

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

struct QuizView: View {
    let quiz: Quiz
    let place: DecodedPlace
    var onFinish: (_ correct: Int, _ elapsed: Int) -> Void

    @State private var selected: Int? = nil
    @State private var skipped = false
    @State private var questionIndex: Int = 0
    @State private var correctCount: Int = 0
    @State private var showResult: Bool = false

    @State private var secondsLeft = defaultTime
    @State private var timer: Timer? = nil

    @State private var startTime = DispatchTime.now()
    @State private var elapsedMs = 0

    // New camera states
    @State private var showCamera = false
    @State private var capturedImage: UIImage? = nil

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
                Button("Close") { onFinish(0, 0) }
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
            }
        }
        .onAppear {
            if questionIndex == 0 {
                correctCount = 0
                startTime = .now()
            }
            startTimer(for: q)
        }
        .animation(.easeInOut, value: selected)
        .padding(.bottom, 28)
    }

    private var footer: some View {
        VStack {
            Divider()
            if showResult {
                resultView
            } else {
                HStack {
                    Button("Skip") {
                        skipped = true
                        proceedAfterAnswer()
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                    Spacer(minLength: 12)

                    nextButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
        .background(Color.white)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.07), radius: 7, x: 0, y: -4)
        .padding(.top, 8)
    }

    private var nextButton: some View {
        Button {
            proceedAfterAnswer()
        } label: {
            Text(questionIndex + 1 == quiz.questions.count ? "Finish" : "Next")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
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
                    onFinish(correctCount, elapsedMs)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Button("Take a Photo") {
                    showCamera = true
                }
                .buttonStyle(.bordered)
                .tint(.blue)

            } else {
                Text("Try again to capture the place!")
                    .font(.title3)
                    .foregroundColor(.red)

                Button("Close") {
                    onFinish(correctCount, elapsedMs)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $capturedImage)
                .onDisappear {
                    if let image = capturedImage,
                       let data = image.jpegData(compressionQuality: 0.8) {
                        ImageService.uploadImage(data, placeID: place.id)
                    }
                }
        }
        .padding(.vertical, 16)
    }

    private func startTimer(for question: QuizQuestion) {
        timer?.invalidate()
        secondsLeft = question.timeLimit ?? defaultTime
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsLeft > 0 {
                secondsLeft -= 1
            }
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

        if !skipped,
           let choice = selected,
           choice == quiz.questions[questionIndex].answer {
            correctCount += 1
        }

        skipped = false
        selected = nil

        if questionIndex + 1 < quiz.questions.count {
            questionIndex += 1
            selected = nil
            startTimer(for: quiz.questions[questionIndex])
        } else {
            finishQuiz()
        }
    }
}
