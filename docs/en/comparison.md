---
layout: default
title: Framework Comparison
lang: en
---

[Home]({{ '/en/' | relative_url }}) > Framework Comparison

# Apple Graphics Framework Comparison

A student-friendly side-by-side look at each framework's purpose, difficulty, and trade-offs.

## At a glance

| | SwiftUI Animation | CoreGraphics | SpriteKit | SceneKit | Metal | Core Image | CAEmitterLayer | UIKit Dynamics |
|---|---|---|---|---|---|---|---|---|
| **Purpose** | UI motion / transitions | 2D drawing | 2D games / physics | 3D visualization | Custom GPU | Image processing | Particle effects | Physics-based UI |
| **Dimension** | 2D (with 3D transforms) | 2D | 2D | 3D | 2D/3D | 2D | 2D | 2D |
| **Learning curve** | ★★☆☆☆ | ★★★☆☆ | ★★★☆☆ | ★★★★☆ | ★★★★★ | ★★★☆☆ | ★★☆☆☆ | ★★☆☆☆ |
| **SwiftUI integration** | Native | Canvas | SpriteView | SceneView | Representable | Manual conversion | Representable | Representable |
| **GPU acceleration** | Automatic | Partial | Automatic | Automatic | Manual control | Automatic | Automatic | CPU |
| **Real-time interaction** | High | Moderate | High | High | High | Moderate | Moderate | High |
| **Simulator support** | Full | Full | Full | Partial | Not supported | Full | Full | Full |

## Per-framework detail

### SwiftUI Animation

#### Pros

- Declarative syntax — short and intuitive
- Built into SwiftUI, no extra import needed
- iOS 17 KeyframeAnimator/PhaseAnimator handle complex sequences
- matchedGeometryEffect makes hero transitions trivial
- Automatic GPU acceleration and 60fps optimization
- Instant feedback in Xcode Preview

#### Cons

- No pixel-level precise graphics control
- No physics simulation or particle systems
- Many APIs are iOS 17+, so backwards-compat concerns
- Complex animations get tricky with State management
- Custom timing curves are limited

**Choose this when:** Standard UI transitions, button/card animations, screen transitions. The first option to try in most apps.

---

### CoreGraphics (Quartz 2D)

#### Pros

- The foundation of Apple graphics — understanding it makes other frameworks easier
- Full 2D drawing control (paths, curves, gradients, transforms)
- Naturally integrates with SwiftUI Canvas
- Versatile: PDF generation, image composition, and more
- A mature API with abundant references and examples

#### Cons

- The C-style API (CGContext) feels unnatural in Swift
- You implement animation yourself (need a frame loop)
- CPU-bound bottleneck on complex scenes
- Mathematical coordinate system (origin at bottom-left) — opposite of UIKit
- You map touch interactions yourself

**Choose this when:** Drawing apps, chart/graph rendering, custom UIView drawing, PDF generation. When you need finer control than PencilKit offers.

---

### PencilKit

#### Pros

- Apple Pencil pressure/tilt automatically supported
- Built-in tool picker (pen, marker, eraser, ruler)
- Canvas with built-in zoom/scroll
- Easy save/load via PKDrawing serialization
- Hooks into handwriting recognition

#### Cons

- Limited customization of the drawing output
- Hard to access individual stroke data
- UIKit-based, requires UIViewRepresentable
- No vector export (SVG)
- Not suitable for games or real-time graphics

**Choose this when:** Note apps, signature capture, sketching features. When you want to make the most of Apple Pencil.

---

### SpriteKit

#### Pros

- Full 2D physics engine built in (gravity, collision, joints, fields)
- Very easy SwiftUI integration via SpriteView
- SKAction system expresses complex sequences concisely
- Texture atlas, particle editor, and other Xcode tooling
- Useful for physics interactions even outside games
- Fully functional in the Simulator

#### Cons

- UIKit/AppKit coordinate system (origin at bottom-left)
- Syncing data between SwiftUI State and SpriteKit Scene is finicky
- No 3D — switch to SceneKit if you need 3D
- Performance degrades with large numbers of nodes (1000+)
- Frequent friction with Swift 6 strict concurrency

**Choose this when:** 2D games, physics simulations, interactive educational content. When you need richer physics than UIKit Dynamics.

---

### SceneKit

#### Pros

- Build a 3D scene in just a few lines — much easier than Metal
- Built-in physics, particle, and animation systems
- USDZ/DAE model loading
- SwiftUI integration via SceneView
- Custom graphics possible via Metal shader modifiers
- Integrates naturally with ARKit

#### Cons

- Apple is shifting focus to RealityKit; updates are slowing
- Metal shaders don't run in the Simulator
- Limited optimization tools for large scenes
- Can't customize the rendering pipeline (you'd need raw Metal)
- Shader modifier debugging is very hard (poor error messages)

**Choose this when:** 3D model viewers, product visualization, simple 3D games, AR prototypes. When you want 3D without raw Metal.

---

### Metal

#### Pros

