import SwiftUI

// MARK: - Quiz Sheet (entry point)

struct TestQuizSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let questions = QuizQuestion.all

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $currentPage) {
                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, q in
                        QuizPageView(question: q)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: questions.count > 1 ? .always : .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            .navigationTitle("확인해 볼까요?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Single Quiz Page

struct QuizPageView: View {
    let question: QuizQuestion
    @State private var revealed = false
    @State private var showExplanation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Question
                Text("Q.")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Text(question.question)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Spacer(minLength: 40)

                if revealed {
                    // Answer text rises from bottom with opacity
                    HStack(spacing: 8) {
                        Text("A.")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.yellow.opacity(0.8))
                        Text(question.answer)
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(.yellow)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        )
                    )

                    if showExplanation {
                        explanationView
                            .padding(.horizontal, 16)
                            .padding(.bottom, 60)
                    }
                } else {
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                            revealed = true
                        }
                        // Explanation shows after the answer-rise animation
                        // completes, but without its own transition animation.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            showExplanation = true
                        }
                    } label: {
                        Text("정답확인")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white, in: Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: Explanation content

    @ViewBuilder
    private var explanationView: some View {
        switch question.explanation {
        case .comparisonTable(let table):
            ComparisonTableView(table: table)
        case .text(let text):
            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 8)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Comparison Table

struct ComparisonTableView: View {
    let table: ComparisonTable

    // Alternating row backgrounds (dark / darker) with gray gridlines between cells.
    private let headerBg = Color(white: 0.22)
    private let labelBg = Color(white: 0.22)
    private let cellBg = Color(white: 0.08)
    private let border = Color(white: 0.3)

    var body: some View {
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            // Header row
            GridRow {
                Color.clear
                    .frame(minHeight: 52)
                headerCell(table.headerA)
                headerCell(table.headerB)
            }
            // Data rows
            ForEach(table.rows) { row in
                GridRow {
                    labelCell(row.label)
                    bodyCell(row.optionA)
                    bodyCell(row.optionB)
                }
            }
        }
        .padding(1)
        .background(border)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func headerCell(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 14)
            .background(headerBg)
    }

    private func labelCell(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 6)
            .background(labelBg)
    }

    private func bodyCell(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(cellBg)
    }
}

// MARK: - Preview

#Preview("Quiz Sheet") {
    TestQuizSheet()
}

#Preview("Single Page") {
    QuizPageView(question: QuizQuestion.all[0])
        .background(Color.black)
        .preferredColorScheme(.dark)
}
