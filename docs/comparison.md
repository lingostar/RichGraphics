---
layout: default
title: Framework 비교
---

[Home]({{ '/' | relative_url }}) > Framework 비교

# Apple 그래픽 프레임워크 비교

학생 관점에서 각 프레임워크의 용도, 난이도, 장단점을 한눈에 비교합니다

## 한눈에 보는 비교표

| | SwiftUI Animation | CoreGraphics | SpriteKit | SceneKit | Metal | Core Image | CAEmitterLayer | UIKit Dynamics |
|---|---|---|---|---|---|---|---|---|
| **용도** | UI 모션/전환 | 2D 드로잉 | 2D 게임/물리 | 3D 시각화 | GPU 커스텀 | 이미지 처리 | 파티클 이펙트 | 물리 기반 UI |
| **차원** | 2D (3D 변환) | 2D | 2D | 3D | 2D/3D | 2D | 2D | 2D |
| **학습 난이도** | ★★☆☆☆ | ★★★☆☆ | ★★★☆☆ | ★★★★☆ | ★★★★★ | ★★★☆☆ | ★★☆☆☆ | ★★☆☆☆ |
| **SwiftUI 통합** | 네이티브 | Canvas | SpriteView | SceneView | Representable | 수동 변환 | Representable | Representable |
| **GPU 가속** | 자동 | 부분적 | 자동 | 자동 | 직접 제어 | 자동 | 자동 | CPU |
| **실시간 인터랙션** | 높음 | 보통 | 높음 | 높음 | 높음 | 보통 | 보통 | 높음 |
| **시뮬레이터 지원** | 완전 | 완전 | 완전 | 부분적 | 미지원 | 완전 | 완전 | 완전 |

## 프레임워크별 상세 비교

### SwiftUI Animation

#### Pros

- 선언적 문법 -- 코드가 짧고 직관적
- 별도 import 없이 SwiftUI에 내장
- iOS 17 KeyframeAnimator/PhaseAnimator로 복잡한 시퀀스도 가능
- matchedGeometryEffect로 히어로 트랜지션 구현이 매우 간편
- 자동 GPU 가속 및 60fps 최적화
- Xcode Preview에서 즉시 확인 가능

#### Cons

- 픽셀 단위의 정밀한 그래픽 제어 불가
- 물리 시뮬레이션이나 입자 시스템 없음
- iOS 17+ API가 많아 하위 호환성 이슈
- 복잡한 애니메이션은 State 관리가 어려움
- 커스텀 타이밍 커브 제한적

**이런 상황에 선택하세요:** 앱의 일반적인 UI 전환, 버튼/카드 애니메이션, 화면 간 트랜지션. 대부분의 앱에서 가장 먼저 시도해야 할 선택지.

---

### CoreGraphics (Quartz 2D)

#### Pros

- Apple 그래픽의 기반 -- 이해하면 다른 프레임워크 학습이 쉬워짐
- 완전한 2D 드로잉 제어 (경로, 곡선, 그래디언트, 변환)
- SwiftUI Canvas와 자연스럽게 통합
- PDF 생성, 이미지 합성 등 다양한 용도
- 오래된 API라 레퍼런스와 예제가 풍부

#### Cons

- C 스타일 API (CGContext)가 Swift에서 다소 부자연스러움
- 애니메이션을 직접 구현해야 함 (프레임 루프 필요)
- 복잡한 장면에서 CPU 바운드 성능 병목
- 좌표계가 수학적 (좌하단 원점) -- UIKit과 반대
- 터치 인터랙션을 직접 매핑해야 함

**이런 상황에 선택하세요:** 드로잉 앱, 차트/그래프 렌더링, 커스텀 UIView 그리기, PDF 생성. PencilKit이 제공하지 않는 세밀한 제어가 필요할 때.

---

### PencilKit

#### Pros

- Apple Pencil 필압/기울기 자동 지원
- 내장 툴 피커 (펜, 마커, 지우개, 눈금자)
- 줌/스크롤이 내장된 캔버스
- PKDrawing 직렬화로 저장/불러오기 간편
- 손글씨 인식 연동 가능

#### Cons

- 드로잉 결과물에 대한 커스터마이징 제한적
- 개별 스트로크 데이터 접근이 어려움
- UIKit 기반이라 UIViewRepresentable 필요
- 벡터 내보내기(SVG) 미지원
- 게임이나 실시간 그래픽에는 부적합

**이런 상황에 선택하세요:** 노트 앱, 서명 캡처, 스케치 기능이 필요한 앱. Apple Pencil을 최대한 활용하고 싶을 때.

