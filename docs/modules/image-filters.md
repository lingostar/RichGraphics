---
layout: default
title: Core Image Filters
---

<div class="breadcrumb">
  <a href="{{ '/' | relative_url }}">Home</a> &gt; Core Image Filters
</div>

<div class="page-header">
  <h1>Core Image Filters</h1>
  <p class="subtitle">Core Image의 GPU 가속 이미지 처리 파이프라인을 학습합니다. 200개 이상의 내장 필터, 필터 체이닝, 실시간 카메라 필터 적용까지 다룹니다.</p>
</div>

<article>

## 개요

**Core Image**는 Apple의 GPU 가속 이미지 처리 프레임워크입니다. 블러, 색상 조정, 왜곡, 합성 등 200개 이상의 내장 필터(CIFilter)를 제공하며, 이들을 체인으로 연결하여 복잡한 이미지 처리 파이프라인을 구성할 수 있습니다.

Core Image는 **지연 평가(lazy evaluation)** 방식으로 동작합니다. 필터를 연결해도 즉시 처리하지 않고, 최종 렌더링 시 GPU에서 한 번에 실행하여 높은 성능을 달성합니다.

### 언제 사용하나요?

- 사진/이미지 편집 앱 (색상 보정, 필터 효과)
- 실시간 카메라 필터 (AVCaptureSession 연동)
- 얼굴 인식 기반 이펙트
- 이미지 합성 및 텍스트 오버레이

## 핵심 API

### CIFilter & CIImage

`CIImage`는 불변(immutable) 이미지 레시피이며, `CIFilter`로 변환합니다. 필터 체이닝은 출력 CIImage를 다음 필터의 입력으로 연결하면 됩니다.

```swift
// 원본 이미지 로드
guard let inputImage = CIImage(image: uiImage) else { return }
// 가우시안 블러 적용
let blur = CIFilter.gaussianBlur()
blur.inputImage = inputImage
blur.radius = 10.0
// 색조 조정 체이닝
let hueAdjust = CIFilter.hueAdjust()
hueAdjust.inputImage = blur.outputImage
hueAdjust.angle = Float.pi / 4
// CIContext로 최종 렌더링
let context = CIContext()
if let output = hueAdjust.outputImage,
   let cgImage = context.createCGImage(output, from: output.extent) {
    let result = UIImage(cgImage: cgImage)
}
```

### CIContext 관리

`CIContext`는 GPU 리소스를 관리하는 무거운 객체입니다. 앱 생명주기 동안 **하나만 생성하여 재사용**하는 것이 핵심 성능 전략입니다.

### 카메라 파이프라인

`AVCaptureSession`에서 실시간 프레임을 받아 Core Image 필터를 적용하면 라이브 카메라 필터를 구현할 수 있습니다. `AVCaptureVideoDataOutputSampleBufferDelegate`의 콜백에서 `CMSampleBuffer` -> `CIImage` 변환 후 필터를 적용합니다.

### CIKernel

내장 필터로 부족할 때, Metal Shading Language로 커스텀 CIKernel을 작성하여 나만의 필터를 만들 수 있습니다.

## 데모 목록

<div class="demo-list">
  <div class="demo-item">
    <h4>1. Filter Gallery</h4>
    <p>Core Image의 주요 필터 카테고리(Blur, Color, Distortion, Stylize)를 탐색하고, 파라미터를 실시간으로 조절하며 결과를 미리봅니다.</p>
  </div>
  <div class="demo-item">
    <h4>2. Filter Chain Builder</h4>
    <p>여러 필터를 드래그 앤 드롭으로 체이닝하여 커스텀 이미지 처리 파이프라인을 시각적으로 구성합니다. 필터 순서에 따른 결과 차이를 비교합니다.</p>
  </div>
  <div class="demo-item">
    <h4>3. Live Camera Filter</h4>
    <p>AVCaptureSession과 Core Image를 연동하여 실시간 카메라 프리뷰에 필터를 적용합니다. 필터 전환 시 부드러운 트랜지션을 구현합니다.</p>
  </div>
  <div class="demo-item">
    <h4>4. Face Detection Effects</h4>
    <p>CIDetector로 얼굴 영역을 감지하고, 해당 영역에만 선택적으로 필터(모자이크, 블러, 스타일 전환)를 적용하는 기법을 실습합니다.</p>
  </div>
</div>

## 실전 팁

<div class="pros-cons">
  <div class="pros">
    <h4>Best Practices</h4>
    <ul>
      <li>`CIContext`는 앱 전체에서 하나만 생성하여 재사용하세요. 매번 생성하면 GPU 리소스 낭비가 심합니다.</li>
      <li>필터 체인 순서가 결과에 큰 영향을 줍니다. 블러 -> 색상 조정과 색상 조정 -> 블러는 결과가 다릅니다.</li>
      <li>실시간 카메라 필터에서는 `CIContext(options: [.useSoftwareRenderer: false])`로 GPU 렌더링을 보장하세요.</li>
      <li>Swift의 타입 안전 CIFilter API(`CIFilter.gaussianBlur()`)를 문자열 기반 API보다 선호하세요.</li>
    </ul>
  </div>
  <div class="cons">
    <h4>주의 사항</h4>
    <ul>
      <li>CIImage는 실제 픽셀 데이터가 아닌 레시피입니다. `CIContext.createCGImage()`로 실제 렌더링을 트리거해야 합니다.</li>
      <li>필터를 과도하게 체이닝하면 GPU 메모리 사용량이 급증할 수 있습니다.</li>
      <li>카메라 프레임 처리 시, 이전 프레임 처리가 끝나기 전에 다음 프레임이 오면 프레임을 드롭해야 합니다.</li>
      <li>CIKernel 작성 시 Metal Shading Language 문법과 Core Image의 좌표계(정규화) 차이에 주의하세요.</li>
    </ul>
  </div>
</div>

</article>
