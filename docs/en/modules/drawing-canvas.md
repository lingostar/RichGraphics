---
layout: default
title: Drawing Canvas
lang: en
---

<div class="page-header">
  <div class="breadcrumb"><a href="{{ '/en/' | relative_url }}">Home</a> / Drawing Canvas</div>
  <h1>Drawing Canvas</h1>
  <p class="subtitle">When you need to draw, start with PencilKit. Drop down to CoreGraphics when that isn't enough.</p>
  <div class="tech-tags" style="margin-top: 12px;">
    <span class="tech-tag">PencilKit</span>
    <span class="tech-tag">CoreGraphics</span>
  </div>
</div>

## Overview

"Drawing" on iOS splits into two paths.

- **PencilKit** — A **high-level** framework that automatically recognizes Apple Pencil pressure, tilt, and azimuth, and gives you a tool palette (`PKToolPicker`) and infinite canvas for free. Start here for note, signature, or sketch apps.
- **CoreGraphics (Quartz 2D)** — A **low-level** 2D drawing engine on top of `CGContext`/`CGPath`. Use it when you need to **directly control the drawing itself**: shape editors, charts, signature capture, and so on.

```swift
// The lightest way to use CoreGraphics from SwiftUI
Canvas { context, size in
    var path = Path()
    path.move(to: .zero)
    path.addCurve(to: CGPoint(x: size.width, y: size.height),
                  control1: CGPoint(x: size.width, y: 0),
                  control2: CGPoint(x: 0, y: size.height))
    context.stroke(path, with: .color(.purple), lineWidth: 3)
}
```

The three demos in this module **start with high-level PencilKit and gradually descend to low-level CoreGraphics**.

---

## 1. PencilKit Canvas

> **What you learn** — integrate `PKCanvasView` with SwiftUI to **build a real drawing app in just a few dozen lines**.

```swift
struct PencilCanvas: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    let toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput   // accept mouse input in the simulator too
        canvas.tool = PKInkingTool(.pen, color: .black, width: 5)
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
```

What PencilKit **handles automatically**:
- Apple Pencil pressure, tilt, azimuth
- Pen / pencil / marker / highlighter / eraser / ruler tools
- Infinite canvas, pinch-to-zoom
- Hooks into handwriting recognition

Exporting is one line:
```swift
let image = canvas.drawing.image(from: canvas.bounds, scale: UIScreen.main.scale)
```

> 💡 **PencilKit's limits**: It's **hard to finely customize** the output. If you want full control over tools, colors, and the look of strokes, drop down to the next demo (CoreGraphics).

---

## 2. Freehand Drawing

> **What you learn** — build **CoreGraphics-based freehand drawing** from scratch using SwiftUI's `Canvas` and `DragGesture`.

```swift
struct Stroke {
    var color: Color
    var lineWidth: CGFloat
    var points: [CGPoint]
}

@State var strokes: [Stroke] = []
@State var current: Stroke?

Canvas { context, size in
    for stroke in strokes + (current.map { [$0] } ?? []) {
        var path = Path()
        path.addLines(stroke.points)
        context.stroke(path, with: .color(stroke.color), lineWidth: stroke.lineWidth)
    }
}
.gesture(
    DragGesture(minimumDistance: 0)
        .onChanged { value in
            if current == nil {
                current = Stroke(color: selectedColor, lineWidth: width, points: [])
            }
            current?.points.append(value.location)
        }
        .onEnded { _ in
            if let s = current { strokes.append(s) }
            current = nil
        }
)
```

Key points:
- `Canvas` is an immediate-mode API that redraws every frame. Redrawing every stroke can become expensive — caching may be needed.
- Color palette, thickness slider, eraser, undo/redo all boil down to manipulating the `[Stroke]` array.
- The interactions PencilKit gave you in 5 lines, you build yourself here — but you also **control everything**.

---

## 3. Shape Builder

> **What you learn** — interactively draw **lines, rectangles, circles, and triangles** via touch gestures, and **manage stroke and fill colors separately**.

```swift
enum ShapeKind { case line, rectangle, ellipse, triangle }

struct DrawnShape {
    var kind: ShapeKind
    var rect: CGRect          // bounding rect formed by start and end points
    var stroke: Color
    var fill: Color
}

@State var shapes: [DrawnShape] = []
@State var preview: DrawnShape?

Canvas { context, size in
    for shape in shapes + (preview.map { [$0] } ?? []) {
        let path = path(for: shape)
        context.fill(path, with: .color(shape.fill))
        context.stroke(path, with: .color(shape.stroke), lineWidth: 2)
    }
}
.gesture(
    DragGesture(minimumDistance: 0)
        .onChanged { value in
            let r = CGRect(start: value.startLocation, end: value.location)
            preview = DrawnShape(kind: kind, rect: r, stroke: strokeColor, fill: fillColor)
        }
        .onEnded { _ in
            if let p = preview { shapes.append(p) }
            preview = nil
        }
)
```

Key takeaways:
- Define each shape from the **bounding rect formed by the drag's start and current points** (`rect`)
- Map each shape kind to a `Path` (line segment / `addRect` / `addEllipse(in:)` / triangle path)
- Treat **fill and stroke as separate colors** in a two-pass draw

---

## Practical Tips

**Best Practices**
- For simple drawing/note apps, start with PencilKit — overwhelmingly faster development with better quality.
- SwiftUI `Canvas` is immediate-mode — it redraws every frame. When strokes grow into the thousands, consider **vector → bitmap caching**.
- PKDrawing is easy to serialize/deserialize as `Data`. PencilKit wins when you need save/restore.

**Watch Out**
- CoreGraphics (Quartz 2D) has its origin at the **bottom-left** (mathematical coords). UIKit/SwiftUI are top-left. Mind the conversion when mixing.
- PencilKit is iOS/iPadOS only. Some features are limited under macOS Catalyst.
- Use Apple Pencil's **predicted touches** to reduce perceived latency (`UITouch.predictedTouches(for:)`).
- When generating high-resolution bitmaps, multiply by `UIScreen.main.scale` so the image isn't blurry.
