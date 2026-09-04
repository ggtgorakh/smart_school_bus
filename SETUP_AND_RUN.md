# Setup and Run Guide

This guide explains how to install, configure, start, test, and build Smart
School Bus locally.

## 1. Prerequisites

Install the following tools:

- Flutter SDK with Dart SDK compatibility for the version declared in
  `pubspec.yaml` (`^3.12.2`).
- Git.
- Android Studio and an Android emulator or physical Android device for Android
  development.
- Xcode and an iOS simulator or physical iOS device for iOS development on
  macOS.
- A supported desktop toolchain for Windows or macOS desktop builds.
- A modern browser for web development.
- Firebase CLI if you need to deploy or inspect Firebase resources.

Verify the Flutter installation:

```text
flutter doctor
flutter --version
```

Resolve any required items reported by `flutter doctor` before running the
application.

## 2. Get the source and dependencies

From the repository root:

```text
git clone <repository-url>
cd smart_school_bus
flutter pub get
```

If the repository is already available locally, only run:

```text
flutter pub get
```

## 3. Configure Firebase

The repository already contains generated Firebase configuration for the
configured project:

- `lib/firebase_options.dart` for Dart and Flutter platforms.
- `android/app/google-services.json` for Android.
- `firebase.json` for Firebase CLI configuration.
- `database.rules.json` for Realtime Database rules.

Before using the app with real data, confirm that the Firebase project has:

1. Email/password Authentication enabled, or another provider matching the
   login flow.
2. Realtime Database created in the intended region.
3. `database.rules.json` deployed when rules change.
4. User profiles created under `/users/{uid}` with an exact-case `role` value:
   `Admin`, `Driver`, `Conductor`, or `Parent`.
5. A `busId` assigned to each Driver and Conductor, such as `bus_01`.
6. Parent-child index records and student roster records created for Parent
   accounts.

Do not place service-account private keys in the Flutter application or commit
secrets to the repository. Client access is enforced by the Realtime Database
rules and Firebase Authentication.

To deploy the database rules with the Firebase CLI:

```text
firebase login
firebase use smart-school-bus-8e7d1
firebase deploy --only database
```

If you are setting up a different Firebase project, regenerate the Flutter
configuration with FlutterFire CLI instead of editing generated configuration
files manually:

```text
flutterfire configure
```

## 4. Select a target device

List available targets:

```text
flutter devices
```

Start an emulator or connect a device, then run the application:

```text
flutter run
```

To choose a specific target:

```text
flutter run -d <device-id>
```

Common examples:

```text
flutter run -d chrome
flutter run -d windows
flutter run -d android
```

The `android` device ID may differ on each machine. Use the value returned by
`flutter devices`.

## 5. Run and use the application

At startup, the app:

1. Initializes Firebase.
2. Restores the cached role and bus assignment when available.
3. Listens for Firebase Authentication state changes.
4. Shows the login screen for signed-out users.
5. Resolves the signed-in user's role and opens the matching navigation shell.

Use a Firebase Authentication account whose `/users/{uid}` profile has been
prepared in Realtime Database. The role is case-sensitive. A missing or
incorrect role can prevent the intended role-specific screens from loading.

## 6. Validate changes

Run static analysis and tests from the repository root:

```text
flutter analyze
flutter test
```

Run only the current widget smoke test:

```text
flutter test test/widget_test.dart
```

Run a named test:

```text
flutter test test/widget_test.dart --plain-name "LoginScreen smoke test"
```

## 7. Build release artifacts

Android APK:

```text
flutter build apk
```

Web:

```text
flutter build web
```

Windows:

```text
flutter build windows
```

Additional signing, store registration, and platform-specific release
configuration may be required before distributing an artifact.

## Troubleshooting

### Dependencies do not resolve

Run `flutter pub get`, verify the Flutter/Dart version with `flutter --version`,
and confirm that the SDK satisfies the constraint in `pubspec.yaml`.

### No device is available

Run `flutter doctor` and `flutter devices`. Start an emulator, connect a
physical device with development mode enabled, or use Chrome for a web run.

### Firebase initialization fails

Confirm that the selected platform is supported by
`lib/firebase_options.dart` and that the platform-specific configuration file
is present. Regenerate configuration with `flutterfire configure` if the
Firebase project changed.

### Login succeeds but the wrong screen opens

Check `/users/{uid}/role` in Realtime Database. The value must be exactly
`Admin`, `Driver`, `Conductor`, or `Parent`. For Driver and Conductor accounts,
also check that `busId` matches an existing fleet ID.

### Database reads or writes are denied

Confirm that the user is authenticated, the role and bus assignment are
correct, and the requested path is allowed by `database.rules.json`. Deploy
updated rules with `firebase deploy --only database` when appropriate.