---

### SpriteKit

#### Pros

- 완전한 2D 물리엔진 내장 (중력, 충돌, 관절, 필드)
- SpriteView로 SwiftUI 통합이 매우 쉬움
- SKAction 시스템으로 복잡한 시퀀스 간결하게 표현
- 텍스처 아틀라스, 파티클 에디터 등 Xcode 도구 지원
- 게임이 아닌 앱에서도 물리 인터랙션용으로 유용
- 시뮬레이터에서 완전히 동작

#### Cons

- UIKit/AppKit 좌표계 (좌하단 원점)
- SwiftUI의 State와 SpriteKit Scene 간 데이터 동기화가 까다로움
- 3D 불가 -- 3D가 필요하면 SceneKit으로 넘어가야 함
- 대규모 노드(1000+)에서 성능 저하
- Swift 6 strict concurrency와 충돌이 잦음

**이런 상황에 선택하세요:** 2D 게임, 물리 시뮬레이션, 인터랙티브 교육 콘텐츠. UIKit Dynamics보다 더 풍부한 물리 기능이 필요할 때.

---

### SceneKit

#### Pros

- 코드 몇 줄로 3D 장면 구성 가능 -- Metal보다 훨씬 진입장벽이 낮음
- 물리엔진, 파티클, 애니메이션 시스템 내장
- USDZ/DAE 모델 로딩 지원
- SceneView로 SwiftUI 통합
- Metal 셰이더 모디파이어로 커스텀 그래픽도 가능
- ARKit과 자연스럽게 연동

#### Cons

- Apple이 RealityKit에 집중하면서 업데이트 감소 추세
- 시뮬레이터에서 Metal 셰이더 미동작
- 대규모 장면에서 최적화 도구가 부족
- 커스텀 렌더링 파이프라인 불가 (Metal 직접 사용 필요)
- 셰이더 모디파이어 디버깅이 매우 어려움 (에러 메시지 부실)

**이런 상황에 선택하세요:** 3D 모델 뷰어, 제품 시각화, 간단한 3D 게임, AR 프로토타입. Raw Metal 없이 3D를 다루고 싶을 때.

---

### Metal

#### Pros

- GPU에 대한 완전한 제어 -- 최대 성능
- 커스텀 렌더링 파이프라인, 컴퓨트 셰이더
- Apple Silicon에서 최적화된 성능
- 머신러닝(MPS), 이미지 처리에도 활용
- 다른 프레임워크(SceneKit, Core Image)의 백엔드

#### Cons

- 학습 곡선이 매우 가파름 (GPU 아키텍처 이해 필요)
- 보일러플레이트 코드가 많음 (디바이스, 큐, 파이프라인, 디스크립터...)
- 시뮬레이터에서 동작하지 않음 -- 실기기 필수
- 디버깅이 어려움 (GPU 크래시는 정보가 제한적)
- 대부분의 앱에서는 과도한 선택 (SceneKit/Core Image로 충분)

**이런 상황에 선택하세요:** 고성능 게임 엔진, 커스텀 렌더러, GPU 컴퓨트, 이미지/비디오 처리 파이프라인. 다른 프레임워크로 원하는 성능이나 기능을 달성할 수 없을 때만.

---

### Core Image

#### Pros

- 200+ 빌트인 필터 즉시 사용 가능
- 필터 체이닝이 간편 (output -> input 연결)
- 자동 GPU 가속 + 지연 실행 최적화
- AVFoundation과 통합하여 실시간 카메라 필터 구현
- CIKernel으로 Metal 기반 커스텀 필터 작성 가능

#### Cons

- 실시간 렌더링에는 CIContext 재사용 등 최적화 필수
- 필터 파라미터가 문자열 키 기반 -- 타입 안전성 부족
- 결과물이 CIImage -> UIImage 변환 과정에서 성능 비용
- 인터랙티브 그래픽이나 게임에는 부적합
- 커스텀 CIKernel 작성 시 Metal + Core Image 둘 다 알아야 함

**이런 상황에 선택하세요:** 사진 편집 앱, 카메라 필터, 이미지 보정/합성. 기존 필터를 조합하는 것만으로도 대부분의 이미지 처리가 가능.

---

### CAEmitterLayer

#### Pros

