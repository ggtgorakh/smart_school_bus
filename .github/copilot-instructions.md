# Copilot instructions for Smart School Bus

## Project overview

This is a Flutter application (`schoolbus_safe`) targeting Android, iOS, macOS, Windows, and web. The app is a role-based school-bus operations client:

- `lib/main.dart` initializes Firebase, restores cached session context, listens to Firebase Auth, resolves the signed-in user's role, and mounts the role-specific navigation shell.
- `lib/screens/` contains the UI. `MainNavigationShell` builds different tabs for exact role values `Admin`, `Driver`, `Conductor`, and `Parent` (the fallback role).
- `lib/services/` contains the application integration layer:
  - `AuthService` wraps Firebase Auth and user profiles.
  - `FirebaseService` is the singleton wrapper for Realtime Database telemetry, rosters, attendance, and fleet data.
  - `RosterImportService` parses and previews Excel rosters before committing parent accounts, student records, and fleet activation.
  - `NotificationService` persists and streams per-user notifications.
  - `SessionService` stores non-credential UI/session preferences with `shared_preferences`.
- `lib/models/` defines the Firebase-facing domain objects (`Student`, `BusLocation`, `BusFleet`) and enum/string conversion behavior.
- `lib/theme/app_theme.dart` owns light/dark `ThemeData`, semantic colors, gradients, typography, and the singleton `ThemeController`.
- `securepath_mobility/DESIGN.md` is the source for the product's visual language: safety blue/orange semantics, 8px spacing rhythm, rounded cards/status pills, and responsive desktop/tablet layouts.

## Build, test, and lint commands

Run commands from the repository root:

```text
flutter pub get
flutter analyze
flutter test
flutter test test/widget_test.dart
flutter test test/widget_test.dart --plain-name "LoginScreen smoke test"
flutter run
flutter build apk
flutter build web
flutter build windows
```

There is currently one widget smoke test in `test/widget_test.dart`; use the file path and `--plain-name` selector above for focused runs. `analysis_options.yaml` applies `flutter_lints` and excludes generated/platform directories from Dart analysis.

Firebase must be initialized before the app is run. `lib/firebase_options.dart` contains the generated per-platform options, and `firebase.json` points Realtime Database deployment at `database.rules.json`. Do not replace Firebase initialization with a mock in application code; inject or isolate dependencies only when adding test seams.

## Firebase data model and boundaries

Use the existing canonical paths and preserve the distinction between hardware telemetry and admin fleet metadata:

- `/users/{uid}`: profile, exact-case `role`, optional `busId`, contact fields.
- `/buses/{busId}`: live ESP32 GPS/telemetry (`BusLocation`); this is the hardware pipeline and must not be used for fleet status administration.
- `/busesFleet/{busId}`: admin fleet records (`BusFleet`), normally `bus_01` through `bus_10`.
- `/studentRosters/{busId}/{studentId}`: student profile and attendance state.
- `/parentChildIndex/{parentUid}/{busId}/{studentId}`: parent-to-child lookup used by parent streams.
- `/notifications/{uid}/{notificationId}`: persisted user notifications.

`database.rules.json` is part of the feature contract. Keep client reads/writes compatible with its role and bus-assignment checks; changes to access behavior require updating the rules deliberately, not bypassing them in Dart.

## Repository-specific conventions

- Prefer the existing singleton services (`AuthService.instance`, `FirebaseService.instance`, `SessionService.instance`, `NotificationService.instance`) instead of creating ad-hoc Firebase references in screens. Direct RTDB access in screens exists for a few admin/profile flows; extend the service layer when adding reusable data operations.
- Treat Firebase streams as the source of truth for live data. Screens commonly use `StreamBuilder`, maintain subscriptions in `State`, and must cancel subscriptions and animation controllers in `dispose`.
- Check `mounted` before updating state after an `await`. Preserve loading/error/empty states; an absent roster or telemetry record is represented as empty/null, not fabricated demo data.
- Keep Firebase serialization compatible with the models: enum values are stored as strings (`StudentStatus` names, `FleetStatus` names, and `BusRunStatus` wire values), timestamps are generally epoch milliseconds, and RTDB keys may be passed separately to `fromMap`.
- Preserve attendance state when updating an existing roster student. The two-phase roster workflow is intentional: parse/validate/preview first, then commit only after admin confirmation. Parent emails are normalized to trimmed lowercase and siblings share one parent account.
- Keep fleet operations bounded to the ten canonical IDs and use partial `update()` calls for status changes so unrelated telemetry/fuel/route fields are not clobbered. `ensureTenBusesExist()` is safe to call repeatedly and must not overwrite existing fleet records.
- Role comparisons are exact strings matching the values stored in `/users/{uid}/role`. If adding a role, update role resolution and the authorized tab construction together.
- Use `AppTheme`, `AppColors`, and the active `Theme.of(context)` rather than hard-coded one-off colors. Follow the design spec's safety-blue primary, orange alert, green success semantics, rounded surfaces, and responsive desktop sidebar/content constraints.
- Keep UI state local to the relevant `StatefulWidget` unless it is cross-screen session/theme state, in which case use the existing service/controller. Preserve tab state behavior in the `IndexedStack` and its `TickerMode` optimization.
- Use `try`/`catch` patterns consistent with the service being changed: log with the service prefix, rethrow when callers must handle a failed write, and do not silently turn failed writes into successful-looking UI state.
- Keep generated and platform-owned files out of ordinary Dart feature edits. Relevant generated Firebase/platform files should only change through the appropriate Flutter/Firebase tooling.

