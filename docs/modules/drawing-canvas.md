---
layout: default
title: Drawing Canvas
---

<div class="page-header">
  <div class="breadcrumb"><a href="{{ '/' | relative_url }}">Home</a> / Drawing Canvas</div>
  <h1>Drawing Canvas</h1>
  <p class="subtitle">무언가를 그려야 할 때는 일단은 PencilKit. 부족하다 싶으면 CoreGraphics.</p>
  <div class="tech-tags" style="margin-top: 12px;">
    <span class="tech-tag">PencilKit</span>
    <span class="tech-tag">CoreGraphics</span>
  </div>
</div>

## 개요

iOS에서 "그리기"는 두 갈래입니다.

- **PencilKit** — Apple Pencil 필압·기울기·방위각을 자동으로 인식하고, 도구 팔레트(`PKToolPicker`)와 무한 캔버스를 무료로 얻는 **고수준** 프레임워크. 노트·서명·스케치 앱이라면 여기서 시작하세요.
- **CoreGraphics(Quartz 2D)** — `CGContext`/`CGPath` 기반의 **저수준** 2D 드로잉 엔진. 도형 에디터, 차트, 시그니처 캡처 같은 **그리기 동작 자체를 직접 제어**해야 할 때 사용합니다.

```swift
// SwiftUI에서 CoreGraphics를 가장 가볍게 쓰는 방법
Canvas { context, size in
    var path = Path()
    path.move(to: .zero)
    path.addCurve(to: CGPoint(x: size.width, y: size.height),
                  control1: CGPoint(x: size.width, y: 0),
                  control2: CGPoint(x: 0, y: size.height))
    context.stroke(path, with: .color(.purple), lineWidth: 3)
}
```

이 모듈의 3개 데모는 **저수준에서 고수준으로 단계적으로 올라가며** 드로잉을 다룹니다.

---

## 1. Freehand Drawing

> **무엇을 배우나** — SwiftUI `Canvas`와 `DragGesture`로 **CoreGraphics 기반 자유 드로잉**을 처음부터 만드는 패턴.

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

핵심 포인트:
- `Canvas`는 매 프레임 다시 그리는 immediate-mode API. 모든 stroke를 다시 그리는 비용이 부담되면 캐싱이 필요합니다.
- 색상 팔레트, 굵기 슬라이더, 지우개, undo/redo는 모두 `[Stroke]` 배열을 조작하는 일.

---

## 2. PencilKit Canvas

> **무엇을 배우나** — `PKCanvasView`를 SwiftUI에 통합해 **수십 줄로 본격 드로잉 앱**을 만드는 패턴.

```swift
struct PencilCanvas: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    let toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput   // 시뮬레이터에서도 마우스 입력 허용
        canvas.tool = PKInkingTool(.pen, color: .black, width: 5)
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
```

PencilKit이 **자동으로 처리**해주는 것:
- Apple Pencil 필압·기울기·방위각
- 펜·연필·마커·하이라이터·지우개·자(Ruler) 도구
- 무한 캔버스, 핀치-줌
- 손글씨 인식 연동

내보내기는 한 줄:
```swift
let image = canvas.drawing.image(from: canvas.bounds, scale: UIScreen.main.scale)
```

> 💡 **CoreGraphics와 비교**: 데모 1과 같은 인터랙션을 PencilKit이 5줄로 끝내줍니다. 단, 결과물에 대한 **세밀한 커스터마이징은 제약**이 큽니다.

---

## 3. Shape Builder

> **무엇을 배우나** — 터치 제스처로 **선·사각형·원·삼각형**을 인터랙티브하게 그리고, **stroke와 fill 색상을 분리**해 다루는 패턴.

```swift
enum ShapeKind { case line, rectangle, ellipse, triangle }

struct DrawnShape {
    var kind: ShapeKind
    var rect: CGRect          // 시작점-끝점이 만드는 경계 사각형
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

여기서 배우는 핵심:
- **드래그 시작점-현재점**으로 만들어지는 경계 사각형(`rect`)에서 도형을 정의
- 각 도형 종류마다 `Path`로 매핑 (선분 / `addRect` / `addEllipse(in:)` / 삼각형 path)
- **fill과 stroke를 별개의 색상**으로 다루는 두 단계 그리기

---

## 실전 팁

**Best Practices**
- 단순 드로잉/필기 앱이라면 PencilKit으로 시작 — 개발 속도와 품질에서 압도적으로 유리합니다.
- SwiftUI `Canvas`는 immediate-mode라 매 프레임 다시 그립니다. stroke가 1000개 단위로 늘어나면 **vector → bitmap 캐싱**을 고려하세요.
- PKDrawing은 `Data`로 직렬화/역직렬화가 간편합니다. 저장/복원이 필요하면 PencilKit이 유리.

**주의 사항**
- CoreGraphics(Quartz 2D)의 좌표 원점은 **좌하단**(수학적 좌표). UIKit/SwiftUI는 좌상단. 둘을 혼용할 때 변환에 주의.
- PencilKit은 iOS/iPadOS 전용. macOS Catalyst에서는 일부 기능이 제한됩니다.
- Apple Pencil의 **predicted touches**를 활용하면 체감 지연을 줄일 수 있습니다 (`UITouch.predictedTouches(for:)`).
- 고해상도 비트맵을 만들 때는 `UIScreen.main.scale`을 곱해 리사이즈해야 흐릿해지지 않습니다.
