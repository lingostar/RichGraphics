---
layout: default
title: UIKit
---

<div class="page-header">
  <div class="breadcrumb"><a href="{{ '/' | relative_url }}">Home</a> / UIKit</div>
  <h1>UIKit</h1>
  <p class="subtitle">UIKit이 열어주는 새로운 차원의 풍부한 그래픽스와 물리 엔진.</p>
  <div class="tech-tags" style="margin-top: 12px;">
    <span class="tech-tag">UIKit Dynamics</span>
  </div>
</div>

## 개요

**UIKit Dynamics**는 일반 UIView에 실시간 물리 시뮬레이션을 적용하는 프레임워크입니다. 게임 엔진을 도입하지 않고도 **카드, 버튼, 이미지** 같은 평범한 UI 요소에 중력·충돌·탄성을 부여할 수 있어, 인터랙티브 UI에 "물리적인 손맛"을 더할 때 가장 적합합니다.

핵심 구조:

- **`UIDynamicAnimator`** — 물리 엔진 본체. `referenceView`라는 좌표 공간 안에서 시뮬레이션을 돌립니다.
- **`UIDynamicBehavior`** — 가짜 물리 법칙. 중력/충돌/스냅/어태치먼트 등을 조합해 동작을 구성합니다.

```swift
animator = UIDynamicAnimator(referenceView: view)

let gravity   = UIGravityBehavior(items: [card])
let collision = UICollisionBehavior(items: [card])
collision.translatesReferenceBoundsIntoBoundary = true
let item      = UIDynamicItemBehavior(items: [card])
item.elasticity = 0.6

[gravity, collision, item].forEach { animator.addBehavior($0) }
```

이 모듈의 5개 데모는 각각 다른 Behavior 조합을 보여줍니다.

---

## 1. Gravity Cards

> **무엇을 배우나** — `UIGravityBehavior`로 중력을 적용하고 `CoreMotion`으로 **디바이스 기울기에 따라 중력 방향을 회전**시키는 패턴.

```swift
let gravity = UIGravityBehavior(items: cards)

motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
    guard let m = motion else { return }
    // 화면 좌표계로 변환된 중력 벡터
    let v = OrientationAwareGravity.uiKitVector(
        deviceX: m.gravity.x, deviceY: m.gravity.y
    )
    gravity.gravityDirection = CGVector(dx: v.dx * 2, dy: v.dy * 2)
}
```

핵심 포인트:
- `gravityDirection`은 **화면 좌표(top-left origin)** 기준 벡터. 디바이스 좌표가 아니므로 인터페이스 회전에 따라 매핑이 필요합니다.
- 카드끼리 충돌·튀어 오르도록 `UICollisionBehavior` + `UIDynamicItemBehavior(elasticity:)`도 함께 적용.
- 화면 회전을 막아야 중력이 일관되므로 이 데모는 **Landscape Lock**이 걸려 있습니다.

---

## 2. Snap Grid

> **무엇을 배우나** — `UISnapBehavior`로 드래그한 항목을 **가장 가까운 그리드 포인트에 자석처럼 끌어당기는** 패턴.

```swift
@objc func handlePan(_ gesture: UIPanGestureRecognizer) {
    guard let item = gesture.view else { return }
    switch gesture.state {
    case .began:
        // 드래그 중에는 snap 제거
        if let snap = snapBehaviors[item] { animator?.removeBehavior(snap) }
    case .changed:
        item.center = gesture.location(in: containerView)
        animator?.updateItem(usingCurrentState: item)
    case .ended:
        // 가장 가까운 그리드 포인트로 snap
        let nearest = nearestGridPoint(to: item.center)
        let snap = UISnapBehavior(item: item, snapTo: nearest)
        snap.damping = currentDamping
        animator?.addBehavior(snap)
        snapBehaviors[item] = snap
    default: break
    }
}
```

`damping` 슬라이더(0~1)로 **얼마나 튕기는 스냅인지** 조절할 수 있습니다. 0에 가까울수록 진동, 1이면 부드럽게 정착.

---

## 3. Collision Bubbles

> **무엇을 배우나** — `UICollisionBehavior`로 **여러 객체가 자연스럽게 자리 잡는 태그 클라우드**를 만드는 패턴.

```swift
let collision = UICollisionBehavior(items: bubbles)
collision.translatesReferenceBoundsIntoBoundary = true

let item = UIDynamicItemBehavior(items: bubbles)
item.elasticity = 0.6
item.allowsRotation = false   // 글자 똑바로 유지

// 탭 시 주변으로 밀어내기
let push = UIPushBehavior(items: [tappedBubble], mode: .instantaneous)
push.angle = .random(in: 0..<2 * .pi)
push.magnitude = 1.0
animator?.addBehavior(push)
```

