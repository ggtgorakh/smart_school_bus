# Smart School Bus

Smart School Bus is a Flutter application for school-bus operations, live
vehicle tracking, student attendance, roster management, fleet administration,
and parent notifications.

The application supports Android, iOS, macOS, Windows, and web through Flutter.
Firebase Authentication and Realtime Database provide the identity, access
control, live telemetry, roster, fleet, and notification backends.

## Features

- Role-based navigation for Admin, Driver, Conductor, and Parent users.
- Live bus location and telemetry from the `/buses/{busId}` Realtime Database
  path.
- Fleet administration through `/busesFleet/{busId}`.
- Student rosters and attendance tracking for each bus.
- Excel roster import with preview and confirmation before data is committed.
- Parent-to-child lookup and parent notifications.
- Offline write queuing for supported writes.
- Light and dark themes with responsive desktop, tablet, and mobile layouts.

## User roles

User roles are stored as exact-case strings in `/users/{uid}/role`.

| Role | Main responsibilities |
| --- | --- |
| `Admin` | Manage users, rosters, buses, fleet records, and operational data |
| `Driver` | View assigned bus operations, update telemetry, and manage attendance |
| `Conductor` | View assigned bus operations and manage attendance |
| `Parent` | View linked children, bus progress, attendance, and notifications |

The `busId` field in a user profile assigns a Driver or Conductor to a bus.
The application currently uses the canonical fleet IDs `bus_01` through
`bus_10`.

Admins have a dedicated **People & Assignments** view from Fleet Overview and
Admin Profile. It keeps the limited operational directory (drivers, conductors,
and parents) separate from the large student roster, shows unassigned staff and
bus coverage, and allows Admins to update contact details and staff bus
assignments. Driver and conductor assignment metadata is stored on the related
`/busesFleet/{busId}` record.

## Technology

- Flutter and Dart
- Firebase Core
- Firebase Authentication
- Firebase Realtime Database
- `shared_preferences` for non-credential session preferences
- Excel and file-picker packages for roster import

## Project structure

```text
lib/
  main.dart                 Application entry point and authentication gate
  models/                   Firebase-facing domain models
  screens/                  Role-specific screens and navigation
  services/                 Firebase, authentication, session, roster, and notification services
  theme/                    Application theme and design tokens
database.rules.json         Realtime Database authorization and validation rules
firebase.json               Firebase CLI configuration
SETUP_AND_RUN.md            Installation, Firebase, and run instructions
test/                       Flutter tests
```

## Firebase data model

The main Realtime Database paths are:

- `/users/{uid}`: profile, exact-case role, contact details, and optional bus
  assignment. Profiles may also contain a `profileImage` base64 string for
  the user's optional profile photo; the client limits uploads to 1.5 MB.
- `/buses/{busId}`: live ESP32 GPS and telemetry data.
- `/busesFleet/{busId}`: administrative fleet metadata and status.
- `/studentRosters/{busId}/{studentId}`: student profiles and attendance.
- `/parentChildIndex/{parentUid}/{busId}/{studentId}`: parent-child lookup.
- `/notifications/{uid}/{notificationId}`: persisted user notifications.
- `/trips/{busId}/{tripId}`: software trip lifecycle records for scheduled,
  preparing, active, paused, completed, and cancelled trips.
- `/attendanceEvents/{busId}/{eventId}`: auditable attendance events linked to
  a student, bus, trip, actor, timestamp, and source.

`database.rules.json` is part of the application contract. Keep client
operations compatible with its role and bus-assignment checks. Do not replace
Firebase initialization with a mock in application code.

Current trip and attendance workflows are software-only. Live location
telemetry remains an external Firebase data source; the Flutter application
does not emulate GPS or depend on physical hardware for trip and attendance
state management.

## Quick start

From the repository root:

```text
flutter pub get
flutter run
```

Firebase must be configured and the target device or browser must be available.
For the complete setup, platform commands, Firebase configuration, and
troubleshooting guidance, see [SETUP_AND_RUN.md](SETUP_AND_RUN.md).

## Development commands

```text
flutter analyze
flutter test
flutter test test/widget_test.dart
flutter run
flutter build apk
flutter build web
flutter build windows
```

## Design guidance

The product visual language is documented in
[`securepath_mobility/DESIGN.md`](securepath_mobility/DESIGN.md). Use the
existing `AppTheme`, `AppColors`, and semantic safety-blue, orange, and green
color conventions when extending the UI.

## License and project status

This is a private application and is not configured for publication to pub.dev.
The package is marked with `publish_to: 'none'` in `pubspec.yaml`.
