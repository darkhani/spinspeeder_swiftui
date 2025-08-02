# Spin Speeder iOS

탁구공의 이동 속도와 회전 속도를 실시간으로 측정하는 iOS 앱입니다.

## 주요 기능

- 🏓 실시간 탁구공 검출 및 추적
- 📊 이동 속도 측정 (m/s)
- 🔄 회전 속도 측정 (rad/s)
- 📱 직관적인 SwiftUI 인터페이스
- 🎯 OpenCV4 기반 컴퓨터 비전 처리

## 기술 스택

- **SwiftUI**: 사용자 인터페이스
- **AVFoundation**: 카메라 스트리밍
- **OpenCV4**: 컴퓨터 비전 처리
- **CoreMotion**: 디바이스 모션 보정
- **CocoaPods**: 의존성 관리

## 설치 및 설정

### 1. 사전 요구사항

- Xcode 15.0 이상
- iOS 15.0 이상
- CocoaPods 설치

### 2. 프로젝트 설정

```bash
# 1. 프로젝트 클론
git clone <repository-url>
cd SpinSpeederIOS

# 2. CocoaPods 의존성 설치
pod install

# 3. .xcworkspace 파일로 프로젝트 열기
open SpinSpeederIOS.xcworkspace
```

### 3. Xcode 프로젝트 설정

1. **Bridging Header 설정**:
   - Build Settings → Objective-C Bridging Header
   - `SpinSpeederIOS/SpinSpeederIOS-Bridging-Header.h` 설정

2. **C++ 설정**:
   - Build Settings → Other Linker Flags
   - `-lc++` 추가

3. **권한 설정**:
   - Info.plist에 카메라 권한 추가:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>탁구공 추적을 위해 카메라 접근이 필요합니다.</string>
   ```

## 사용법

1. 앱을 실행하고 "탁구공 추적 시작" 버튼을 탭합니다.
2. 탁구공을 카메라 화면 중앙에 위치시킵니다.
3. 공을 움직이거나 회전시키면 실시간으로 측정됩니다.
4. 화면에 속도와 회전 속도가 표시됩니다.

## 아키텍처

```
SpinSpeederIOS/
├── SwiftUI Layer (ContentView, TrackingCameraView)
├── UIKit Layer (CameraViewController)
├── Objective-C++ Bridge (BallTrackerWrapper)
├── C++ Core (BallTracker)
└── OpenCV4 Framework
```

### 주요 컴포넌트

- **BallTracker.cpp/hpp**: 탁구공 검출 및 속도 계산 알고리즘
- **BallTrackerWrapper.mm/h**: Swift ↔ C++ 브릿지
- **CameraViewController.swift**: 카메라 스트리밍 및 UI 처리
- **ContentView.swift**: 메인 SwiftUI 인터페이스

## 알고리즘 설명

### 탁구공 검출
1. **색상 기반 마스킹**: HSV 색상 공간에서 주황색/흰색 범위 추출
2. **윤곽선 검출**: 연결된 컴포넌트 분석
3. **원형도 검사**: 원형 객체만 필터링
4. **크기 필터링**: 최소 크기 이상의 객체만 선택

### 속도 측정
- 프레임 간 위치 변화 분석
- `v = √(dx² + dy²) / Δt` 공식 사용
- 픽셀/초 단위로 계산 후 m/s로 변환

### 회전 속도 측정
- 공 표면의 패턴 변화 분석
- Optical Flow 알고리즘 적용
- 각속도(rad/s) 계산

## 성능 최적화

- **프레임 스킵**: 처리 속도 향상을 위해 일부 프레임 건너뛰기
- **ROI 처리**: 관심 영역만 처리하여 성능 향상
- **메모리 관리**: OpenCV Mat 객체 적절한 해제

## 문제 해결

### 일반적인 문제들

1. **탁구공이 검출되지 않는 경우**:
   - 조명 상태 확인
   - 배경이 단순한지 확인
   - 공이 화면 중앙에 있는지 확인

2. **속도 측정이 부정확한 경우**:
   - 카메라 흔들림 최소화
   - 충분한 조명 확보
   - 공의 움직임이 선명한지 확인

3. **앱이 크래시되는 경우**:
   - 카메라 권한 확인
   - OpenCV 프레임워크가 올바르게 링크되었는지 확인

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 연락처

프로젝트 링크: [https://github.com/yourusername/SpinSpeederIOS](https://github.com/yourusername/SpinSpeederIOS) 