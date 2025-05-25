# SmartAir App

<p align="center">
  <img src="assets/logo.png" width="120" alt="SmartAir Logo"/>
</p>

스마트 공기질 관리와 IoT 기기 제어를 위한 Flutter 기반 모바일 앱입니다.
2024년 최신 Swagger API 명세와 실시간 UX, 권한/보안, 다크모드 등
실서비스 수준의 구조와 일관성을 갖춘 프로젝트입니다.

---

## ✨ 주요 특징

- **Swagger 명세 기반 API 통신**: 모든 엔드포인트/파라미터를 최신 명세와 동기화
- **isRegistered 기반 기기 필터링**: 방에 등록된 기기만 노출, 미등록 기기는 UI/상태조회 제외
- **실시간 공기 점수 애니메이션**: 5초마다 자동 갱신, 숫자 변경 시 부드러운 애니메이션
- **권한/PAT 처리**: 403 발생 시 PAT 등록/권한 요청 UI 제공
- **다크모드 완벽 지원**: 모든 화면/다이얼로그/입력창/버튼 일관된 스타일
- **반응형 레이아웃**: 다양한 기기에서 최적화

---

## 🆕 2025 주요 변경점

- **API 구조 전면 리팩토링**: Swagger 명세와 100% 일치, 상수/함수 통합 관리
- **기기/방/센서/통계 화면 스크롤 및 레이아웃 개선**
- **실내/실외 공기질 비교 BarChart 시각화**
- **방 위도/경도 입력 및 모델 반영**
- **Room/Device 모델 일관성, Map → 객체화**
- **권한/PAT 처리 및 안내 다이얼로그**
- **다크모드 UI/UX 개선**
- **등록된 기기만 상태조회, 미등록 기기는 아예 제외**
- **점수 실시간 갱신 및 AnimatedSwitcher 적용**
- **로딩 중 '조회중 ...' 텍스트 안내**

---

## 🚀 설치 및 실행

```bash
# 패키지 설치
flutter pub get

# 네이티브 스플래시 적용
flutter pub run flutter_native_splash:create

# 앱 실행
flutter run
```

---

## 📂 폴더 구조 (2024)

```
lib/
 ┣ main.dart
 ┣ screens/
 ┃   ┣ home_tab.dart
 ┃   ┣ device_tab.dart
 ┃   ┣ stats_tab.dart
 ┃   ┣ ...
 ┣ models/
 ┃   ┗ device.dart, room.dart, sensor.dart
 ┣ utils/
 ┃   ┗ (API 관련 파일은 gitignore)
 ┣ widgets/
 ┃   ┗ smart_air_bottom_nav_bar.dart
assets/
 ┣ logo.png, Home.svg, device.svg, stats.svg, mypage.svg, splash.png
```

---

## 🤝 기여 방법

1. 이슈/기능 제안 등록
2. Fork & PR
3. 커밋 메시지는 [gitmoji](https://gitmoji.dev/) 스타일 권장

---

## 📝 라이선스

MIT License