`UIPushBehavior`의 `.instantaneous` 모드는 **한 번의 충격**(주먹질 한 번)을, `.continuous` 모드는 **지속적인 힘**(바람 같은)을 표현합니다.

---

## 4. Pendulum (Newton's Cradle)

> **무엇을 배우나** — `UIAttachmentBehavior`로 **줄/스프링 연결**을 만들고, 중력·충돌과 결합해 **운동량 전달**을 보여주는 패턴.

```swift
for ball in balls {
    let attachment = UIAttachmentBehavior(
        item: ball,
        attachedToAnchor: anchorAbove(ball)
    )
    attachment.length = stringLength
    attachment.damping = 0      // 진자 운동 무손실
    animator?.addBehavior(attachment)
}

// 모든 공이 서로 충돌
let collision = UICollisionBehavior(items: balls)
let item = UIDynamicItemBehavior(items: balls)
item.elasticity = 1.0           // 완전 탄성 충돌
animator?.addBehavior(collision)
animator?.addBehavior(item)
```

> 💡 **드래그 인터랙션은 `UISnapBehavior`로**: 손으로 공을 잡을 때는 `UISnapBehavior(item:snapTo:)`로 손가락 위치에 부착하고, 손을 떼면 snap을 제거해 자연스럽게 놓아줍니다. (rafcio2k의 NewtonsCradlePlayground 패턴)

---

## 5. Elastic Menu

> **무엇을 배우나** — `UIAttachmentBehavior`의 **스프링 모드**로 항목들을 이상적 위치에 매달고, 항목 사이를 약한 스프링으로 연결해 **체인처럼 따라오는** 메뉴를 만드는 패턴.

```swift
// 각 메뉴 아이템을 자기의 "고정 위치"에 스프링으로 매닮
for (i, item) in items.enumerated() {
    let anchor = idealPosition(for: i)
    let spring = UIAttachmentBehavior(item: item, attachedToAnchor: anchor)
    spring.length = 0
    spring.damping = 0.5
    spring.frequency = 3.0
    animator?.addBehavior(spring)
}

// 인접 아이템끼리도 약한 스프링으로 연결
for i in 0..<(items.count - 1) {
    let chain = UIAttachmentBehavior(item: items[i], attachedTo: items[i+1])
    chain.damping = 0.5
    chain.frequency = 2.0
    animator?.addBehavior(chain)
}
```

한 항목을 당기면 자기 anchor가 끌어당기는 힘 + 옆 항목과의 체인 힘이 동시에 작용해, **부드럽게 출렁이는 메뉴**가 만들어집니다.

---

## Behavior 빠른 참조

| Behavior | 용도 |
|----------|------|
| `UIGravityBehavior` | 일정한 가속도(중력) |
| `UICollisionBehavior` | 객체 간 또는 경계와의 충돌 |
| `UIAttachmentBehavior` | 두 점/객체를 고정·스프링 연결 (줄, 스프링) |
| `UISnapBehavior` | 한 점으로 자석처럼 흡인 (감쇠 진동) |
| `UIPushBehavior` | 순간 힘(.instantaneous) 또는 지속 힘(.continuous) |
| `UIDynamicItemBehavior` | 마찰·탄성·밀도·회전 허용 등 물리 속성 |

---

## 실전 팁

**Best Practices**
- UIKit Dynamics는 **기존 UIView를 그대로** 물리 객체로 쓰므로, SwiftUI 화면에 부분적으로 물리 인터랙션을 넣고 싶을 때 가장 가볍습니다.
- `UISnapBehavior.damping`(0~1)으로 스냅의 "탄성 느낌"을 조절. 0.4~0.6이 보편적으로 자연스러움.
- 시뮬레이션이 안정화되면 자동 일시정지되지만, 안 쓰는 Behavior는 명시적으로 `removeBehavior`.

**주의 사항**
- SwiftUI에서는 반드시 `UIViewRepresentable` 또는 `UIViewControllerRepresentable` 래퍼 필요.
- Auto Layout과 충돌하므로, 물리 대상 뷰는 **frame 기반**으로 배치하세요.
- `UIDynamicAnimator`의 `referenceView`가 해제되면 시뮬레이션이 멈춥니다. 강한 참조를 유지.
- 객체 100개 이상 + 복잡한 Behavior 조합은 CPU 병목. 그 시점이면 SpriteKit으로 전환을 고려.
