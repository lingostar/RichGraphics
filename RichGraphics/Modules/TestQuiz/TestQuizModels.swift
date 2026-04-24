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
        // Page 1 — Phase vs Keyframe
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

        // Page 2 — CoreGraphics vs PencilKit
        QuizQuestion(
            question: "Apple Pencil의 필압과 기울기를 자동으로 반영하는 필기 앱을 빠르게 만들고 싶다면?",
            answer: "PencilKit",
            explanation: .comparisonTable(ComparisonTable(
                headerA: "CoreGraphics",
                headerB: "PencilKit",
                rows: [
                    ComparisonRow(label: "필압·기울기", optionA: "직접 이벤트 처리", optionB: "자동 내장"),
                    ComparisonRow(label: "도구 UI", optionA: "직접 구현", optionB: "PKToolPicker 제공"),
                    ComparisonRow(label: "저장·복원", optionA: "수동 직렬화", optionB: "PKDrawing 자동"),
                    ComparisonRow(label: "커스터마이징", optionA: "완전 자유", optionB: "제한적"),
                    ComparisonRow(label: "적합한 곳", optionA: "차트, 커스텀 드로잉", optionB: "노트, 스케치, 서명"),
                ]
            ))
        ),

        // Page 3 — SpriteKit vs UIKit Dynamics
        QuizQuestion(
            question: "화면의 UIView 카드들에 중력과 스냅 효과만 넣고 싶은데, 게임 엔진까지 도입하기는 부담스럽다면?",
            answer: "UIKit Dynamics",
            explanation: .comparisonTable(ComparisonTable(
                headerA: "SpriteKit",
                headerB: "UIKit Dynamics",
                rows: [
                    ComparisonRow(label: "대상", optionA: "SKNode (게임 객체)", optionB: "UIView (기존 UI)"),
                    ComparisonRow(label: "좌표계", optionA: "좌하단 원점", optionB: "좌상단 원점"),
                    ComparisonRow(label: "물리 범위", optionA: "풍부 (조인트·필드)", optionB: "기본 (중력·충돌·스냅)"),
                    ComparisonRow(label: "SwiftUI 통합", optionA: "SpriteView", optionB: "UIViewRepresentable"),
                    ComparisonRow(label: "적합한 곳", optionA: "2D 게임, 시뮬레이션", optionB: "카드 UI, 탄성 메뉴"),
                ]
            ))
        ),

        // Page 4 — SceneKit vs Metal
        QuizQuestion(
            question: "3D 제품 뷰어를 며칠 안에 프로토타이핑해야 하는데, GPU 파이프라인까지 직접 다룰 여유가 없다면?",
            answer: "SceneKit",
            explanation: .comparisonTable(ComparisonTable(
                headerA: "SceneKit",
                headerB: "Metal",
                rows: [
                    ComparisonRow(label: "진입 장벽", optionA: "낮음 (수십 줄)", optionB: "매우 높음 (수백 줄)"),
                    ComparisonRow(label: "커스터마이징", optionA: "셰이더 모디파이어", optionB: "무한대"),
                    ComparisonRow(label: "모델 로딩", optionA: "USDZ·DAE 내장", optionB: "직접 파싱"),
                    ComparisonRow(label: "디버깅", optionA: "Scene Editor", optionB: "GPU Frame Debugger"),
                    ComparisonRow(label: "적합한 곳", optionA: "제품 뷰어, AR", optionB: "게임 엔진, 과학 시각화"),
                ]
            ))
        ),

        // Page 5 — Core Image vs Custom Metal Shader
        QuizQuestion(
            question: "사진에 세피아와 비네팅을 적용한 필터 UI를 빠르게 만들고 싶다면?",
            answer: "Core Image",
            explanation: .comparisonTable(ComparisonTable(
                headerA: "Core Image",
                headerB: "Custom Metal Shader",
                rows: [
                    ComparisonRow(label: "빌트인 필터", optionA: "200+ 즉시 사용", optionB: "직접 작성"),
                    ComparisonRow(label: "체이닝", optionA: "output → input 간편", optionB: "수동 구현"),
                    ComparisonRow(label: "GPU 가속", optionA: "자동", optionB: "직접 제어"),
                    ComparisonRow(label: "학습 비용", optionA: "낮음", optionB: "높음 (MSL + 파이프라인)"),
                    ComparisonRow(label: "적합한 곳", optionA: "사진 편집, 카메라 필터", optionB: "고성능 커스텀 이펙트"),
                ]
            ))
        ),
    ]
}
