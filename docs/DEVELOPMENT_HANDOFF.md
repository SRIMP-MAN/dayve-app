# DAYVE 개발 인수인계

2026-10-14 기준. 현재 소스 코드가 과거 기획 문서보다 우선합니다.

## 작업 경계

- 저장소: https://github.com/SRIMP-MAN/dayve-app
- 작업 경로: `C:\haru-app`
- 다른 앱의 저장소, 환경 파일, 서명 파일은 접근하거나 재사용하지 않습니다.
- 과거 `BOOTSTRAP_PROMPT_FOR_CODEX_WORK.md`는 초기 기획 기록입니다. 재생성 지시로 실행하지 마세요.

## 재현 환경

- 로컬 Flutter 3.47.1 stable / Dart 3.13.1 / Java 언어·바이트코드 타깃 17
- Android compileSdk / targetSdk 36, minSdk 24
- Gradle wrapper 9.3.1, Android Gradle Plugin 9.1.0, Kotlin plugin 2.4.0
- 버전 `pubspec.yaml`: 0.1.0+1
- Android applicationId / namespace: `com.dayve.app`
- iOS bundle identifier는 기존 `com.haruapp.haruApp` 유지
- CI는 기존 설정대로 Flutter stable과 Java 17 사용

`flutter doctor -v`로 Android SDK 및 Java 설치를 확인하고 Android SDK 라이선스에 동의합니다.
`android/local.properties`는 PC별 SDK 경로이므로 기존 PC 파일을 복사하지 않습니다.
Flutter 명령으로 생성되는 로컬 설정을 사용하세요. Windows에서 플러그인 symlink 오류가 나면
Windows 개발자 모드 설정을 확인하세요. Device Guard/Smart App Control 차단은 우회하지 않습니다.

## 이어서 작업하는 순서

1. README의 clone 명령 또는 `git pull --ff-only origin main`으로 최신화합니다.
2. `flutter pub get`으로 커밋된 lockfile 기준 의존성을 설치합니다. 불필요한 upgrade는 하지 않습니다.
3. `flutter analyze`, `flutter test`, `flutter build apk --debug`로 확인합니다.
4. Android 기기에서 위젯/알림/퇴근 액션/재부팅 복원을 확인합니다.
5. 변경 후 테스트하고 커밋·푸시합니다. 다른 PC에서 수정 전 반드시 pull합니다.

## 현재 기능과 의도적으로 제외한 부분

- Today / Consumption 탭, 우측 상단 설정 진입을 유지합니다.
- Hero는 `assets/day_backgrounds/`의 완성 이미지 4종을 사용합니다.
- Scene 레이어 합성 화면은 제거했습니다. `assets/day/`는 보관용이며 앱 asset 등록 대상이 아닙니다.
- 날씨는 `TimeOnlyWeatherService` 오프라인 구현입니다. 기상청 키/서버 연결은 필요 없습니다.
- 일일 권장 소비 금액 UI는 제거했습니다. BudgetEngine과 실제 지출 저장/월 예산은 유지합니다.
- 개발자 진단 코드는 남아 있지만 일반 설정의 진단 진입점은 제거했습니다.
- Android 위젯/잠금화면은 Flutter Snapshot을 표시합니다. Native에서 업무/예산 계산을 추가하지 마세요.
- Flutter 프로젝트명 `haru_app`, HARU 내부 클래스/저장 키는 호환성을 위해 유지합니다.

## 출시 서명: GitHub에 포함되지 않는 항목

- 실제 `android/key.properties`
- 실제 `dayve-upload-key.jks` 및 그 비밀번호
- `.env`, 개인 PC SDK 경로, 빌드 산출물

출시를 계속하려면 기존 upload keystore를 암호화된 저장소/안전한 오프라인 수단으로 별도 이전하세요.
비밀번호는 GitHub, 이 문서, 채팅, 로그에 기록하지 마세요. 키를 새로 만들거나 덮어쓰지 마세요.
`android/key.properties.example`는 양식일 뿐 실제 키와 alias를 포함하지 않습니다.
집 PC에서 실제 key.properties의 storeFile 경로를 실제 키 위치에 맞춥니다.
상대 storeFile 경로는 `android/app` 기준으로 해석됩니다.

```powershell
flutter build appbundle --release
```

결과: `build/app/outputs/bundle/release/app-release.aab`.
키 파일이 없으면 현재 설정에서 release signing config가 만들어지지 않으므로,
release 빌드 성공만으로 Play 업로드 가능한 서명을 보장하지 않습니다.
업로드 전 Gradle signingReport와 AAB 서명을 확인하고 기존 upload 인증서와 대조하세요.
Play Console용 아이콘: `release_assets/play_store_icon_512.png`.

## 데이터 및 실기기 주의

GitHub는 소스/에셋을 옮기며 기기 내부의 일정·지출·설정 데이터는 자동 이전하지 않습니다.
이전 Android ID `com.haruapp.haru_app` 앱과 `com.dayve.app`은 서로 다른 앱입니다.
새 패키지에 기존 앱 데이터/위젯이 자동 이전된다고 가정하지 마세요.
웹은 UI 확인용입니다. Android 위젯, 잠금화면, 알림 권한 거절, 절전·재부팅은 실기기 QA가 필요합니다.
시스템/OEM이 제어하는 Now Bar 노출은 보장하지 않습니다.
