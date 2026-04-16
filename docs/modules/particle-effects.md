---
layout: default
title: Particle Effects
---

[Home]({{ '/' | relative_url }}) > Particle Effects

# Particle Effects

CAEmitterLayer 파티클 시스템으로 불꽃놀이, 눈, 비, 화염, 트레일 등 다양한 시각 이펙트를 구현합니다. Core Animation 기반이라 UIKit/SwiftUI 모두에서 사용 가능합니다.

## 개요

**CAEmitterLayer**는 Core Animation에 내장된 고성능 파티클 시스템입니다. GPU 가속으로 수천 개의 파티클을 효율적으로 렌더링하며, 게임 엔진 없이도 풍부한 시각 이펙트를 구현할 수 있습니다.

CAEmitterLayer(방출기)가 CAEmitterCell(파티클 템플릿)을 생성하는 구조입니다. 하나의 방출기에 여러 셀을 설정하거나, 셀이 하위 셀을 방출하는 계층 구조도 가능합니다.

### 언제 사용하나요?

- 축하/보상 이펙트 (컨페티, 불꽃놀이)
- 날씨/환경 효과 (눈, 비, 안개)
- UI 인터랙션 피드백 (터치 파티클, 버튼 이펙트)
- 배경 장식 (부유하는 입자, 보케 효과)

## 핵심 API

### CAEmitterLayer + CAEmitterCell

```swift
let emitter = CAEmitterLayer()
emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: 0)
emitter.emitterShape = .line
emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)

let cell = CAEmitterCell()
cell.contents = UIImage(named: "spark")?.cgImage
cell.birthRate = 50          // 초당 생성 수
cell.lifetime = 3.0          // 생존 시간 (초)
cell.velocity = 100          // 초기 속도
cell.velocityRange = 50      // 속도 랜덤 범위
cell.emissionLongitude = .pi // 방출 방향 (아래)
cell.emissionRange = .pi / 4 // 방출 각도 범위
cell.spin = 2.0              // 회전 속도
cell.scale = 0.5
cell.scaleSpeed = -0.1       // 시간에 따라 축소
cell.alphaSpeed = -0.3       // 시간에 따라 투명해짐

emitter.emitterCells = [cell]
view.layer.addSublayer(emitter)
```

### 주요 프로퍼티

| 프로퍼티 | 설명 |
|----------|------|
| `birthRate` | 초당 파티클 생성 수. 성능에 직접 영향 |
| `lifetime` | 파티클 생존 시간(초). 화면의 총 파티클 수 = birthRate x lifetime |
| `velocity` / `velocityRange` | 초기 속도와 랜덤 범위 |
| `emissionLongitude` / `emissionRange` | 방출 방향과 확산 범위 |
| `spin` / `spinRange` | 회전 속도와 랜덤 범위 |
| `scale` / `scaleSpeed` | 초기 크기와 시간에 따른 크기 변화 |
| `color` / `redRange`, `greenRange`, `blueRange` | 색상 및 랜덤 색상 범위 |
| `emitterShape` | `.point`, `.line`, `.rectangle`, `.circle`, `.sphere` |

### SwiftUI 통합

`UIViewRepresentable`로 CAEmitterLayer를 감싸거나, SwiftUI의 `.overlay`/`.background`에 배치하여 사용합니다.

## 데모 목록

| # | 데모 | 설명 |
|---|------|------|
| 1 | **Confetti Cannon** | 버튼 탭 시 화면 상단에서 컨페티가 쏟아지는 축하 이펙트. 다양한 색상과 모양의 CAEmitterCell을 조합합니다. |
| 2 | **Weather Effects** | 눈, 비, 안개 등 날씨 이펙트를 구현합니다. emitterShape과 velocity 조합으로 자연스러운 낙하 패턴을 만듭니다. |
| 3 | **Fire & Smoke** | 화염과 연기 이펙트를 계층적 CAEmitterCell(불꽃 -> 연기 -> 불씨)로 구현합니다. alphaSpeed와 scaleSpeed로 생명주기를 표현합니다. |
| 4 | **Touch Trail** | 터치/드래그 위치를 따라 파티클 트레일이 생성되는 인터랙티브 이펙트. emitterPosition을 실시간으로 업데이트합니다. |
| 5 | **Fireworks Show** | 하위 셀(sub-cell)을 활용한 불꽃놀이 시뮬레이션. 발사체 -> 폭발 -> 잔광의 3단계 파티클 계층을 구성합니다. |
| 6 | **Parameter Tuner** | CAEmitterCell의 모든 주요 프로퍼티를 슬라이더로 실시간 조절하며 파티클 동작 변화를 직관적으로 이해합니다. |

## 실전 팁

### Best Practices

- 화면의 총 파티클 수 = `birthRate x lifetime`입니다. 이 값을 기준으로 성능을 예측하세요.
- 파티클 이미지는 작은 크기(32x32 이하)의 단순한 형태가 성능에 유리합니다.
- `alphaSpeed`를 음수로 설정하면 파티클이 자연스럽게 사라지는 효과를 얻습니다.
- 이펙트 종료 시 `birthRate = 0`으로 설정하면 기존 파티클은 수명이 다할 때까지 유지됩니다.
- `CAEmitterCell`의 `color`에 `UIColor.white`를 설정하고 `redRange/greenRange/blueRange`로 랜덤 색상을 만드세요.

### 주의 사항

- birthRate를 과도하게 높이면 GPU 부하와 메모리 사용량이 급증합니다. 구형 기기에서 반드시 테스트하세요.
- CAEmitterLayer는 Core Animation 레이어이므로, SwiftUI에서 직접 사용하려면 `UIViewRepresentable` 래퍼가 필요합니다.
- 파티클이 화면 밖으로 나가도 lifetime이 남아 있으면 GPU에서 계속 처리됩니다. 적절한 lifetime 설정이 중요합니다.
- `renderMode`가 `.additive`이면 파티클이 겹칠수록 밝아져 과포화될 수 있습니다.
