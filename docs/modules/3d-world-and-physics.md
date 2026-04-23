---
layout: default
title: 3D World & Physics
---

[Home]({{ '/' | relative_url }}) > 3D World & Physics

# 3D World & Physics

<p class="subtitle">SpriteKit, SceneKit, CAEmitterLayer을 하나의 모듈에 모아 2D/3D 장면과 파티클 시스템을 비교하며 배웁니다.</p>

---

## 섹션 구성

세 가지 프레임워크를 각각의 섹션으로 구분해 같은 모듈 안에서 비교할 수 있도록 구성했습니다.

<div class="demo-list">
  <div class="demo-item">
    <h4>SpriteKit Physics — Gravity Balls</h4>
    <p>탭으로 공을 떨어뜨리고, 디바이스 기울기로 중력 방향을 제어합니다. SpriteKit의 물리엔진 + CoreMotion 통합을 보여줍니다.</p>
  </div>
  <div class="demo-item">
    <h4>3D World — Solar System</h4>
    <p>태양과 5개 행성의 공전, 달의 종속 궤도, 속도 슬라이더를 통한 시뮬레이션. SceneKit의 `SCNAction.rotateBy`와 자식 노드 계층을 활용합니다.</p>
  </div>
  <div class="demo-item">
    <h4>Particle Effects — Weather</h4>
    <p>눈/비/벚꽃 파티클을 segmented picker로 전환. `CAEmitterLayer`의 `birthRate`, `velocity`, `spin` 속성 조절 예시입니다.</p>
  </div>
  <div class="demo-item">
    <h4>Particle Effects — Confetti</h4>
    <p>버튼 트리거 축하 이펙트, continuous 모드 토글. 3D 텀블링 회전을 위한 `spin` + `spinRange` 활용.</p>
  </div>
</div>

---

## 왜 세 프레임워크를 묶었는가

**공통점**: 세 프레임워크 모두 **렌더링 루프를 가진 자식 뷰**를 SwiftUI에 내장하는 패턴입니다.

| Framework | SwiftUI 통합 | 렌더 대상 |
|-----------|-------------|----------|
| SpriteKit | `SpriteView(scene:)` | 2D 물리 노드 |
| SceneKit | `SceneView(scene:)` | 3D 기하체 |
| CAEmitterLayer | `UIViewRepresentable` | 2D 파티클 |

**차이점**: 각자 다른 계층의 추상화를 제공합니다 — 물리 시뮬레이션(SpriteKit), 3D 씬 그래프(SceneKit), 단순 파티클 렌더(CAEmitterLayer).

---

## SpriteKit 핵심 API

```swift
import SpriteKit

class GravityScene: SKScene {
    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with: UIEvent?) {
        guard let t = touches.first else { return }
        let ball = SKShapeNode(circleOfRadius: 20)
        ball.position = t.location(in: self)
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        ball.physicsBody?.restitution = 0.6   // 탄성
        addChild(ball)
    }
}
```

주요 개념: `SKPhysicsBody` (충돌/질량), `physicsWorld.gravity` (중력 벡터), `SKAction` (선언적 애니메이션 시퀀스).

---

## SceneKit 핵심 API

```swift
import SceneKit

let scene = SCNScene()
let sphere = SCNSphere(radius: 1.0)
sphere.firstMaterial?.diffuse.contents = UIColor.orange

let node = SCNNode(geometry: sphere)
node.position = SCNVector3(0, 0, -3)
scene.rootNode.addChildNode(node)

// Continuous rotation
let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 4)
node.runAction(SCNAction.repeatForever(spin))
```

주요 개념: `SCNScene` (씬 그래프 루트), `SCNNode` (계층적 트랜스폼), `SCNMaterial` (셰이딩 속성), `SCNAction` (애니메이션).

---

## CAEmitterLayer 핵심 API

```swift
let emitter = CAEmitterLayer()
emitter.emitterShape = .line
emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: 0)
emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)

let cell = CAEmitterCell()
cell.contents = UIImage(systemName: "snowflake")?.cgImage
cell.birthRate = 10          // per second
cell.lifetime = 6
cell.velocity = 80
cell.velocityRange = 40
cell.yAcceleration = 20
cell.spinRange = .pi

emitter.emitterCells = [cell]
view.layer.addSublayer(emitter)
```

주요 속성:
- `birthRate × lifetime` = 화면에 존재하는 평균 파티클 수
- `velocity` + `velocityRange` = 속도 분포
- `emitterShape` = 생성 형태 (`.point`, `.line`, `.rectangle`, `.circle`)

---

## 학생 팁

1. **SwiftUI `@State` vs Scene 내부 상태**: SpriteKit/SceneKit 씬은 SwiftUI의 relay가 아닙니다. 씬을 `@State` 프로퍼티로 한 번만 생성해 재사용하세요.
2. **성능**: `CAEmitterLayer`는 GPU 가속으로 수천 개 파티클도 무난하지만, SpriteKit에서 수백 개 이상의 물리 body는 CPU 병목이 될 수 있습니다.
3. **시뮬레이터 한계**: SceneKit의 Metal 셰이더 모디파이어는 시뮬레이터에서 제대로 동작하지 않을 수 있습니다. 실기기 테스트가 필요합니다.
4. **좌표계**: SpriteKit은 **좌하단 원점**(UIKit과 반대), SceneKit은 **우손 좌표계** (Y 위, Z 화면 앞), CAEmitterLayer는 UIKit과 동일한 좌상단 원점입니다.
