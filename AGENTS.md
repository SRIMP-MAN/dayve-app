# HARU Project Scope

This repository is the HARU application.

## Safety boundary
Work only inside this repository.

Do NOT read, edit, move, delete, or modify files in:
- C:\mukking-app
- any Mukking repository, environment file, Supabase project, signing config, port config, or build output

Before modifying files, confirm the current working directory belongs to HARU.

## Product
HARU is a local-first Flutter app that shows:
- time remaining until work ends
- free time remaining after work
- sleep time available if the user sleeps now
- monthly discretionary budget remaining
- recommended spendable amount for today

The app should minimize foreground use. Prefer widgets, notifications, and quick actions.

## v0.1 constraints
- Flutter mobile app
- Android first
- No backend
- No authentication
- No Supabase
- No banking/card APIs
- No AI
- No social features
- Local-only storage
- Keep business logic outside UI
- Time calculations belong in TimeEngine
- Budget calculations belong in BudgetEngine
- Do not add dependencies without a clear need

## Naming
- Repository: haru-app
- Flutter project: haru_app
- Display name: 하루
- English brand: HARU
- Storage prefix: haru.v1.
- Notification channel prefix: haru_
- Deep link prefix reserved: haru://
