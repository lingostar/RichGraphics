---
layout: default
title: 3D World & Physics
lang: en
---

<div class="page-header">
  <div class="breadcrumb"><a href="{{ '/en/' | relative_url }}">Home</a> / 3D World &amp; Physics</div>
  <h1>3D World &amp; Physics</h1>
  <p class="subtitle">3D graphics built in Swift. Open up a whole spatial world inside your app.</p>
  <div class="tech-tags" style="margin-top: 12px;">
    <span class="tech-tag">SpriteKit</span>
    <span class="tech-tag">SceneKit</span>
    <span class="tech-tag">CoreAnimation</span>
  </div>
</div>

## Overview

This module compares three patterns for layering **a child view with its own render loop** on top of SwiftUI.

| Framework | Integration | What it handles |
|-----------|-------------|----------------|
| SpriteKit | `SpriteView(scene:)` | 2D nodes + physics |
| SceneKit | `SceneView(scene:)` | 3D scene graph |
| CoreAnimation (`CAEmitterLayer`) | `UIViewRepresentable` | 2D particles |

All three frameworks share the same idea: **create the scene once and reuse it**, with SwiftUI just acting as the container. Hold the scene in SwiftUI's `@State` so it survives view re-renders.

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

The four demos in this module each show a **representative use** of one of these frameworks.

---

## 1. Gravity Balls (SpriteKit)

> **What you learn** — **2D physics simulation** using `SKPhysicsBody` and `physicsWorld.gravity`, plus integrating `CoreMotion` to **rotate gravity direction based on device tilt**.

```swift
final class GravityScene: SKScene {
    override func didMove(to view: SKView) {
        // Use the screen edges as collision walls
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let ball = SKShapeNode(circleOfRadius: 20)
        ball.position = t.location(in: self)
        let body = SKPhysicsBody(circleOfRadius: 20)
        body.restitution = 0.7        // bounciness
        ball.physicsBody = body
        addChild(ball)
    }
}
```

CoreMotion integration — the key is **mapping device coordinates to screen coordinates**. Since SpriteKit uses a lower-left origin, the conversion changes with interface rotation.

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

> **What you learn** — use the **hierarchical transforms** of `SCNScene`/`SCNNode` to express parent-child relationships, and use `SCNAction` for **orbits and rotations**.

```swift
let scene = SCNScene()

// Sun
let sun = SCNNode(geometry: SCNSphere(radius: 1.0))
sun.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
scene.rootNode.addChildNode(sun)

// Earth's "orbit pivot" — an empty node attached to the Sun
let earthOrbit = SCNNode()
sun.addChildNode(earthOrbit)

// Earth itself — child of the orbit pivot
let earth = SCNNode(geometry: SCNSphere(radius: 0.3))
earth.position = SCNVector3(3, 0, 0)         // distance 3 from the pivot
earthOrbit.addChildNode(earth)

// Pivot rotates → Earth orbits the Sun
let orbit = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 6)
earthOrbit.runAction(.repeatForever(orbit))

// Spin
let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 1)
earth.runAction(.repeatForever(spin))
```

Core idea: **use an empty node (`SCNNode()`) as the rotation pivot**, then offset child nodes from it to get orbit motion. The Moon works the same way as a child of Earth — when Earth moves, the Moon follows.

---

## 3. Weather (CAEmitterLayer)

> **What you learn** — build **GPU-accelerated particles** declaratively with `CAEmitterLayer` + `CAEmitterCell`.

```swift
let emitter = CAEmitterLayer()
emitter.emitterShape    = .line
emitter.emitterPosition = CGPoint(x: bounds.midX, y: 0)
emitter.emitterSize     = CGSize(width: bounds.width, height: 1)

let snow = CAEmitterCell()
snow.contents       = UIImage(named: "snowflake")?.cgImage
snow.birthRate      = 30          // 30 per second
snow.lifetime       = 8           // alive for 8 seconds
snow.scale          = 0.05
snow.scaleRange     = 0.03
snow.velocity       = 80
snow.velocityRange  = 30
snow.yAcceleration  = 20          // falling acceleration
snow.spinRange      = .pi
snow.emissionRange  = .pi / 8     // slight wobble

emitter.emitterCells = [snow]
view.layer.addSublayer(emitter)
```

A formula worth memorizing:

> **Average particles on screen ≈ `birthRate × lifetime`**

The demo uses a segmented picker to switch between **snow / rain / cherry blossoms**. Same API — just change cell `contents`, `velocity`, and `yAcceleration` to get a different effect.

---

## 4. Confetti (CAEmitterLayer)

> **What you learn** — produce a one-shot burst with a **button trigger**, and set **rotation properties** for a 3D-tumbling look.

```swift
func fire() {
    cell.birthRate = 200       // brief explosion
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        cell.birthRate = 0     // stop spawning (existing particles live out their lifetime)
    }
}

cell.spin       = 0
cell.spinRange  = .pi * 4    // rotate at varied angular velocities → 3D tumbling feel
cell.color      = UIColor.systemPink.cgColor
cell.redRange   = 0.6        // color variation
cell.greenRange = 0.6
cell.blueRange  = 0.6
```

The continuous-mode toggle is just the difference between holding `birthRate` at a steady value vs. toggling it to 0.

---

## Student Tips

1. **Create the scene once via `@State`** — making `SKScene()` inside `body` recreates it every frame. Always store it in a `@State` property and create only once.
2. **Coordinate-system gotchas**:
   - SpriteKit: origin at **bottom-left**
   - SceneKit: **right-handed coords** (Y up, Z toward the viewer)
   - CAEmitterLayer: same **top-left** origin as UIKit
3. **Performance ceiling**:
   - `CAEmitterLayer` — thousands fine on the GPU
   - SpriteKit — hundreds of physics bodies start to bottleneck the CPU
   - SceneKit — simple scenes are light, but shadows/reflections quickly get heavy
4. **Simulator limits** — SceneKit Metal shader modifiers may not render correctly in the Simulator. Verify on real hardware.
