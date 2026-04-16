---
layout: default
title: Home
---

<div class="hero">
  <h1>RichGraphics</h1>
  <p>Apple의 그래픽 프레임워크를 직접 만져보며 배우는 iOS 그래픽스 레퍼런스. 7개 모듈, 38개 인터랙티브 데모.</p>
</div>

<h2 class="section-title">Modules</h2>

<div class="module-grid">

  <a href="{{ '/modules/swiftui-animations' | relative_url }}" class="module-card">
    <div class="card-icon">✨</div>
    <h3>SwiftUI Animations</h3>
    <p>Spring, Keyframe, Phase, Morphing 등 SwiftUI 네이티브 애니메이션 시스템 탐험</p>
    <div class="tech-tags">
      <span class="tech-tag">SwiftUI</span>
      <span class="tech-tag">Animation</span>
      <span class="tech-tag">7 demos</span>
    </div>
  </a>

  <a href="{{ '/modules/drawing-canvas' | relative_url }}" class="module-card">
    <div class="card-icon">🖌️</div>
    <h3>Drawing Canvas</h3>
    <p>CoreGraphics와 PencilKit으로 드로잉 앱의 핵심 기술 구현</p>
    <div class="tech-tags">
      <span class="tech-tag">CoreGraphics</span>
      <span class="tech-tag">PencilKit</span>
      <span class="tech-tag">5 demos</span>
    </div>
  </a>

  <a href="{{ '/modules/spritekit-physics' | relative_url }}" class="module-card">
    <div class="card-icon">⚛️</div>
    <h3>SpriteKit Physics</h3>
    <p>2D 물리엔진으로 중력, 충돌, 관절, 자기장 시뮬레이션</p>
    <div class="tech-tags">
      <span class="tech-tag">SpriteKit</span>
      <span class="tech-tag">CoreMotion</span>
      <span class="tech-tag">6 demos</span>
    </div>
  </a>

  <a href="{{ '/modules/scenekit-3d' | relative_url }}" class="module-card">
    <div class="card-icon">🧊</div>
    <h3>SceneKit / Metal 3D</h3>
    <p>3D 렌더링, 프로시저럴 지형, 셰이더, 태양계 시뮬레이션</p>
    <div class="tech-tags">
      <span class="tech-tag">SceneKit</span>
      <span class="tech-tag">Metal</span>
      <span class="tech-tag">5 demos</span>
    </div>
  </a>

  <a href="{{ '/modules/image-filters' | relative_url }}" class="module-card">
    <div class="card-icon">📸</div>
    <h3>Core Image Filters</h3>
    <p>실시간 이미지/카메라 필터, 필터 체인 빌더, 커스텀 이펙트</p>
    <div class="tech-tags">
      <span class="tech-tag">Core Image</span>
      <span class="tech-tag">AVFoundation</span>
      <span class="tech-tag">4 demos</span>
    </div>
  </a>

  <a href="{{ '/modules/particle-effects' | relative_url }}" class="module-card">
    <div class="card-icon">🎆</div>
    <h3>Particle Effects</h3>
    <p>CAEmitterLayer로 불꽃놀이, 날씨, 파티클 트레일 구현</p>
    <div class="tech-tags">
      <span class="tech-tag">CAEmitterLayer</span>
      <span class="tech-tag">Core Animation</span>
      <span class="tech-tag">6 demos</span>
    </div>
  </a>

  <a href="{{ '/modules/uikit-dynamics' | relative_url }}" class="module-card">
    <div class="card-icon">🎯</div>
    <h3>UIKit Dynamics</h3>
    <p>물리 기반 UI: 중력 카드, 뉴턴의 요람, 탄성 메뉴</p>
    <div class="tech-tags">
      <span class="tech-tag">UIKit Dynamics</span>
      <span class="tech-tag">UIDynamicAnimator</span>
      <span class="tech-tag">5 demos</span>
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
