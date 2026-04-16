---
layout: default
title: Drawing Canvas
---

[Home]({{ '/' | relative_url }}) > Drawing Canvas

# Drawing Canvas

CoreGraphics(Quartz 2D)의 저수준 드로잉 API와 PencilKit의 고수준 필기/드로잉 프레임워크를 함께 학습합니다. 벡터 경로부터 Apple Pencil 필압 인식까지 다룹니다.

## 개요

iOS 드로잉은 크게 두 가지 접근법으로 나뉩니다.

**CoreGraphics(Quartz 2D)** 는 C 기반의 저수준 2D 드로잉 엔진입니다. `CGContext`를 통해 경로(Path), 그라디언트, 변환 행렬 등을 직접 제어하며, 커스텀 차트, 도형 에디터, 이미지 합성 등 정밀한 그래픽 작업에 사용합니다.

**PencilKit**은 Apple Pencil 지원을 포함한 드로잉 환경을 제공하는 고수준 프레임워크입니다. 필압, 기울기, 방위각 인식과 함께 내장 도구 팔레트(PKToolPicker)를 제공하여 드로잉 앱을 빠르게 구축할 수 있습니다.

### 언제 사용하나요?

| 목적 | 추천 |
|------|------|
| 커스텀 차트/그래프 | CoreGraphics |
| 벡터 도형 에디터 | CoreGraphics + CGPath |
| 자유 드로잉/필기 앱 | PencilKit |
| Apple Pencil 필압 활용 | PencilKit |
| 이미지 위 오버레이 | CoreGraphics |

## 핵심 API

### CoreGraphics Drawing

SwiftUI의 `Canvas` 뷰는 CoreGraphics 드로잉을 SwiftUI에 통합하는 가장 간단한 방법입니다.

```swift
Canvas { context, size in
    let rect = CGRect(origin: .zero, size: size)
    // 그라디언트 배경
    let gradient = Gradient(colors: [.blue, .purple])
    context.fill(
        Path(rect),
        with: .linearGradient(gradient,
            startPoint: .zero,
            endPoint: CGPoint(x: size.width, y: size.height))
    )
    // 커스텀 경로
    var path = Path()
    path.move(to: CGPoint(x: 50, y: 50))
    path.addCurve(to: CGPoint(x: 250, y: 50),
        control1: CGPoint(x: 100, y: 0),
        control2: CGPoint(x: 200, y: 100))
    context.stroke(path, with: .color(.white), lineWidth: 3)
}
```

### PencilKit Integration

`PKCanvasView`는 UIKit 기반이므로 SwiftUI에서 `UIViewRepresentable`로 래핑하여 사용합니다.

```swift
struct DrawingCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        // Tool Picker 표시
        let picker = PKToolPicker()
        picker.setVisible(true, forFirstResponder: canvasView)
        picker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        return canvasView
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
```

### 주요 클래스

- **CGContext**: 드로잉 명령을 받는 그래픽 컨텍스트. 비트맵/PDF 컨텍스트 생성 가능
- **CGPath / UIBezierPath**: 직선, 곡선, 호 등으로 구성된 벡터 경로
- **PKCanvasView**: PencilKit의 드로잉 영역. PKDrawing 데이터를 관리
- **PKToolPicker**: 펜, 마커, 지우개 등 도구 선택 UI

## 데모 목록

| # | 데모 | 설명 |
|---|------|------|
| 1 | **Bezier Path Editor** | Control Point를 드래그하여 3차 베지어 곡선을 실시간으로 조작합니다. CGPath의 구조와 곡선 수학을 시각적으로 이해합니다. |
| 2 | **Gradient & Pattern Lab** | Linear, Radial, Conic Gradient와 타일링 패턴을 CoreGraphics로 직접 그립니다. CGGradient과 CGPattern API를 실습합니다. |
| 3 | **PencilKit Sketchpad** | PKCanvasView와 PKToolPicker를 활용한 드로잉 앱. 필압에 따른 선 굵기 변화와 도구 전환을 체험합니다. |
| 4 | **Transform Playground** | CGAffineTransform(이동, 회전, 스케일)을 조합하며 좌표 변환의 순서가 결과에 미치는 영향을 실험합니다. |
| 5 | **Image Compositing** | CGContext의 blendMode를 활용하여 여러 이미지를 합성합니다. 마스킹과 클리핑 경로 기법도 함께 다룹니다. |

## 실전 팁

### Best Practices

- 단순 드로잉/필기 앱이라면 PencilKit이 개발 속도와 품질 면에서 유리합니다.
- CoreGraphics는 좌표계 원점이 좌하단(UIKit에서는 좌상단)임에 주의하세요.
- SwiftUI `Canvas` 뷰는 매 프레임 다시 그리므로, 복잡한 드로잉은 캐싱을 고려하세요.
- PKDrawing은 Data로 직렬화되어 저장/복원이 간편합니다.
- Apple Pencil의 예측(predicted) 터치를 활용하면 체감 지연을 줄일 수 있습니다.

### 주의 사항

- CGContext 기반 드로잉은 반드시 `saveGState()`/`restoreGState()` 쌍으로 상태를 관리하세요.
- PencilKit은 iOS/iPadOS 전용으로, macOS에서는 제한적입니다.
- UIBezierPath와 CGPath는 변환 가능하지만, 혼용 시 좌표계 차이에 주의하세요.
- 고해상도(Retina) 디스플레이에서는 `UIScreen.main.scale`을 반영해야 선명하게 그려집니다.
