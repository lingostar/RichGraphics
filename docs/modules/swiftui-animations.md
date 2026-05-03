---
layout: default
title: SwiftUI
---

<div class="page-header">
  <div class="breadcrumb"><a href="{{ '/' | relative_url }}">Home</a> / SwiftUI</div>
  <h1>SwiftUI</h1>
  <p class="subtitle">가장 친근한 기술에서 얻을 수 있는 강력한 애니메이션. 시작은 SwiftUI 에서.</p>
  <div class="tech-tags" style="margin-top: 12px;">
    <span class="tech-tag">SwiftUI Animation</span>
  </div>
</div>

## 개요

SwiftUI는 **선언형(Declarative) 애니메이션 시스템**을 제공합니다. UIKit이 "어떻게 움직일지"(begin/commit, durations, curves)를 명령형으로 기술해야 했다면, SwiftUI는 **"최종 상태가 무엇인지"만 선언**하면 됩니다. 상태(State) 변경을 감지한 프레임워크가 자동으로 중간 프레임을 보간(interpolate)해 부드러운 전환을 만들어 줍니다.

핵심 두 패턴:

- **Implicit Animation** — `.animation(_:value:)` modifier로 특정 값 변경에 애니메이션을 바인딩
- **Explicit Animation** — `withAnimation { ... }` 블록 안에서 상태를 변경, 영향받는 모든 뷰가 함께 애니메이션

```swift
// Implicit
Circle()
    .scaleEffect(isExpanded ? 1.5 : 1.0)
    .animation(.spring, value: isExpanded)

// Explicit
withAnimation(.spring(response: 0.5, dampingFraction: 0.3)) {
    isExpanded.toggle()
}
```

이 모듈의 4개 데모는 각각 SwiftUI 애니메이션의 **다른 측면**을 다룹니다.

---

## 1. Spring Playground

> **무엇을 배우나** — 애니메이션의 **타이밍 곡선(curve)**: 같은 두 상태 사이라도 어떻게 움직이는가에 따라 느낌이 완전히 달라집니다.

`.spring`은 SwiftUI의 가장 자연스러운 기본 곡선입니다. 물리의 스프링-댐퍼 시스템에서 영감을 받아 세 가지 파라미터로 동작을 제어합니다.

| 파라미터 | 의미 | 직관 |
|----------|------|------|
| `response` | 목표에 도달하는 데 걸리는 대략의 시간(초) | 작을수록 빠르고, 클수록 느긋 |
| `dampingFraction` | 진동(튕김)의 감쇠 비율 (0~1) | 0에 가까울수록 많이 튕김, 1이면 안 튕김 |
| `blendDuration` | 진행 중이던 애니메이션이 새 애니메이션으로 섞이는 시간 | 보통 0이면 충분 |

```swift
withAnimation(.spring(response: 0.5, dampingFraction: 0.3)) {
    animated.toggle()
}
```

데모에서는 **Bouncy / Smooth / Snappy** 프리셋을 비교하고, **Custom 슬라이더**로 직접 파라미터를 조정해 곡선의 차이를 직관적으로 느낄 수 있습니다.

---

## 2. Morphing Shapes

> **무엇을 배우나** — 커스텀 `Shape`에 `animatableData`를 정의하여 도형 자체를 변형시키는 방법.

SwiftUI의 `Shape` 프로토콜은 `path(in:)` 메서드만 구현하면 어떤 도형이든 그릴 수 있습니다. 여기에 **`animatableData: Double`** 한 줄을 추가하면, SwiftUI가 0→1 사이를 보간하면서 매 프레임마다 `path(in:)`을 다시 호출합니다.

```swift
struct MorphShape: Shape {
    let shapeA: [CGPoint]
    let shapeB: [CGPoint]
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        // shapeA[i]와 shapeB[i]를 progress(0~1)로 lerp해서 그림
    }
}
```

데모에서는 circle ↔ star, square ↔ triangle, heart ↔ diamond를 모핑하며, 슬라이더로 progress를 직접 조작해 **보간이 어떻게 일어나는지** 단계별로 볼 수 있습니다.

