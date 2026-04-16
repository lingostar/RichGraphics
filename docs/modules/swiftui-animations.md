---
layout: default
title: SwiftUI Animations
---

<div class="breadcrumb">
  <a href="{{ '/' | relative_url }}">Home</a> &gt; SwiftUI Animations
</div>

<div class="page-header">
  <h1>SwiftUI Animations</h1>
  <p class="subtitle">SwiftUI의 선언형 애니메이션 시스템을 탐험합니다. Spring, Keyframe, Phase 기반 애니메이션부터 geometry 전환까지, 모던 iOS 앱의 모션 디자인 핵심을 다룹니다.</p>
</div>

<article markdown="1">

## 개요

SwiftUI는 **선언형(Declarative) 애니메이션 시스템**을 제공합니다. 상태(State) 변경을 선언하면 프레임워크가 자동으로 중간 프레임을 보간하여 부드러운 전환을 만들어 줍니다. UIKit의 명령형 애니메이션과 달리, "어떻게 움직일지"가 아니라 "최종 상태가 무엇인지"만 기술하면 됩니다.

### 언제 사용하나요?

- UI 요소의 위치, 크기, 투명도, 색상 전환
- 화면 전환 및 네비게이션 애니메이션
- 인터랙티브 제스처 피드백
- 복잡한 다단계(multi-step) 모션 시퀀스

## 핵심 API

### Implicit vs Explicit Animation

**Implicit Animation**은 `.animation()` modifier로 특정 값 변경에 애니메이션을 바인딩합니다. **Explicit Animation**은 `withAnimation` 블록 안에서 상태를 변경하여 해당 변경에 영향받는 모든 뷰를 애니메이션합니다.

```swift
// Implicit: 특정 프로퍼티에 애니메이션 바인딩
Circle()
    .scaleEffect(isExpanded ? 1.5 : 1.0)
    .animation(.spring(duration: 0.5), value: isExpanded)

// Explicit: 상태 변경 시점에 애니메이션 적용
withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
    isExpanded.toggle()
}
```

### Spring Animation

iOS 17부터 `spring(duration:bounce:)` 파라미터로 물리 기반 스프링을 간편하게 설정할 수 있습니다. `bounce` 값이 0이면 임계감쇠(critically damped), 양수이면 바운스 효과가 나타납니다.

### KeyframeAnimator

iOS 17에서 도입된 `KeyframeAnimator`는 여러 프로퍼티를 독립적인 타임라인으로 제어하는 키프레임 애니메이션을 지원합니다.

```swift
KeyframeAnimator(initialValue: AnimValues()) { values in
    Circle()
        .scaleEffect(values.scale)
        .rotationEffect(values.rotation)
} keyframes: { _ in
    KeyframeTrack(\.scale) {
        SpringKeyframe(1.5, duration: 0.3)
        SpringKeyframe(1.0, duration: 0.2)
    }
    KeyframeTrack(\.rotation) {
        LinearKeyframe(.degrees(360), duration: 0.5)
    }
}
```

### PhaseAnimator

`PhaseAnimator`는 정의된 Phase 배열을 순차적으로 순회하며 자동 애니메이션을 실행합니다. 로딩 인디케이터나 반복 모션에 적합합니다.

### matchedGeometryEffect

서로 다른 뷰 계층에 있는 두 요소 사이의 위치/크기 전환을 자연스럽게 연결합니다. 리스트에서 디테일 화면으로의 Hero Transition 구현에 핵심적인 API입니다.

### .visualEffect

iOS 17의 `.visualEffect` modifier는 geometry proxy 정보(위치, 크기)에 기반한 시각 효과를 적용할 수 있게 해 줍니다. 스크롤 위치에 따른 패럴랙스, 회전, 스케일 효과 등을 구현할 때 유용합니다.

## 데모 목록

<div class="demo-list">
  <div class="demo-item">
    <h4>1. Spring Playground</h4>
    <p>Spring 파라미터(duration, bounce, blendDuration)를 실시간으로 조절하며 스프링 곡선의 변화를 시각적으로 확인합니다.</p>
  </div>
  <div class="demo-item">
    <h4>2. Keyframe Choreographer</h4>
    <p>KeyframeAnimator로 여러 프로퍼티(scale, rotation, offset)를 독립적 타임라인으로 조합하는 복합 애니메이션을 만듭니다.</p>
  </div>
  <div class="demo-item">
    <h4>3. Phase Loop</h4>
    <p>PhaseAnimator를 활용한 자동 반복 애니메이션 구현. 로딩 스피너와 펄스 이펙트를 직접 구성합니다.</p>
  </div>
  <div class="demo-item">
    <h4>4. Morphing Shapes</h4>
    <p>커스텀 Shape의 animatableData를 활용하여 도형 간 부드러운 모핑 전환을 구현합니다.</p>
  </div>
  <div class="demo-item">
    <h4>5. Hero Transition</h4>
    <p>matchedGeometryEffect로 그리드/리스트 뷰와 디테일 뷰 사이의 자연스러운 Hero 화면 전환을 만듭니다.</p>
  </div>
  <div class="demo-item">
    <h4>6. Scroll Parallax</h4>
    <p>.visualEffect와 ScrollView를 결합하여 스크롤 위치에 따른 패럴랙스, 회전, 페이드 효과를 구현합니다.</p>
  </div>
  <div class="demo-item">
    <h4>7. Gesture-Driven Animation</h4>
    <p>DragGesture와 withAnimation을 결합하여 드래그에 반응하는 인터랙티브 카드 애니메이션을 구현합니다.</p>
  </div>
</div>

## 실전 팁

<div class="pros-cons">
  <div class="pros">
    <h4>Best Practices</h4>
    <ul>
      <li>단일 프로퍼티 변경에는 Implicit(`.animation`)이 간결하고 안전합니다.</li>
      <li>여러 상태를 동시에 변경할 때는 `withAnimation`(Explicit)을 사용하세요.</li>
      <li>Spring Animation의 `bounce: 0`은 자연스러운 감속 효과를 줍니다.</li>
      <li>`Animation.interactiveSpring`은 제스처 추적에 최적화되어 있습니다.</li>
      <li>KeyframeAnimator는 단발성 복합 모션에, PhaseAnimator는 반복 모션에 적합합니다.</li>
    </ul>
  </div>
  <div class="cons">
    <h4>주의 사항</h4>
    <ul>
      <li>`.animation()`에 `value` 파라미터를 생략하면 의도하지 않은 프로퍼티까지 애니메이션될 수 있습니다.</li>
      <li>matchedGeometryEffect는 두 뷰가 동시에 존재하면 안 됩니다 (if/else 분기 필요).</li>
      <li>복잡한 뷰 트리에서 과도한 애니메이션은 프레임 드롭을 유발할 수 있습니다.</li>
      <li>Instruments의 Animation Hitches 도구로 성능을 프로파일링하세요.</li>
      <li>Simulator보다 실기기에서 성능을 반드시 확인하세요.</li>
    </ul>
  </div>
</div>

</article>