- Core Animation 레벨이라 UIKit/SwiftUI 어디서든 사용 가능
- GPU 가속 파티클 렌더링으로 수천 개 파티클도 부드러움
- 설정 기반 -- 물리/수학 코드 없이 프로퍼티만 조절
- 이미터 안에 이미터를 넣어 복잡한 효과 구현 (불꽃놀이 등)
- 학습 비용 대비 시각적 임팩트가 큼

#### Cons

- 개별 파티클에 대한 제어 불가 (일괄 설정만)
- 파티클 간 충돌/상호작용 없음
- UIViewRepresentable 래핑 필요 (SwiftUI)
- 파라미터가 많아 원하는 효과를 만들기까지 시행착오 필요
- Xcode에 파티클 에디터 없음 (SpriteKit과 달리)

**이런 상황에 선택하세요:** 축하 이펙트, 날씨 효과, UI 장식, 배경 애니메이션. 파티클 간 상호작용이 필요 없는 시각적 효과.

---

### UIKit Dynamics

#### Pros

- 일반 UIView에 물리 법칙 적용 -- 게임 프레임워크 불필요
- 중력, 충돌, 스냅, 어태치먼트 등 직관적인 Behavior 조합
- 터치 제스처와 자연스럽게 연결됨
- UI 요소 그대로 사용 (버튼, 이미지, 커스텀 뷰)
- 학습 비용이 낮고 효과는 인상적

#### Cons

- UIKit 기반이라 SwiftUI에서는 UIViewRepresentable 필요
- 물리 정밀도가 SpriteKit보다 낮음
- 조인트/필드 같은 고급 물리 기능 없음
- 많은 아이템(100+)에서 성능 저하
- Apple의 업데이트가 사실상 중단됨

**이런 상황에 선택하세요:** 드래그 앤 드롭 UI, 탄성 메뉴, 카드 인터페이스, 물리 기반 스크롤. 게임이 아닌 앱에서 물리적 느낌을 추가하고 싶을 때.

---

## 선택 가이드 플로우차트

```
"그래픽을 추가하고 싶다"
    │
    ├─ UI 전환/모션? → SwiftUI Animation
    │
    ├─ 드로잉/페인팅?
    │   ├─ Apple Pencil 필요? → PencilKit
    │   └─ 커스텀 제어 필요? → CoreGraphics
    │
    ├─ 2D 게임/물리?
    │   ├─ 게임 수준? → SpriteKit
    │   └─ UI에 물리만? → UIKit Dynamics
    │
    ├─ 3D?
    │   ├─ 빠른 프로토타입? → SceneKit
    │   └─ 커스텀 렌더링? → Metal
    │
    ├─ 이미지 처리? → Core Image
    │
    └─ 파티클 이펙트? → CAEmitterLayer
```

## SpriteKit vs UIKit Dynamics: 언제 뭘 쓸까?

둘 다 "물리"를 다루지만 목적이 다릅니다.

| | SpriteKit | UIKit Dynamics |
|---|---|---|
| **대상** | 게임 오브젝트 (SKNode) | 일반 UI 요소 (UIView) |
| **좌표계** | 좌하단 원점 | 좌상단 원점 |
| **물리 기능** | 풍부 (조인트, 필드, 충돌 마스크) | 기본적 (중력, 충돌, 스냅) |
| **렌더링** | 별도 렌더 루프 (SKScene) | UIKit 레이아웃 시스템 |
| **적합한 곳** | 게임, 교육 시뮬레이션 | 드래그&드롭, 탄성 UI, 카드 |
| **SwiftUI** | SpriteView (쉬움) | UIViewRepresentable (수동) |

**판단 기준:** "내 물리 오브젝트가 UIView(버튼, 이미지 등)인가?" -> UIKit Dynamics. "별도 게임 화면인가?" -> SpriteKit.

## SceneKit vs Metal: 언제 뭘 쓸까?

| | SceneKit | Metal |
|---|---|---|
| **진입장벽** | 낮음 (몇 줄로 3D 장면) | 매우 높음 (GPU 파이프라인 이해 필요) |
| **커스터마이징** | 셰이더 모디파이어로 제한적 | 무한대 |
| **모델 로딩** | USDZ, DAE 내장 지원 | 직접 파서 작성 필요 |
| **디버깅** | Xcode Scene Editor | GPU Frame Debugger |
| **성능 상한** | 중간 | 최대 |
| **적합한 곳** | 제품 뷰어, 교육, AR | 게임 엔진, 과학 시각화, ML |

**판단 기준:** "SceneKit의 셰이더 모디파이어로 구현 가능한가?" -> SceneKit. "렌더링 파이프라인을 직접 제어해야 하는가?" -> Metal.
