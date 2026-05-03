---
layout: default
title: Home
---

<div class="hero">
  <h1>RichGraphics</h1>
  <p>풍부한 그래픽을 표시하기 위해 알아둬야 할 다양한 기술들을 살펴봅시다.</p>
</div>

<h2 class="section-title">Modules</h2>

<div class="module-grid">

  <a href="{{ '/modules/swiftui-animations' | relative_url }}" class="module-card">
    <div class="card-icon">✨</div>
    <h3>SwiftUI Animations</h3>
    <p>가장 친근한 기술에서 얻을 수 있는 강력한 애니메이션. 시작은 SwiftUI 에서.</p>
    <div class="tech-tags">
      <span class="tech-tag">SwiftUI</span>
    </div>
  </a>

  <a href="{{ '/modules/drawing-canvas' | relative_url }}" class="module-card">
    <div class="card-icon">🖌️</div>
    <h3>Drawing Canvas</h3>
    <p>무언가를 그려야 할 때는 일단은 PencilKit. 부족하다 싶으면 CoreGraphics.</p>
    <div class="tech-tags">
      <span class="tech-tag">PencilKit</span>
      <span class="tech-tag">CoreGraphics</span>
    </div>
  </a>

  <a href="{{ '/modules/3d-world-and-physics' | relative_url }}" class="module-card">
    <div class="card-icon">🧊</div>
    <h3>3D World & Physics</h3>
    <p>Swift 언어로 구현하는 3D 그래픽스. 앱 안에서 공간을 열어보세요.</p>
    <div class="tech-tags">
      <span class="tech-tag">SpriteKit</span>
      <span class="tech-tag">SceneKit</span>
      <span class="tech-tag">CAEmitterLayer</span>
    </div>
  </a>

  <a href="{{ '/modules/image-filters' | relative_url }}" class="module-card">
    <div class="card-icon">📸</div>
    <h3>Image Filters</h3>
    <p>아이폰 카메라에서 DSLR처럼 렌즈를 겹쳐 쓸 수 있다구요?</p>
    <div class="tech-tags">
      <span class="tech-tag">Core Image</span>
      <span class="tech-tag">AVFoundation</span>
    </div>
  </a>

  <a href="{{ '/modules/uikit-dynamics' | relative_url }}" class="module-card">
    <div class="card-icon">🎯</div>
    <h3>UIKit Dynamics</h3>
    <p>UIKit이 열어주는 새로운 차원의 풍부한 그래픽스와 물리 엔진.</p>
    <div class="tech-tags">
      <span class="tech-tag">UIKit Dynamics</span>
      <span class="tech-tag">UIDynamicAnimator</span>
    </div>
  </a>

</div>

<h2 class="section-title">Quick Reference</h2>

어떤 프레임워크를 선택해야 할지 고민된다면 [**Framework 비교표**]({{ '/comparison' | relative_url }})를 확인하세요. 각 프레임워크의 용도, 난이도, 장단점을 한눈에 비교할 수 있습니다.

| 목적 | 추천 프레임워크 |
|------|---------------|
| UI 전환/모션 | SwiftUI Animation |
| 드로잉/페인팅 | CoreGraphics + PencilKit |
| 2D 게임/물리 | SpriteKit |
| 3D 시각화 | SceneKit |
| GPU 커스텀 렌더링 | Metal |
| 이미지 처리 | Core Image |
| 파티클/이펙트 | CAEmitterLayer |
| 물리 기반 UI | UIKit Dynamics |
