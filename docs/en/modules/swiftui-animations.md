---
layout: default
title: SwiftUI
lang: en
---

<div class="page-header">
  <div class="breadcrumb"><a href="{{ '/en/' | relative_url }}">Home</a> / SwiftUI</div>
  <h1>SwiftUI</h1>
  <p class="subtitle">Powerful animations from the framework you already know. Start your graphics journey here.</p>
  <div class="tech-tags" style="margin-top: 12px;">
    <span class="tech-tag">SwiftUI Animation</span>
  </div>
</div>

## Overview

SwiftUI provides a **declarative animation system**. Where UIKit required imperative descriptions of "how to move" (begin/commit, durations, curves), SwiftUI lets you **just declare the final state**. The framework detects state changes and automatically interpolates intermediate frames for a smooth transition.

Two core patterns:

- **Implicit Animation** — bind an animation to a value change with the `.animation(_:value:)` modifier
- **Explicit Animation** — change state inside a `withAnimation { ... }` block; every affected view animates together

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

The four demos in this module each cover a **different facet** of SwiftUI animation.

---

## 1. Spring Playground

> **What you learn** — animation **timing curves**: between the same two states, how it moves changes the entire feel.

`.spring` is SwiftUI's most natural default curve. Inspired by physical spring-damper systems, three parameters drive its behavior.

| Parameter | Meaning | Intuition |
|----------|---------|-----------|
| `response` | Approximate time (seconds) to reach the target | Smaller = faster, larger = slower |
| `dampingFraction` | Damping ratio of oscillation (0–1) | Closer to 0 = more bounce; 1 = no bounce |
| `blendDuration` | Time to blend an in-progress animation into a new one | 0 is usually fine |

```swift
withAnimation(.spring(response: 0.5, dampingFraction: 0.3)) {
    animated.toggle()
}
```

The demo lets you compare **Bouncy / Smooth / Snappy** presets and tweak parameters via a **Custom slider** to feel the differences directly.

---

## 2. Morphing Shapes

> **What you learn** — define `animatableData` on a custom `Shape` to morph the shape itself.

SwiftUI's `Shape` protocol only requires implementing `path(in:)`. Add **`animatableData: Double`** as one extra line and SwiftUI interpolates between 0 and 1, calling `path(in:)` again every frame.

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
        // Lerp shapeA[i] and shapeB[i] by progress (0–1) to draw
    }
}
```

The demo morphs circle ↔ star, square ↔ triangle, heart ↔ diamond, and lets you scrub progress with a slider to **see how the interpolation unfolds** step by step.

> 💡 **Tip**: `animatableData` should be a single `Double` or a scalar type like `AnimatablePair` for stable behavior. Trying to interpolate an arbitrary `Array<CGPoint>` directly leads to subtle bugs.

---

## 3. Keyframe Animations

> **What you learn** — composite sequences where **multiple properties animate simultaneously**, each with its own **independent time curve**.

iOS 17's `KeyframeAnimator` introduced a "keyframe + track" structure. Each track has its own time/curve, and they all run simultaneously, expressing composite motion like **a bouncing-and-rotating ball** cleanly.

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

The demo offers four presets — **bounce / orbit / shake / wave** — to compare how different track combinations produce different motions.

---

## 4. Phase Animations

> **What you learn** — a state-machine pattern that **automatically cycles through multiple stages**. Ideal for animations that keep flowing without user input.

`PhaseAnimator` defines an array of phases and SwiftUI advances them automatically. Perfect for things that **"keep moving on their own"**, like loading indicators or pulsing badges.

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

The demo has three examples — **loading indicator, pulsing notification badge, status transition (connecting → connected → synced)** — showing how varied UX you can build with the same API.

> 💡 **Difference from Spring**: Spring handles "curves," Phase handles "state sequences." In other words, you can **use Spring as the curve for each Phase Animator transition** — the two concepts are orthogonal.

---

## Practical Tips

**Best Practices**
- Use Implicit (`.animation`) for single-property changes; use Explicit (`withAnimation`) for changing several states at once.
- Spring curves are the most natural default. When in doubt, just use `.spring` — it works in most cases.
- One-shot composite motion → `KeyframeAnimator`. Repeating/cycling motion → `PhaseAnimator`.

**Watch Out**
- **Don't omit the `value:` parameter** in `.animation()`. Otherwise unintended properties may also animate.
- Excessive animation in complex view trees causes frame drops. Profile with the **Animation Hitches** instrument.
- The Simulator can be more forgiving than real hardware — always validate performance on a **physical device**.
