# DAYVE

오늘 내게 남은 **시간과 돈**을 앱을 열지 않고 확인하는 생활 계기판.

## v0.1
- Android first
- Flutter
- Local-only
- No backend / no Supabase / no login
- Home widget + notification centric UX

## Recommended local path

`C:\haru-app`

Do not create DAYVE under `C:\mukking-app`.

## 집 PC에서 이어서 개발

Git, Flutter SDK, Android Studio/Android SDK, JDK 17을 설치하세요.
현재 로컬 검증 환경은 Flutter **3.47.1 stable / Dart 3.13.1**이며 Android SDK Platform 36을 사용합니다.

```powershell
git clone https://github.com/SRIMP-MAN/dayve-app.git C:\haru-app
cd C:\haru-app
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

이미 복제한 PC라면 로컬 변경사항을 확인한 뒤 `git pull --ff-only origin main`을 사용하세요.
`flutter create`로 기존 프로젝트를 덮어쓰지 마세요.
웹 UI 미리보기: `flutter run -d chrome --web-port=8091`.
Android 실행: `flutter devices`로 기기를 확인한 뒤 `flutter run -d <device-id>`.

자세한 현재 기능, 환경, 출시 서명 이전 방법은 [개발 인수인계](docs/DEVELOPMENT_HANDOFF.md)를 읽어주세요.
서버, 로그인, 날씨 API 키 없이 실행할 수 있습니다.

## 서명 파일과 CI

`.env`, `android/key.properties`, keystore, 빌드 결과물은 GitHub에서 제외합니다.
디버그 실행에는 출시 키가 필요 없습니다. 집에서 출시 AAB를 만들려면 **기존 upload keystore와
비밀번호를 별도의 안전한 방법으로 옮겨야 합니다. 새 키로 대체하지 마세요.**

GitHub Actions는 push/PR마다 analyze → test → debug APK build를 수행하며,
성공한 APK는 `dayve-debug-apk` Artifact에서 받을 수 있습니다. 별도 secret은 필요 없습니다.

## Architecture

- `lib/domain/services/time_engine.dart`
- `lib/domain/services/budget_engine.dart`

UI must consume engine results rather than perform business calculations directly.
