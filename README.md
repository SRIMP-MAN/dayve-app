# 하루 (HARU)

오늘 내게 남은 **시간과 돈**을 앱을 열지 않고 확인하는 생활 계기판.

## v0.1
- Android first
- Flutter
- Local-only
- No backend / no Supabase / no login
- Home widget + notification centric UX

## Recommended local path

`C:\haru-app`

Do not create HARU under `C:\mukking-app`.

## Bootstrap

1. Create a clean Flutter project:
   `flutter create --org com.haruapp --project-name haru_app C:\haru-app`

2. Copy the contents of this starter pack into the new project.

3. Use a project-scoped Flutter SDK with FVM if available.

4. Run:
   `flutter pub get`
   `flutter analyze`
   `flutter test`

## Architecture

- `lib/domain/services/time_engine.dart`
- `lib/domain/services/budget_engine.dart`

UI must consume engine results rather than perform business calculations directly.
