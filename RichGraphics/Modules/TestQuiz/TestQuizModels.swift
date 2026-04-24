import SwiftUI

// MARK: - Quiz Data Model
//
// A quiz is a sequence of QuizQuestion entries. Each question has:
// - The prompt text (shown first)
// - The answer (revealed with animation on "정답확인" tap)
// - Optional explanation content (comparison table, image, extended text, ...)
// The explanation is modelled as an enum so we can add new formats as we
// build out more quiz pages without forcing every question into the same shape.

struct QuizQuestion: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let explanation: QuizExplanation
}

enum QuizExplanation {
    case comparisonTable(ComparisonTable)
    case text(String)
    case none
}

struct ComparisonTable {
    let headerA: String
    let headerB: String
    let rows: [ComparisonRow]
}

struct ComparisonRow: Identifiable {
    let id = UUID()
    let label: String
    let optionA: String
    let optionB: String
}

// MARK: - Catalogue

extension QuizQuestion {
    @MainActor static let all: [QuizQuestion] = [
        QuizQuestion(
            question: "축구장에서 공이 움직이는 경로를 표현하는데 적합한 SwiftUI 애니메이션 방식은?",
            answer: "키프레임 애니메이션",
            explanation: .comparisonTable(ComparisonTable(
                headerA: "PhaseAnimator",
                headerB: "KeyframeAnimator",
                rows: [
                    ComparisonRow(label: "역할", optionA: "상태 머신 (statemachine)", optionB: "타임라인 애니메이션"),
                    ComparisonRow(label: "각 단계", optionA: "개별 이름을 가진 phase", optionB: "절대 시간을 가진 keyframe"),
                    ComparisonRow(label: "제어 단위", optionA: "하나의 phase = 하나의 정적 스타일", optionB: "하나의 프로퍼티 = 시간별 보간"),
                    ComparisonRow(label: "타이밍", optionA: "각 phase 전환 시 Animation 지정", optionB: "시간·곡선 명시적 제어"),
                    ComparisonRow(label: "적합한 곳", optionA: "로딩, 펄스, 상태 표시", optionB: "복잡한 동작 시퀀스 (바운스, 궤적)"),
                ]
            ))
        ),
        // 추가 페이지는 여기에 append
    ]
}
