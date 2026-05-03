import SwiftUI

// MARK: - Quiz Sheet (entry point)

struct TestQuizSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages = QuizPage.all

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        Group {
                            switch page {
                            case .question(let q):
                                QuizPageView(question: q)
                            case .info(let info):
                                InfoPageView(info: info)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: pages.count > 1 ? .always : .never))
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
    @State private var selectedOption: String?
    @State private var revealed = false
    @State private var showExplanation = false

    private let optionColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

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
                    .padding(.bottom, 28)

                // 4 multiple-choice options (2 × 2 grid)
                LazyVGrid(columns: optionColumns, spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        optionButton(for: option)
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 28)

                // Reveal area: button and answer+explanation share the same
                // layout slot (ZStack) so toggling `revealed` doesn't resize
                // the view. The VStack inside always occupies its natural size
                // — even when invisible — which fixes the total height.
                ZStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Text("A.")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.yellow.opacity(0.8))
                            Text(question.answer)
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundStyle(.yellow)
                        }
                        .padding(.horizontal, 24)
                        .opacity(revealed ? 1 : 0)
                        .offset(y: revealed ? 0 : 20)

                        explanationView
                            .padding(.horizontal, 16)
                            .opacity(showExplanation ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                            revealed = true
                        }
                        // Explanation appears after the answer rise animation,
                        // but itself is not animated.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            showExplanation = true
                        }
                    } label: {
                        Text("정답확인")
                            .font(.headline)
                            .foregroundStyle(selectedOption == nil ? .gray : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                selectedOption == nil ? Color.white.opacity(0.4) : Color.white,
                                in: Capsule()
                            )
                    }
                    .disabled(selectedOption == nil)
                    .padding(.horizontal, 24)
                    .opacity(revealed ? 0 : 1)
                    .allowsHitTesting(!revealed)
                }
                .padding(.bottom, 60)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: Option button

    private func optionButton(for option: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedOption = option
            }
        } label: {
            Text(option)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, 12)
                .multilineTextAlignment(.center)
                .background(optionBackground(for: option))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(optionBorder(for: option), lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(revealed)
    }

    private func optionBackground(for option: String) -> Color {
        if revealed {
            // After reveal: correct = green tint, your wrong pick = red tint,
            // others = neutral.
            if option == question.answer {
                return Color.green.opacity(0.25)
            } else if option == selectedOption {
                return Color.red.opacity(0.25)
            } else {
                return Color(white: 0.13)
            }
        } else {
            // Before reveal: chosen option highlighted yellow.
            return option == selectedOption
                ? Color.yellow.opacity(0.18)
                : Color(white: 0.13)
        }
    }

    private func optionBorder(for option: String) -> Color {
        if revealed {
            if option == question.answer { return .green }
            if option == selectedOption { return .red }
            return Color(white: 0.28)
        } else {
            return option == selectedOption ? .yellow : Color(white: 0.28)
        }
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

// MARK: - Info Page (image + heading, non-interactive)

struct InfoPageView: View {
    let info: InfoPage

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 24)

                if let imageName = info.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                }

                Text(info.heading)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if let body = info.body {
                    Text(body)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer(minLength: 60)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
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