- Full GPU control — maximum performance
- Custom rendering pipelines, compute shaders
- Optimized performance on Apple Silicon
- Also useful for machine learning (MPS) and image processing
- Powers the backends of other frameworks (SceneKit, Core Image)

#### Cons

- Very steep learning curve (requires GPU architecture knowledge)
- Lots of boilerplate (devices, queues, pipelines, descriptors...)
- Doesn't work in the Simulator — physical device required
- Hard to debug (GPU crashes give limited information)
- Overkill for most apps (SceneKit/Core Image is usually enough)

**Choose this when:** High-performance game engines, custom renderers, GPU compute, image/video processing pipelines. Only when other frameworks can't deliver the performance or features you need.

---

### Core Image

#### Pros

- 200+ built-in filters ready to use
- Filter chaining is simple (output → input)
- Automatic GPU acceleration with deferred-execution optimizations
- Integrates with AVFoundation for real-time camera filters
- Custom filters via CIKernel, written in Metal

#### Cons

- Real-time rendering requires reusing CIContext and other optimizations
- Filter parameters are string-keyed — no compile-time type safety
- CIImage → UIImage conversion has a performance cost
- Not suited for interactive graphics or games
- Writing a custom CIKernel requires knowing both Metal and Core Image

**Choose this when:** Photo-editing apps, camera filters, image correction/composition. Combining built-in filters covers most image-processing needs.

---

### CAEmitterLayer

#### Pros

- Lives at the Core Animation level, so usable from UIKit or SwiftUI
- GPU-accelerated particle rendering — thousands of particles stay smooth
- Configuration-driven — no physics/math code, just tune properties
- Embed emitters within emitters for complex effects (fireworks, etc.)
- High visual impact relative to learning cost

#### Cons

- No control over individual particles (batch settings only)
- No collision or interaction between particles
- Requires UIViewRepresentable wrapping (SwiftUI)
- Many parameters — trial and error to dial in the look
- No particle editor in Xcode (unlike SpriteKit)

**Choose this when:** Celebration effects, weather effects, UI decoration, background animations. Visual effects that don't require particles to interact.

---

### UIKit Dynamics

#### Pros

- Apply physics to plain UIViews — no game framework needed
- Intuitive Behavior composition: gravity, collision, snap, attachment
- Hooks naturally into touch gestures
- Works with the UI elements you already have (buttons, images, custom views)
- Low learning cost, big visual payoff

#### Cons

- UIKit-based — needs UIViewRepresentable in SwiftUI
- Lower physics precision than SpriteKit
- No advanced physics features like joints/fields
- Performance drops with lots of items (100+)
- Apple has effectively stopped updating it

**Choose this when:** Drag-and-drop UI, elastic menus, card interfaces, physics-based scrolling. To add a "physical feel" to non-game apps.

---

## Selection flowchart

```
"I want to add some graphics"
    │
    ├─ UI transitions / motion? → SwiftUI Animation
    │
    ├─ Drawing / painting?
    │   ├─ Apple Pencil needed? → PencilKit
    │   └─ Custom control needed? → CoreGraphics
    │
    ├─ 2D games / physics?
    │   ├─ Game level? → SpriteKit
    │   └─ Just physics on UI? → UIKit Dynamics
    │
    ├─ 3D?
    │   ├─ Quick prototype? → SceneKit
    │   └─ Custom rendering? → Metal
    │
    ├─ Image processing? → Core Image
    │
    └─ Particle effects? → CAEmitterLayer
```

## SpriteKit vs UIKit Dynamics: which one when?

Both deal with "physics" but for different goals.

| | SpriteKit | UIKit Dynamics |
|---|---|---|
| **Target** | Game objects (SKNode) | Standard UI elements (UIView) |
| **Coordinate system** | Origin at bottom-left | Origin at top-left |
| **Physics features** | Rich (joints, fields, collision masks) | Basic (gravity, collision, snap) |
| **Rendering** | Separate render loop (SKScene) | UIKit layout system |
| **Best for** | Games, educational simulations | Drag & drop, elastic UI, cards |
| **SwiftUI** | SpriteView (easy) | UIViewRepresentable (manual) |

**Decision criterion:** "Are my physics objects UIViews (buttons, images, etc.)?" → UIKit Dynamics. "Is it a separate game scene?" → SpriteKit.

## SceneKit vs Metal: which one when?

| | SceneKit | Metal |
|---|---|---|
| **Entry barrier** | Low (a 3D scene in a few lines) | Very high (need to understand the GPU pipeline) |
| **Customization** | Limited via shader modifiers | Unlimited |
| **Model loading** | USDZ, DAE built in | Need to write your own parser |
| **Debugging** | Xcode Scene Editor | GPU Frame Debugger |
| **Performance ceiling** | Medium | Maximum |
| **Best for** | Product viewers, education, AR | Game engines, scientific visualization, ML |

**Decision criterion:** "Can I implement this with SceneKit's shader modifiers?" → SceneKit. "Do I need to control the rendering pipeline directly?" → Metal.
