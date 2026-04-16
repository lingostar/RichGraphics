---
layout: default
title: UIKit Dynamics
---

[Home]({{ '/' | relative_url }}) > UIKit Dynamics

# UIKit Dynamics

UIKit의 물리 엔진으로 UI 요소에 중력, 충돌, 탄성, 스냅 등 물리 기반 동작을 부여합니다. 자연스러운 인터랙션과 유기적인 UI 모션을 만들어 봅니다.

## 개요

**UIKit Dynamics**는 UIKit 뷰에 실시간 물리 시뮬레이션을 적용하는 프레임워크입니다. `UIDynamicAnimator`가 물리 엔진 역할을 하며, 다양한 `UIDynamicBehavior`(중력, 충돌, 부착, 스냅, 푸시)를 조합하여 UI 요소의 동작을 정의합니다.

SpriteKit과 달리 **일반 UIView를 물리 객체로 사용**하기 때문에, 기존 UI 컴포넌트에 물리 기반 인터랙션을 자연스럽게 추가할 수 있습니다. SwiftUI에서는 `UIViewRepresentable`을 통해 통합합니다.

### 언제 사용하나요?

- UI 카드/패널의 물리 기반 드래그 & 드롭
- 중력에 반응하는 인터랙티브 메뉴
- 탄성 있는 스냅 효과 (아이콘 정렬, 슬라이더 등)
- 충돌 기반 인터랙션 (범퍼, 핀볼 스타일 UI)
- 교육용 물리 시뮬레이션

## 핵심 API

### UIDynamicAnimator와 Behavior

```swift
class PhysicsViewController: UIViewController {
    var animator: UIDynamicAnimator!

    override func viewDidLoad() {
        super.viewDidLoad()
        animator = UIDynamicAnimator(referenceView: view)

        let card = UIView(frame: CGRect(x: 150, y: 50, width: 80, height: 80))
        card.backgroundColor = .systemBlue
        card.layer.cornerRadius = 12
        view.addSubview(card)

        // 중력
        let gravity = UIGravityBehavior(items: [card])
        // 충돌 (화면 경계)
        let collision = UICollisionBehavior(items: [card])
        collision.translatesReferenceBoundsIntoBoundary = true
        // 탄성
        let itemBehavior = UIDynamicItemBehavior(items: [card])
        itemBehavior.elasticity = 0.6

        animator.addBehavior(gravity)
        animator.addBehavior(collision)
        animator.addBehavior(itemBehavior)
    }
}
```

### 주요 Behavior 정리

| Behavior | 설명 |
|----------|------|
| `UIGravityBehavior` | 아이템에 중력(방향, 세기) 적용 |
| `UICollisionBehavior` | 아이템 간 또는 경계와의 충돌 감지 |
| `UIAttachmentBehavior` | 두 아이템 또는 앵커 포인트에 스프링/고정 연결 |
| `UISnapBehavior` | 아이템을 특정 지점으로 스냅 (감쇠 진동) |
| `UIPushBehavior` | 순간적(.instantaneous) 또는 지속적(.continuous) 힘 적용 |
| `UIDynamicItemBehavior` | 마찰, 탄성, 밀도, 저항 등 물리 속성 설정 |

### SwiftUI 통합

UIKit Dynamics는 UIKit 기반이므로 SwiftUI에서 `UIViewRepresentable` 또는 `UIViewControllerRepresentable`로 래핑하여 사용합니다.

```swift
struct DynamicsView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PhysicsViewController {
        PhysicsViewController()
    }
    func updateUIViewController(_ vc: PhysicsViewController, context: Context) {}
}
```

## 데모 목록

| # | 데모 | 설명 |
|---|------|------|
| 1 | **Gravity Cards** | 여러 카드 뷰에 중력과 충돌을 적용합니다. 디바이스를 기울이면 중력 방향이 바뀌어 카드가 쏟아지는 효과를 체험합니다. |
| 2 | **Newton's Cradle** | UIAttachmentBehavior(pendulum)와 UICollisionBehavior로 뉴턴의 요람을 구현합니다. 운동량 보존 법칙을 시각적으로 확인합니다. |
| 3 | **Snap Grid** | UISnapBehavior로 드래그한 아이콘이 가장 가까운 그리드 위치로 스냅되는 인터랙션을 구현합니다. damping 값에 따른 스냅 느낌 변화를 실험합니다. |
| 4 | **Elastic Menu** | UIAttachmentBehavior의 spring 설정으로 탄성 있는 메뉴 열기/닫기 애니메이션을 구현합니다. 드래그 속도에 반응하는 자연스러운 모션을 만듭니다. |
| 5 | **Collision Playground** | 커스텀 충돌 경계(UIBezierPath)를 그리고 뷰를 던져 충돌하는 인터랙티브 놀이터. UIPushBehavior의 instantaneous/continuous 차이를 비교합니다. |

## 실전 팁

### Best Practices

- UIKit Dynamics는 기존 UIView를 그대로 물리 객체로 활용하므로, 복잡한 UI에 물리 인터랙션을 추가하기 쉽습니다.
- 간단한 UI 물리(카드 스와이프, 스냅 정렬)에는 SpriteKit보다 UIKit Dynamics가 적합합니다.
- UISnapBehavior의 `damping` 값(0~1)으로 스냅의 "탄성 느낌"을 정밀하게 조절하세요.
- 여러 Behavior를 `UIDynamicBehavior` 서브클래스 하나에 묶으면 코드 관리가 편리합니다.

### 주의 사항

- UIKit Dynamics는 UIKit 전용이므로 SwiftUI에서 쓰려면 반드시 UIViewRepresentable 래퍼가 필요합니다.
- 물리 시뮬레이션이 안정화되면 자동으로 일시정지되지만, 불필요한 Behavior는 명시적으로 제거하세요.
- 수십 개 이상의 아이템에 복잡한 Behavior를 적용하면 CPU 부하가 증가합니다. SpriteKit 전환을 고려하세요.
- Auto Layout과 UIKit Dynamics는 충돌할 수 있습니다. 물리 대상 뷰는 frame 기반 레이아웃을 사용하세요.
- `UIDynamicAnimator`의 `referenceView`가 해제되면 시뮬레이션이 멈추므로 강한 참조를 유지하세요.
