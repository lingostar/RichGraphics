---
layout: default
title: Image Filters
---

<div class="page-header">
  <div class="breadcrumb"><a href="{{ '/' | relative_url }}">Home</a> / Image Filters</div>
  <h1>Image Filters</h1>
  <p class="subtitle">아이폰 카메라에서 DSLR처럼 렌즈를 겹쳐 쓸 수 있다구요?</p>
  <div class="tech-tags" style="margin-top: 12px;">
    <span class="tech-tag">Core Image</span>
    <span class="tech-tag">AVFoundation</span>
  </div>
</div>

## 개요

**Core Image**는 Apple의 GPU 가속 이미지 처리 프레임워크입니다. 200개 이상의 내장 필터(`CIFilter`)를 **체인으로 연결**해 사진 보정 파이프라인을 구성하거나, `AVFoundation`의 카메라 피드에 **실시간**으로 적용할 수 있습니다.

핵심 추상화 두 개:

- **`CIImage`** — 픽셀 데이터가 아닌 **"이미지를 만드는 레시피"**. 필터를 연결해도 즉시 처리하지 않음.
- **`CIContext`** — GPU 리소스를 관리하는 무거운 객체. **앱 수명 동안 1개만 생성·재사용**하는 게 정석.

```swift
// 1) 입력 → 2) 필터 → 3) 출력 → 4) 렌더
let input  = CIImage(image: photo)!
let blur   = CIFilter.gaussianBlur()
blur.inputImage = input
blur.radius = 8

let context = CIContext()                                // 한 번만 만들어 재사용
let cgImage = context.createCGImage(blur.outputImage!, from: input.extent)!
let result  = UIImage(cgImage: cgImage)
```

이 모듈의 4개 데모는 위 패턴을 **갤러리 → 카메라 실시간 → 체인 → 합성 이펙트** 순서로 확장해 갑니다.

---

## 1. Filter Gallery

> **무엇을 배우나** — 단일 `CIFilter`를 입력 이미지에 적용하고, 파라미터(예: 강도)를 슬라이더로 실시간 조절하는 가장 기본적인 패턴.

```swift
@State var intensity: Double = 0.8
let context = CIContext()                       // 한 번만 생성

func apply(_ filterName: String, to input: CIImage) -> UIImage? {
    guard let filter = CIFilter(name: filterName) else { return nil }
    filter.setValue(input, forKey: kCIInputImageKey)
    filter.setValue(intensity, forKey: kCIInputIntensityKey)

    guard let output = filter.outputImage,
          let cg = context.createCGImage(output, from: input.extent)
    else { return nil }
    return UIImage(cgImage: cg)
}
```

데모는 `Sepia`, `Chrome`, `Noir`, `Bloom`, `Crystallize` 등 15개 썸네일을 그리드로 보여주고, 탭하면 큰 미리보기 + 강도 슬라이더가 나타납니다.

> 💡 **타입 안전 API 권장**: `CIFilter(name: "CISepiaTone")` 같은 문자열 기반 대신 `CIFilter.sepiaTone()`을 쓰면 컴파일 타임에 검증됩니다.

---

## 2. Camera Filters

> **무엇을 배우나** — `AVCaptureSession`으로 카메라 프레임을 받아 **실시간으로** Core Image 필터를 적용하는 파이프라인.

```swift
final class CameraPipeline: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session  = AVCaptureSession()
    let context  = CIContext()
    var filter:  CIFilter?
    var onFrame: (UIImage) -> Void = { _ in }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var image = CIImage(cvPixelBuffer: pixel)

        if let filter = filter {
            filter.setValue(image, forKey: kCIInputImageKey)
            if let out = filter.outputImage { image = out }
        }
        if let cg = context.createCGImage(image, from: image.extent) {
            DispatchQueue.main.async { self.onFrame(UIImage(cgImage: cg)) }
        }
    }
}
```

