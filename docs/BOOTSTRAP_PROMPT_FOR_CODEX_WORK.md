# Codex Work bootstrap prompt

You are bootstrapping a brand-new Flutter app named HARU (display name: 하루).

Absolute safety rule:
- Work only inside C:\haru-app
- Never read or modify C:\mukking-app
- Do not reuse Mukking code, env files, Supabase, ports, signing, package IDs, or git config.

Tasks:
1. Confirm the current working directory is C:\haru-app.
2. If the Flutter project does not exist, create a new Flutter app with project name `haru_app`.
3. Use Android as the first target.
4. Keep v0.1 local-only: no backend, no auth, no Supabase.
5. Add FVM project pinning if FVM is available; do not upgrade the global Flutter SDK.
6. Apply the folder structure from AGENTS.md / starter pack.
7. Add only the dependencies needed for:
   - Riverpod state management
   - local key/value storage
   - date/time formatting and timezone support
   - local notifications
   - Android home widget bridge
8. Implement the provided domain models, TimeEngine, BudgetEngine, and tests.
9. Run:
   - flutter pub get
   - flutter analyze
   - flutter test
10. Do not implement widgets, notifications, or onboarding UI yet beyond minimal compile-safe placeholders.
11. Stop after the foundation builds cleanly and report:
   - Flutter version used
   - package/application ID
   - files created/changed
   - analyze result
   - test result
   - any issues or risks

Do not touch Mukking under any circumstance.
