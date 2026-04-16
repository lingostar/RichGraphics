---
layout: default
title: SceneKit / Metal 3D
---

[Home]({{ '/' | relative_url }}) > SceneKit / Metal 3D

# SceneKit / Metal 3D

SceneKit의 고수준 3D 렌더링 파이프라인과 Metal Shader Modifier를 결합하여 3D 시각화, 프로시저럴 지형, 커스텀 셰이더 이펙트를 구현합니다.

## 개요

**SceneKit**은 Apple의 고수준 3D 렌더링 프레임워크입니다. 씬 그래프(Scene Graph) 기반으로 3D 객체, 조명, 카메라, 애니메이션, 물리를 관리하며, 내부적으로 Metal(또는 OpenGL)을 사용하여 GPU 가속 렌더링을 수행합니다.

직접 Metal 코드를 작성하지 않고도 **SCN Shader Modifier**를 통해 셰이더 프로그래밍을 체험할 수 있어, 3D 그래픽스 입문에 매우 적합합니다. SwiftUI에서는 `SceneView`로 간편하게 통합됩니다.

### 언제 사용하나요?

- 3D 데이터 시각화 (지형, 분자 구조, 건축 모델 등)
- AR/VR 콘텐츠의 3D 씬 구성
- 간단한 3D 게임이나 인터랙티브 체험
- 커스텀 셰이더 이펙트 실험

## 핵심 API

### SCNScene & SCNNode

SceneKit의 모든 3D 객체는 `SCNNode` 트리 구조로 관리됩니다. 노드에 geometry, light, camera를 부착하여 씬을 구성합니다.

```swift
let scene = SCNScene()
// 구체 생성
let sphere = SCNNode(geometry: SCNSphere(radius: 1.0))
sphere.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
sphere.geometry?.firstMaterial?.lightingModel = .physicallyBased
sphere.position = SCNVector3(0, 0, 0)
scene.rootNode.addChildNode(sphere)
// 조명
let light = SCNNode()
light.light = SCNLight()
light.light?.type = .omni
light.light?.intensity = 1000
light.position = SCNVector3(5, 5, 5)
scene.rootNode.addChildNode(light)
```

### SCN Shader Modifier

SceneKit은 4개의 진입점(entry point)에서 Metal 셰이더 코드를 삽입할 수 있습니다.

```swift
// Geometry entry point: 정점 변형
let waveShader = """
float amplitude = 0.3;
float frequency = 2.0;
float offset = sin(_geometry.position.x * frequency
    + u_time * 3.0) * amplitude;
_geometry.position.y += offset;
"""
sphere.geometry?.shaderModifiers = [
    .geometry: waveShader
]
```

| Entry Point | 용도 |
|-------------|------|
| `.geometry` | 정점 위치/법선 변형 (물결, 변형 효과) |
| `.surface` | 표면 색상/텍스처 수정 |
| `.lightingModel` | 커스텀 조명 모델 |
| `.fragment` | 최종 픽셀 색상 후처리 |

### SceneView (SwiftUI)

`SceneView`는 SwiftUI에서 SceneKit 씬을 표시합니다. `allowsCameraControl`로 사용자 회전/줌을 활성화할 수 있습니다.

## 데모 목록

| # | 데모 | 설명 |
|---|------|------|
| 1 | **3D Primitives Gallery** | Box, Sphere, Cylinder, Torus 등 기본 geometry에 PBR(Physically Based Rendering) 재질을 적용하고, 조명 설정을 실험합니다. |
| 2 | **Procedural Terrain** | Perlin Noise 알고리즘으로 높이맵(height map)을 생성하고, Shader Modifier의 geometry entry point로 지형을 실시간 변형합니다. |
| 3 | **Shader Modifier Lab** | 4개의 shader entry point(.geometry, .surface, .lightingModel, .fragment)에 코드를 삽입하며 셰이더 프로그래밍의 기초를 실습합니다. |
| 4 | **Solar System** | SCNNode 계층 구조와 SCNAction을 활용하여 태양계 행성의 공전/자전 시뮬레이션을 구현합니다. 부모-자식 좌표계를 학습합니다. |
| 5 | **Model Viewer** | USDZ/OBJ 3D 모델을 로드하고, 카메라 제어, 환경 조명(IBL), 애니메이션 재생을 구현하는 모델 뷰어입니다. |

## 실전 팁

### Best Practices

- 대부분의 3D 시각화는 SceneKit으로 충분합니다. Raw Metal은 극한 성능이나 커스텀 렌더링 파이프라인이 필요할 때만 고려하세요.
- Shader Modifier는 Metal Shading Language(MSL) 문법을 사용하지만, 보일러플레이트 없이 핵심 로직만 작성하면 됩니다.
- `SCNMaterial.lightingModel = .physicallyBased`와 HDR 환경맵을 조합하면 사실적인 렌더링을 쉽게 얻을 수 있습니다.
- `u_time` uniform 변수를 활용하면 시간 기반 애니메이션 셰이더를 간단히 만들 수 있습니다.

### 주의 사항

- SceneKit의 물리 엔진은 SpriteKit에 비해 제한적입니다. 복잡한 물리가 필요하면 별도 물리 엔진을 고려하세요.
- Shader Modifier 디버깅은 어렵습니다. 단순한 코드부터 점진적으로 복잡도를 높이세요.
- 노드 수가 많아지면 draw call이 증가하여 성능이 저하됩니다. `flattenedClone()`으로 노드를 병합하세요.
- SceneView의 `allowsCameraControl`은 편리하지만 커스텀 카메라 조작이 필요하면 직접 구현해야 합니다.
