---
layout: default
title: 3D World & Physics
---

<div class="page-header">
  <div class="breadcrumb"><a href="{{ '/' | relative_url }}">Home</a> / 3D World &amp; Physics</div>
  <h1>3D World &amp; Physics</h1>
  <p class="subtitle">Swift 언어로 구현하는 3D 그래픽스. 앱 안에서 공간을 열어보세요.</p>
  <div class="tech-tags" style="margin-top: 12px;">
    <span class="tech-tag">SpriteKit</span>
    <span class="tech-tag">SceneKit</span>
    <span class="tech-tag">CoreAnimation</span>
  </div>
</div>

## 개요

이 모듈은 SwiftUI 위에 **렌더링 루프를 가진 자식 뷰**를 얹는 세 가지 패턴을 한 곳에서 비교합니다.

| Framework | 통합 방법 | 다루는 대상 |
|-----------|---------|-----------|
| SpriteKit | `SpriteView(scene:)` | 2D 노드 + 물리 |
| SceneKit | `SceneView(scene:)` | 3D 씬 그래프 |
| CoreAnimation (`CAEmitterLayer`) | `UIViewRepresentable` | 2D 파티클 |

세 프레임워크의 공통점은 **씬을 한 번 생성해 재사용**하고, SwiftUI는 그 씬을 화면에 담는 컨테이너 역할만 한다는 것입니다. SwiftUI의 `@State`로 씬을 보유하면 뷰가 다시 그려져도 같은 씬을 유지할 수 있습니다.

```swift
@State private var scene: GravityScene = {
    let scene = GravityScene()
    scene.scaleMode = .resizeFill
    return scene
}()

var body: some View {
    SpriteView(scene: scene)
}
```

이 모듈의 4개 데모는 위 세 프레임워크의 **대표적 활용**을 하나씩 보여줍니다.

---

## 1. Gravity Balls (SpriteKit)

> **무엇을 배우나** — `SKPhysicsBody`와 `physicsWorld.gravity`를 이용한 **2D 물리 시뮬레이션**, 그리고 `CoreMotion`으로 **디바이스 기울기에 따라 중력 방향을 회전**시키는 통합.

```swift
final class GravityScene: SKScene {
    override func didMove(to view: SKView) {
        // 화면 경계를 충돌 벽으로
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let ball = SKShapeNode(circleOfRadius: 20)
        ball.position = t.location(in: self)
        let body = SKPhysicsBody(circleOfRadius: 20)
        body.restitution = 0.7        // 탄성
        ball.physicsBody = body
        addChild(ball)
    }
}
```

CoreMotion 통합 — **디바이스 좌표 → 화면 좌표** 매핑이 핵심입니다. SpriteKit은 lower-left origin이라 인터페이스 회전에 따라 변환이 달라집니다.

```swift
motionManager.startAccelerometerUpdates(to: .main) { data, _ in
    guard let d = data else { return }
    let v = OrientationAwareGravity.spriteKitVector(
        deviceX: d.acceleration.x,
        deviceY: d.acceleration.y
    )
    self.physicsWorld.gravity = CGVector(dx: v.dx * 9.8, dy: v.dy * 9.8)
}
```

---

## 2. Solar System (SceneKit)

> **무엇을 배우나** — `SCNScene`/`SCNNode`의 **계층적 트랜스폼**으로 부모-자식 관계를 만들고, `SCNAction`으로 **공전·자전**을 표현하는 패턴.

```swift
let scene = SCNScene()

// 태양
let sun = SCNNode(geometry: SCNSphere(radius: 1.0))
sun.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
scene.rootNode.addChildNode(sun)

// 지구의 "공전 축" — 태양에 부착된 빈 노드
let earthOrbit = SCNNode()
sun.addChildNode(earthOrbit)

// 지구 본체 — 공전 축의 자식
let earth = SCNNode(geometry: SCNSphere(radius: 0.3))
earth.position = SCNVector3(3, 0, 0)         // 공전 축에서 거리 3
earthOrbit.addChildNode(earth)

// 공전 축이 회전 → 지구가 태양 주변을 돈다
let orbit = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 6)
earthOrbit.runAction(.repeatForever(orbit))

// 자전
let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 1)
earth.runAction(.repeatForever(spin))
```

