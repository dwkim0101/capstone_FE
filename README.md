# SmartAir App

<p align="center">
  <img src="assets/logo.png" width="120" alt="SmartAir Logo"/>
</p>

스마트 공기질 관리와 기기 제어를 위한 Flutter 기반 모바일 앱입니다.
피그마 디자인을 충실히 반영한 세련된 UI와, 네이티브 Splash, 애니메이션, 하단바, 기기 카드 등 다양한 기능을 제공합니다.

---

## ✨ 주요 기능

- 실시간 공기 점수 시각화 (애니메이션 배경)
- 여러 집/공간 관리 및 전환
- 공기청정기 등 기기 카드 제어 (활성/비활성)
- 피그마 기반 하단 네비게이션 바 (SVG 아이콘)
- 네이티브 스플래시 화면 (flutter_native_splash)
- 반응형 레이아웃 및 다크 테마

---

## 📱 스크린샷

<p align="center">
  <img src="assets/screenshot_main.png" width="250"/>
</p>

---

## 🚀 설치 및 실행

```bash
# 패키지 설치
flutter pub get

# 네이티브 스플래시 적용
dart run flutter_native_splash:create

# 앱 실행
flutter run
```

---

## 🛠️ 기술스택

- Flutter 3.x
- Dart
- flutter_svg (SVG 아이콘)
- flutter_native_splash (네이티브 스플래시)

---

## 📂 폴더 구조

```
lib/
 ┣ main.dart
 ┣ screens/
 ┃   ┗ home_screen.dart
 ┣ widgets/
 ┃   ┗ smart_air_bottom_nav_bar.dart
 ┣ assets/
 ┃   ┣ Home.svg, device.svg, stats.svg, mypage.svg, logo.png, splash.png
```

---

## 🤝 기여 방법

1. 이슈/기능 제안 등록
2. Fork & PR
3. 커밋 메시지는 [gitmoji](https://gitmoji.dev/) 스타일 권장

---

## �� 라이선스

MIT License
