# VCloud — Employee Productivity MVP

Flutter + Supabase mobile app: **chat · attendance · timesheet · tickets · dashboard**.

## Stack
- Flutter 3.x, Dart 3.12+
- Supabase (auth · postgres · realtime · RLS)
- Riverpod for state, GoRouter for navigation

## Run locally

```bash
flutter pub get
flutter run \
  --dart-define=VCLOUD_SUPABASE_URL=https://ccjldpmsvzxudqjemtkw.supabase.co \
  --dart-define=VCLOUD_SUPABASE_ANON_KEY=sb_publishable_9Pxl6uZ5KAHSR21noY9G4A_MTZVSoWi
```

The defaults inside `lib/core/config/env.dart` fallback to those values so
a bare `flutter run` works in dev. **Always pass `--dart-define` for CI
and release builds** so the value doesn't get baked into the binary.

## Supabase bootstrap

1. Open the Supabase SQL editor for the project.
2. Paste the contents of `supabase/migrations/0001_init.sql` and run.
3. **Auth → Providers → Email**: disable "Confirm email" for MVP.
4. **Auth → URL Configuration**: add `vcloud://login-callback`.

## Folder layout

```
lib/
  core/      config · theme · router · utils · error
  shared/    models · widgets
  features/
    auth/{data,application,presentation}
    chat/{data,application,presentation}
    attendance/{data,application,presentation}
    timesheet/{data,application,presentation}
    ticket/{data,application,presentation}
    home/{application,presentation}
```

## Verification

```bash
flutter analyze
flutter test
flutter run
```