핵심 포인트:
- `AVCaptureVideoDataOutputSampleBufferDelegate`의 콜백은 백그라운드 큐에서 호출 → UI 갱신은 main으로 dispatch.
- `CIContext`는 반드시 재사용. 매 프레임 생성하면 GPU 리소스 폭발.
- 시뮬레이터에는 카메라가 없으므로, 데모에서는 **절차적으로 만든 애니메이션 이미지를 입력으로 폴백**합니다.

---

## 3. Filter Chain Builder

> **무엇을 배우나** — `outputImage → inputImage`로 **여러 필터를 직렬 연결**하는 패턴, 그리고 **순서가 결과를 바꾸는** 사실의 시각화.

```swift
struct FilterSlot: Identifiable {
    let id = UUID()
    var filterName: String
    var intensity: Double
}

@State var slots: [FilterSlot] = []

func processChain(input: CIImage) -> CIImage {
    var current = input
    for slot in slots {
        guard let filter = CIFilter(name: slot.filterName) else { continue }
        filter.setValue(current, forKey: kCIInputImageKey)
        filter.setValue(slot.intensity, forKey: kCIInputIntensityKey)
        if let out = filter.outputImage { current = out }
    }
    return current
}
```

같은 두 필터라도:
- **블러 → 색상 조정**: 이미 흐려진 색을 조정 → 톤이 부드러움
- **색상 조정 → 블러**: 또렷한 색을 흐리게 → 색이 번지는 느낌

데모에서는 슬롯을 최대 5개까지 쌓고, 슬롯 순서를 드래그로 바꿀 수 있습니다.

---

## 4. Custom Effects

> **무엇을 배우나** — 여러 필터를 조합해 **완성된 한 장의 룩(look)**을 만들고, before/after 슬라이더로 비교하는 패턴.

데모는 4가지 프리셋(글리치, 빈티지, 팝아트, 네온 글로우)을 제공합니다. 각 프리셋은 단일 필터가 아니라 **여러 필터의 합성 결과**입니다.

```swift
// 빈티지 프리셋 예시
func vintage(_ input: CIImage) -> CIImage? {
    let sepia = CIFilter.sepiaTone()
    sepia.inputImage = input
    sepia.intensity  = 0.8

    let vignette = CIFilter.vignette()
    vignette.inputImage = sepia.outputImage
    vignette.intensity  = 1.0
    vignette.radius     = 2.0

    let noise = CIFilter.colorMonochrome()
    // ... 추가 합성

    return vignette.outputImage
}
```

before/after 슬라이더는 동일 위치에 원본과 처리 결과를 겹쳐 두고, 슬라이더의 X 좌표 기준으로 클리핑(`mask`)을 잘라 반반 보여줍니다.

> 💡 **CIKernel로 한 단계 더**: 내장 필터 조합으로도 부족하면 Metal Shading Language로 직접 `CIKernel`을 작성해 픽셀별 커스텀 연산을 추가할 수 있습니다.

---

## 실전 팁

**Best Practices**
- `CIContext`는 **앱당 1개**. 셀에서 또 만들고, 매 프레임 또 만들면 즉시 성능 폭락.
- 카메라 파이프라인에서는 `CIContext(options: [.useSoftwareRenderer: false])`로 GPU 강제.
- Swift 타입 안전 API(`CIFilter.sepiaTone()`)를 쓰면 키 이름 오타로 인한 런타임 실패가 없어집니다.
- 필터 체인 순서는 **결과를 결정하는 변수**. 같은 두 필터라도 순서가 바뀌면 다른 결과.

**주의 사항**
- `CIImage`는 픽셀이 아닌 **레시피**입니다. 실제 픽셀이 필요하면 반드시 `CIContext.createCGImage(_:from:)`로 렌더링.
- 카메라 프레임은 백그라운드 큐 → UI 갱신은 반드시 main dispatch.
- 필터를 과도하게 체이닝하면 GPU 메모리 사용량이 빠르게 증가. 가능하면 중간 결과를 합쳐 한 번에 처리.
- `CIKernel` 작성 시 Metal Shading Language의 좌표계와 Core Image의 정규화 좌표 차이에 주의.
