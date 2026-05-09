---
layout: default
title: UIKit
lang: en
---

<div class="page-header">
  <div class="breadcrumb"><a href="{{ '/en/' | relative_url }}">Home</a> / UIKit</div>
  <h1>UIKit</h1>
  <p class="subtitle">A whole new dimension of rich graphics and physics, opened up by UIKit.</p>
  <div class="tech-tags" style="margin-top: 12px;">
    <span class="tech-tag">UIKit Dynamics</span>
  </div>
</div>

## Overview

**UIKit Dynamics** applies real-time physics simulation to plain UIViews. Without dragging in a game engine, you can give ordinary UI elements like **cards, buttons, and images** gravity, collision, and elasticity — making it the most natural fit when you want to add a "physical feel" to interactive UI.

Core structure:

- **`UIDynamicAnimator`** — the physics engine itself. It runs the simulation inside a coordinate space called `referenceView`.
- **`UIDynamicBehavior`** — pseudo-physical laws. Compose gravity / collision / snap / attachment etc. to design behavior.

```swift
animator = UIDynamicAnimator(referenceView: view)

let gravity   = UIGravityBehavior(items: [card])
let collision = UICollisionBehavior(items: [card])
collision.translatesReferenceBoundsIntoBoundary = true
let item      = UIDynamicItemBehavior(items: [card])
item.elasticity = 0.6

[gravity, collision, item].forEach { animator.addBehavior($0) }
```

The five demos in this module each show a different combination of Behaviors.

---

## 1. Gravity Cards

> **What you learn** — apply gravity with `UIGravityBehavior`, then **rotate gravity direction with device tilt** via `CoreMotion`.

```swift
let gravity = UIGravityBehavior(items: cards)

motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
    guard let m = motion else { return }
    // Convert into a screen-space gravity vector
    let v = OrientationAwareGravity.uiKitVector(
        deviceX: m.gravity.x, deviceY: m.gravity.y
    )
    gravity.gravityDirection = CGVector(dx: v.dx * 2, dy: v.dy * 2)
}
```

Key points:
- `gravityDirection` is a vector in **screen coordinates (top-left origin)**, not device coordinates — so you have to remap based on interface rotation.
- Add `UICollisionBehavior` + `UIDynamicItemBehavior(elasticity:)` so cards collide and bounce off each other.
- Screen rotation must be locked to keep gravity consistent — this demo is **Landscape Locked**.

---

## 2. Snap Grid

> **What you learn** — use `UISnapBehavior` to **snap a dragged item to the nearest grid point like a magnet**.

```swift
@objc func handlePan(_ gesture: UIPanGestureRecognizer) {
    guard let item = gesture.view else { return }
    switch gesture.state {
    case .began:
        // Remove snap while dragging
        if let snap = snapBehaviors[item] { animator?.removeBehavior(snap) }
    case .changed:
        item.center = gesture.location(in: containerView)
        animator?.updateItem(usingCurrentState: item)
    case .ended:
        // Snap to the nearest grid point
        let nearest = nearestGridPoint(to: item.center)
        let snap = UISnapBehavior(item: item, snapTo: nearest)
        snap.damping = currentDamping
        animator?.addBehavior(snap)
        snapBehaviors[item] = snap
    default: break
    }
}
```

Use the `damping` slider (0–1) to **control how bouncy the snap feels**. Closer to 0 = oscillation; 1 = settles smoothly.

---

## 3. Collision Bubbles

> **What you learn** — use `UICollisionBehavior` to build a **tag cloud where multiple objects naturally settle into place**.

```swift
let collision = UICollisionBehavior(items: bubbles)
collision.translatesReferenceBoundsIntoBoundary = true

let item = UIDynamicItemBehavior(items: bubbles)
item.elasticity = 0.6
item.allowsRotation = false   // keep text upright

// Tap to push outward
let push = UIPushBehavior(items: [tappedBubble], mode: .instantaneous)
push.angle = .random(in: 0..<2 * .pi)
push.magnitude = 1.0
animator?.addBehavior(push)
```

`UIPushBehavior`'s `.instantaneous` mode is **a single impulse** (one punch); `.continuous` mode applies a **sustained force** (like wind).

---

## 4. Pendulum (Newton's Cradle)

> **What you learn** — use `UIAttachmentBehavior` to create **string/spring connections**, and combine with gravity and collision to demonstrate **momentum transfer**.

```swift
for ball in balls {
    let attachment = UIAttachmentBehavior(
        item: ball,
        attachedToAnchor: anchorAbove(ball)
    )
    attachment.length = stringLength
    attachment.damping = 0      // lossless pendulum
    animator?.addBehavior(attachment)
}

// All balls collide with each other
let collision = UICollisionBehavior(items: balls)
let item = UIDynamicItemBehavior(items: balls)
item.elasticity = 1.0           // perfectly elastic collision
animator?.addBehavior(collision)
animator?.addBehavior(item)
```

> 💡 **Drag interaction via `UISnapBehavior`**: when grabbing a ball with your finger, attach a `UISnapBehavior(item:snapTo:)` to follow the finger; remove the snap on release for a natural drop. (Pattern from rafcio2k's NewtonsCradlePlayground.)

---

## 5. Elastic Menu

> **What you learn** — use `UIAttachmentBehavior`'s **spring mode** to anchor each item to its ideal position, plus weak springs between adjacent items so they **follow each other in a chain**.

```swift
// Anchor each menu item to its "ideal position" with a spring
for (i, item) in items.enumerated() {
    let anchor = idealPosition(for: i)
    let spring = UIAttachmentBehavior(item: item, attachedToAnchor: anchor)
    spring.length = 0
    spring.damping = 0.5
    spring.frequency = 3.0
    animator?.addBehavior(spring)
}

// Connect adjacent items with weaker springs too
for i in 0..<(items.count - 1) {
    let chain = UIAttachmentBehavior(item: items[i], attachedTo: items[i+1])
    chain.damping = 0.5
    chain.frequency = 2.0
    animator?.addBehavior(chain)
}
```

When you pull one item, the pull from its own anchor and the chain force from neighbors apply together — yielding a **smoothly oscillating menu**.

---

## Behavior quick reference

| Behavior | Purpose |
|----------|---------|
| `UIGravityBehavior` | Constant acceleration (gravity) |
| `UICollisionBehavior` | Collision between objects or with bounds |
| `UIAttachmentBehavior` | Anchor / spring-connect two points/objects (strings, springs) |
| `UISnapBehavior` | Magnetic attraction to a point (damped oscillation) |
| `UIPushBehavior` | Instant force (.instantaneous) or sustained force (.continuous) |
| `UIDynamicItemBehavior` | Physics properties: friction, elasticity, density, allow rotation, etc. |

---

## Practical Tips

**Best Practices**
- UIKit Dynamics uses **existing UIViews directly** as physics objects, so it's the lightest way to bolt physics interactions onto a SwiftUI screen.
- Tune `UISnapBehavior.damping` (0–1) for the snap's "elastic feel". 0.4–0.6 generally feels natural.
- The simulation auto-pauses when stable, but unused Behaviors should be explicitly `removeBehavior`'d.

**Watch Out**
- From SwiftUI, you must wrap with `UIViewRepresentable` or `UIViewControllerRepresentable`.
- Auto Layout conflicts with the simulation — lay out physics-targeted views with **frames**.
- If `UIDynamicAnimator`'s `referenceView` is released, the simulation stops. Keep a strong reference.
- 100+ items combined with complex Behaviors will bottleneck the CPU. At that point, consider switching to SpriteKit.
