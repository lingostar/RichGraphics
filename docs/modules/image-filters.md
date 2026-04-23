---
layout: default
title: Core Image Filters
---

[Home]({{ '/' | relative_url }}) > Core Image Filters

# Core Image Filters

Core Image의 GPU 가속 이미지 처리 파이프라인을 학습합니다. 200개 이상의 내장 필터, 필터 체이닝, 실시간 카메라 필터 적용까지 다룹니다.

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

| # | 데모 | 설명 |
|---|------|------|
| 1 | **Filter Gallery** | 15개 Core Image 필터 썸네일 그리드 + 강도 슬라이더. Sepia, Chrome, Noir, Bloom, Crystallize 등을 한눈에 비교. |
| 2 | **Camera Filters** | `AVCaptureSession`과 Core Image를 연동한 실시간 카메라 필터. 시뮬레이터에서는 절차적 이미지 폴백을 사용합니다. |
| 3 | **Filter Chain Builder** | 최대 5개 필터 슬롯을 스택으로 연결하여 커스텀 이미지 처리 파이프라인을 구성합니다. |
| 4 | **Custom Effects** | 여러 필터를 조합한 창의적 이펙트(글리치, 빈티지, 팝아트, 네온 글로우). Before/After 비교 슬라이더 포함. |

## 실전 팁

### Best Practices

- `CIContext`는 앱 전체에서 하나만 생성하여 재사용하세요. 매번 생성하면 GPU 리소스 낭비가 심합니다.
- 필터 체인 순서가 결과에 큰 영향을 줍니다. 블러 -> 색상 조정과 색상 조정 -> 블러는 결과가 다릅니다.
- 실시간 카메라 필터에서는 `CIContext(options: [.useSoftwareRenderer: false])`로 GPU 렌더링을 보장하세요.
- Swift의 타입 안전 CIFilter API(`CIFilter.gaussianBlur()`)를 문자열 기반 API보다 선호하세요.

### 주의 사항

- CIImage는 실제 픽셀 데이터가 아닌 레시피입니다. `CIContext.createCGImage()`로 실제 렌더링을 트리거해야 합니다.
- 필터를 과도하게 체이닝하면 GPU 메모리 사용량이 급증할 수 있습니다.
- 카메라 프레임 처리 시, 이전 프레임 처리가 끝나기 전에 다음 프레임이 오면 프레임을 드롭해야 합니다.
- CIKernel 작성 시 Metal Shading Language 문법과 Core Image의 좌표계(정규화) 차이에 주의하세요.