핵심 개념: **빈 노드(`SCNNode()`)를 회전 축으로 사용**해, 자식 노드의 위치를 옮기면 그 거리에서 공전이 됩니다. 달도 같은 방식으로 지구의 자식 노드 → 지구 자체가 움직여도 달은 따라옵니다.

---

## 3. Weather (CAEmitterLayer)

> **무엇을 배우나** — `CAEmitterLayer` + `CAEmitterCell`로 **GPU 가속 파티클**을 설정 기반으로 만드는 패턴.

```swift
let emitter = CAEmitterLayer()
emitter.emitterShape    = .line
emitter.emitterPosition = CGPoint(x: bounds.midX, y: 0)
emitter.emitterSize     = CGSize(width: bounds.width, height: 1)

let snow = CAEmitterCell()
snow.contents       = UIImage(named: "snowflake")?.cgImage
snow.birthRate      = 30          // 초당 30개
snow.lifetime       = 8           // 8초 살아 있음
snow.scale          = 0.05
snow.scaleRange     = 0.03
snow.velocity       = 80
snow.velocityRange  = 30
snow.yAcceleration  = 20          // 떨어지는 가속도
snow.spinRange      = .pi
snow.emissionRange  = .pi / 8     // 살짝 흔들림

emitter.emitterCells = [snow]
view.layer.addSublayer(emitter)
```

기억해야 할 공식:

> **화면에 평균적으로 존재하는 파티클 수 ≈ `birthRate × lifetime`**

데모는 segmented picker로 **눈 / 비 / 벚꽃** 세 모드를 전환합니다. 같은 API에 cell의 contents·velocity·yAcceleration만 바꾸면 다른 효과가 나옵니다.

---

## 4. Confetti (CAEmitterLayer)

> **무엇을 배우나** — **버튼 트리거**로 일회성 폭발을 만들고, 3D 텀블링 효과를 위해 **회전 속성**을 설정하는 패턴.

```swift
func fire() {
    cell.birthRate = 200       // 잠깐 폭발
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        cell.birthRate = 0     // 더 이상 생성 안 함 (이미 떠있는 입자는 lifetime까지 유지)
    }
}

cell.spin       = 0
cell.spinRange  = .pi * 4    // 다양한 각속도로 회전 → 3D 텀블링 느낌
cell.color      = UIColor.systemPink.cgColor
cell.redRange   = 0.6        // 색상 변이
cell.greenRange = 0.6
cell.blueRange  = 0.6
```

continuous 모드 토글은 `birthRate`를 일정 값으로 유지/0으로 토글하는 차이입니다.

---

## 학생 팁

1. **씬은 `@State` 1번 생성** — `body` 안에서 매번 `SKScene()` 만들면 매 프레임 새로 만들어집니다. 반드시 `@State` 프로퍼티에 한 번만 보관.
2. **좌표계 함정**:
   - SpriteKit: **좌하단** 원점
   - SceneKit: **우손 좌표계** (Y 위, Z 화면 앞)
   - CAEmitterLayer: UIKit과 동일한 **좌상단** 원점
3. **성능 한계**:
   - `CAEmitterLayer` — GPU에서 수천 개 OK
   - SpriteKit — 수백 개 물리 body부터 CPU 병목 시작
   - SceneKit — 단순 씬은 가볍지만 그림자·반사 켜면 빠르게 무거워짐
4. **시뮬레이터 한계** — SceneKit의 Metal 셰이더 모디파이어는 시뮬레이터에서 잘 안 보일 수 있습니다. 실기기 검증 필수.