> 💡 **포인트**: `animatableData`는 단일 `Double` 또는 `AnimatablePair` 같은 스칼라 타입이어야 안정적으로 동작합니다. 임의의 `Array<CGPoint>`를 직접 보간하려고 하면 미묘한 버그가 발생합니다.

---

## 3. Keyframe Animations

> **무엇을 배우나** — **여러 프로퍼티가 동시에**, 각각 **독립된 시간 곡선**으로 움직이는 복합 시퀀스.

iOS 17의 `KeyframeAnimator`는 "키프레임 + 트랙" 구조를 도입했습니다. 트랙마다 자신만의 시간/곡선을 가지고, 모두 동시에 진행되어 **공이 튕기면서 회전하는** 같은 합성 모션을 깔끔하게 표현할 수 있습니다.

```swift
struct AnimValues {
    var offset: CGFloat = 0
    var scale: CGFloat = 1
    var rotation: Angle = .zero
}

KeyframeAnimator(initialValue: AnimValues(), trigger: trigger) { values in
    Image(systemName: "soccerball")
        .offset(y: values.offset)
        .scaleEffect(values.scale)
        .rotationEffect(values.rotation)
} keyframes: { _ in
    KeyframeTrack(\.offset) {
        SpringKeyframe(-200, duration: 0.4)
        SpringKeyframe(0, duration: 0.6, spring: .bouncy)
    }
    KeyframeTrack(\.rotation) {
        LinearKeyframe(.degrees(720), duration: 1.0)
    }
}
```

데모는 **bounce / orbit / shake / wave** 4가지 프리셋을 제공해 트랙을 어떻게 조합하면 어떤 모션이 나오는지 비교합니다.

---

## 4. Phase Animations

> **무엇을 배우나** — **여러 단계를 자동으로 순환**하는 상태 머신 패턴. 사용자 입력 없이 계속 흐르는 애니메이션에 적합.

`PhaseAnimator`는 phase 배열을 정의하고, SwiftUI가 자동으로 다음 phase로 넘어가게 합니다. 로딩 인디케이터나 펄싱 뱃지처럼 **"가만히 있어도 계속 움직이는"** 표현에 안성맞춤.

```swift
enum LoadPhase: CaseIterable { case dot1, dot2, dot3 }

HStack {
    ForEach(0..<3) { i in
        Circle()
            .phaseAnimator(LoadPhase.allCases) { view, phase in
                let scale = (phase.rawValue == i) ? 1.3 : 0.7
                view.scaleEffect(scale)
            } animation: { _ in
                .easeInOut(duration: 0.4)
            }
    }
}
```

데모에는 **로딩 인디케이터, 펄싱 알림 뱃지, 상태 전환(connecting → connected → synced)** 세 가지 사용 예시가 있어, 같은 API로도 얼마나 다양한 UX를 만들 수 있는지 보여줍니다.

> 💡 **Spring과의 차이**: Spring은 "곡선"을, Phase는 "상태 시퀀스"를 다룹니다. 즉, Phase Animator의 **각 phase 전환의 곡선으로 Spring을 사용할 수도** 있습니다 — 두 개념은 직교합니다.

---

## 실전 팁

**Best Practices**
- 단일 프로퍼티 변경에는 Implicit(`.animation`), 여러 상태 동시 변경에는 Explicit(`withAnimation`).
- Spring 곡선이 가장 자연스러운 기본값. 의심스럽다면 `.spring`만 쓰면 대부분 괜찮습니다.
- 단발성 복합 모션 → `KeyframeAnimator`. 반복/순환 모션 → `PhaseAnimator`.

**주의 사항**
- `.animation()`에 `value:` 파라미터를 **생략하지 마세요**. 안 그러면 의도하지 않은 프로퍼티까지 애니메이션됩니다.
- 복잡한 뷰 트리에서 과도한 애니메이션은 프레임 드롭의 원인. Instruments의 **Animation Hitches** 도구로 프로파일링하세요.
- Simulator는 실기기보다 후하게 그려주는 경우가 있으니, 성능은 반드시 **실기기**에서 검증.
