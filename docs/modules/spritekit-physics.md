---
layout: default
title: SpriteKit Physics
---

<div class="breadcrumb">
  <a href="{{ '/' | relative_url }}">Home</a> &gt; SpriteKit Physics
</div>

<div class="page-header">
  <h1>SpriteKit Physics</h1>
  <p class="subtitle">SpriteKit의 2D 물리 엔진을 활용하여 중력, 충돌, 관절, 자기장 시뮬레이션을 구현합니다. CoreMotion과 연동한 디바이스 기울기 기반 물리도 다룹니다.</p>
</div>

<article>

## 개요

**SpriteKit**은 Apple의 2D 게임/시뮬레이션 프레임워크입니다. 내장 물리 엔진(Box2D 기반)을 통해 중력, 충돌 감지, 관절(Joint), 필드(Field) 등을 코드 몇 줄로 시뮬레이션할 수 있습니다.

게임 개발뿐 아니라, 물리 기반 인터랙션이 필요한 교육용 앱이나 인터랙티브 시각화에도 매우 유용합니다. SwiftUI에서는 `SpriteView`를 통해 간편하게 SpriteKit 씬을 임베드할 수 있습니다.

### 언제 사용하나요?

- 2D 게임 개발 (물리, 충돌, 파티클)
- 물리 시뮬레이션 시각화 (교육/과학)
- 디바이스 모션과 연동한 인터랙티브 콘텐츠
- 대량의 스프라이트를 효율적으로 렌더링해야 할 때

## 핵심 API

### SKScene + SpriteView

SpriteKit의 진입점은 `SKScene`입니다. SwiftUI에서는 `SpriteView`로 씬을 표시합니다.

```swift
class PhysicsScene: SKScene {
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        // 공 생성
        let ball = SKShapeNode(circleOfRadius: 20)
        ball.fillColor = .systemBlue
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        ball.physicsBody?.restitution = 0.7
        ball.position = CGPoint(x: size.width / 2, y: size.height - 50)
        addChild(ball)
        // 바닥 경계
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    }
}
// SwiftUI에서 사용
SpriteView(scene: PhysicsScene(size: CGSize(width: 400, height: 600)))
```

### 물리 바디 & 충돌

- **SKPhysicsBody**: 노드에 물리 속성(질량, 반발계수, 마찰)을 부여
- **categoryBitMask / contactTestBitMask**: 충돌 그룹과 접촉 감지 설정
- **SKPhysicsContactDelegate**: 충돌 이벤트 콜백

### SKPhysicsJoint

`SKPhysicsJointPin`, `SKPhysicsJointSpring`, `SKPhysicsJointFixed` 등으로 노드 간 관절을 연결합니다. 진자, 체인, 브리지 시뮬레이션에 활용됩니다.

### SKFieldNode

자기장, 전기장, 소용돌이, 노이즈 등 다양한 물리 필드를 공간에 배치하여 주변 물리 바디에 힘을 가합니다.

### CoreMotion 연동

`CMMotionManager`의 가속도계 데이터를 `physicsWorld.gravity`에 매핑하면 디바이스를 기울여 물리 세계의 중력 방향을 제어할 수 있습니다.

## 데모 목록

<div class="demo-list">
  <div class="demo-item">
    <h4>1. Gravity Balls</h4>
    <p>다양한 물리 속성(질량, 반발계수, 마찰)을 가진 공들이 중력 아래 튕기고 충돌하는 시뮬레이션. 파라미터를 실시간으로 조절합니다.</p>
  </div>
  <div class="demo-item">
    <h4>2. Collision Lab</h4>
    <p>categoryBitMask와 contactTestBitMask를 설정하며 선택적 충돌 감지를 실습합니다. 충돌 시 시각/사운드 피드백을 구현합니다.</p>
  </div>
  <div class="demo-item">
    <h4>3. Joint Playground</h4>
    <p>Pin, Spring, Fixed Joint로 진자, 체인, 브리지 구조물을 만듭니다. 관절 파라미터 조절에 따른 동작 변화를 관찰합니다.</p>
  </div>
  <div class="demo-item">
    <h4>4. Field Forces</h4>
    <p>SKFieldNode(radialGravity, vortex, noise, spring)를 배치하여 파티클에 미치는 힘을 시각화합니다. 필드 세기와 범위를 조절합니다.</p>
  </div>
  <div class="demo-item">
    <h4>5. Tilt Maze</h4>
    <p>CoreMotion 가속도계와 SpriteKit 중력을 연동하여 디바이스 기울기로 공을 굴려 미로를 통과하는 게임입니다.</p>
  </div>
  <div class="demo-item">
    <h4>6. Ragdoll Physics</h4>
    <p>여러 SKPhysicsJoint를 조합하여 래그돌 캐릭터를 구성하고, 터치로 던지거나 당기는 인터랙션을 구현합니다.</p>
  </div>
</div>

## 실전 팁

<div class="pros-cons">
  <div class="pros">
    <h4>Best Practices</h4>
    <ul>
      <li>SpriteView의 `isPaused`, `preferredFramesPerSecond` 옵션으로 배터리를 절약하세요.</li>
      <li>물리 시뮬레이션 스케일은 실제 단위(미터)가 아닌 포인트 기준입니다. 적절한 스케일링이 중요합니다.</li>
      <li>`SKScene.update(_:)`에서 deltaTime을 활용하여 프레임 독립적 로직을 작성하세요.</li>
      <li>SpriteView에 `.ignoresSafeArea()`를 붙이면 전체 화면 씬을 쉽게 만들 수 있습니다.</li>
    </ul>
  </div>
  <div class="cons">
    <h4>주의 사항</h4>
    <ul>
      <li>물리 바디가 너무 많으면(수백 개 이상) 시뮬레이션 부하가 급격히 증가합니다.</li>
      <li>물리 바디의 크기가 너무 작으면 터널링(관통) 현상이 발생할 수 있습니다. `usesPreciseCollisionDetection`을 활성화하세요.</li>
      <li>SpriteView는 SwiftUI 뷰 업데이트와 SpriteKit 렌더 루프가 별도로 돌아가므로, 상태 동기화에 주의하세요.</li>
      <li>CoreMotion은 Simulator에서 동작하지 않으므로 실기기 테스트가 필수입니다.</li>
    </ul>
  </div>
</div>

</article>
