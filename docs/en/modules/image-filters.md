---
layout: default
title: Image Filters
lang: en
---

<div class="page-header">
  <div class="breadcrumb"><a href="{{ '/en/' | relative_url }}">Home</a> / Image Filters</div>
  <h1>Image Filters</h1>
  <p class="subtitle">Wait, you can stack filters on the iPhone camera like a DSLR with interchangeable lenses?</p>
  <div class="tech-tags" style="margin-top: 12px;">
    <span class="tech-tag">Core Image</span>
    <span class="tech-tag">AVFoundation</span>
  </div>
</div>

## Overview

**Core Image** is Apple's GPU-accelerated image processing framework. **Chain** any of 200+ built-in filters (`CIFilter`) into a photo-editing pipeline, or apply them in **real time** to an `AVFoundation` camera feed.

Two key abstractions:

- **`CIImage`** — not pixels, but a **"recipe to make an image"**. Connecting filters doesn't process anything immediately.
- **`CIContext`** — a heavy object that manages GPU resources. The standard practice is to **create one and reuse it for the app's lifetime**.

```swift
// 1) input → 2) filter → 3) output → 4) render
let input  = CIImage(image: photo)!
let blur   = CIFilter.gaussianBlur()
blur.inputImage = input
blur.radius = 8

let context = CIContext()                                // create once, reuse
let cgImage = context.createCGImage(blur.outputImage!, from: input.extent)!
let result  = UIImage(cgImage: cgImage)
```

The four demos in this module expand this pattern in order: **gallery → real-time camera → chain → composite effects**.

---

## 1. Filter Gallery

> **What you learn** — apply a single `CIFilter` to an input image and tune a parameter (e.g. intensity) in real time with a slider — the most basic pattern.

```swift
@State var intensity: Double = 0.8
let context = CIContext()                       // create once

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

The demo shows 15 thumbnails — `Sepia`, `Chrome`, `Noir`, `Bloom`, `Crystallize`, etc. — in a grid; tap one for a large preview and intensity slider.

> 💡 **Prefer the type-safe API**: instead of string-based `CIFilter(name: "CISepiaTone")`, use `CIFilter.sepiaTone()` — it's verified at compile time.

---

## 2. Camera Filters

> **What you learn** — pull camera frames from `AVCaptureSession` and apply Core Image filters **in real time**.

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

Key points:
- `AVCaptureVideoDataOutputSampleBufferDelegate` callbacks fire on a background queue → dispatch UI updates to main.
- Always reuse `CIContext`. Creating it every frame blows up GPU resources.
- The Simulator has no camera, so the demo **falls back to a procedurally generated animated image** as input.

---

## 3. Filter Chain Builder

> **What you learn** — chain **multiple filters in sequence** via `outputImage → inputImage`, and visualize how **order changes the result**.

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

The same two filters can produce different results depending on order:
- **Blur → color adjust**: tones get smoother because already-blurred colors are adjusted
- **Color adjust → blur**: feels like color smearing because crisp colors get blurred

The demo lets you stack up to 5 slots and reorder them by dragging.

---

## 4. Custom Effects

> **What you learn** — combine multiple filters into a **single finished "look"**, and compare with a before/after slider.

The demo includes 4 presets (glitch, vintage, pop art, neon glow). Each preset is **the result of composing multiple filters**, not a single one.

```swift
// Vintage preset example
func vintage(_ input: CIImage) -> CIImage? {
    let sepia = CIFilter.sepiaTone()
    sepia.inputImage = input
    sepia.intensity  = 0.8

    let vignette = CIFilter.vignette()
    vignette.inputImage = sepia.outputImage
    vignette.intensity  = 1.0
    vignette.radius     = 2.0

    let noise = CIFilter.colorMonochrome()
    // ... additional composition

    return vignette.outputImage
}
```

The before/after slider stacks the original and processed images at the same position and uses the slider's X coordinate to clip (`mask`) the boundary, revealing each half.

> 💡 **Going further with CIKernel**: when built-in filter combinations aren't enough, you can write a custom `CIKernel` in Metal Shading Language to add per-pixel custom math.

---

## Practical Tips

**Best Practices**
- **One `CIContext` per app**. Creating it inside a cell, or per frame, instantly tanks performance.
- For camera pipelines, force GPU with `CIContext(options: [.useSoftwareRenderer: false])`.
- Use the Swift type-safe API (`CIFilter.sepiaTone()`) to avoid runtime failures from misspelled key names.
- Filter-chain order is a **variable that determines the result**. The same two filters in different orders produce different outputs.

**Watch Out**
- `CIImage` is a **recipe**, not pixels. To get actual pixels, render via `CIContext.createCGImage(_:from:)`.
- Camera frames arrive on a background queue → always dispatch UI updates to main.
- Excessive chaining quickly grows GPU memory usage. When possible, fold intermediate results into a single pass.
- When writing a `CIKernel`, mind the difference between Metal Shading Language coordinates and Core Image's normalized coordinates.
