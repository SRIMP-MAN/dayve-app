# DAYVE Project Scope

This repository is the DAYVE application. Read docs/DEVELOPMENT_HANDOFF.md before continuing work on a new computer.

## Safety boundary
Work only inside this repository.

Do NOT read, edit, move, delete, or modify files in:
- C:\mukking-app
- any Mukking repository, environment file, Supabase project, signing config, port config, or build output

Before modifying files, confirm the current working directory belongs to HARU.

## Product
DAYVE is a local-first Flutter app that shows:
- time remaining until work ends
- free time remaining after work
- sleep time available if the user sleeps now
- monthly discretionary budget remaining
- actual spending history (do not restore the removed daily spendable recommendation UI)

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
- Repository: SRIMP-MAN/dayve-app (local directory C:\haru-app)
- Flutter project: haru_app
- Display name: DAYVE
- English brand: DAYVE
- Android applicationId / namespace: com.dayve.app
- Keep existing HARU internal class names and storage keys unless a migration is explicitly requested.
- Storage prefix: haru.v1.
- Notification channel prefix: haru_
- Deep link prefix reserved: haru://
