// PLACEHOLDER — this file must be regenerated for your actual Firebase
// project before the app will connect to Realtime Database.
//
// Run this once from the project root (needs Firebase CLI + FlutterFire
// CLI installed, and you logged into the Google account that owns the
// Smart School Bus Firebase project):
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That command talks to your Firebase project and OVERWRITES this file
// with real apiKey/appId/projectId/databaseURL values for Android/iOS/web.
// Do not hand-edit those values in — always regenerate with the CLI.

import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) return android;
    if (Platform.isIOS) return ios;
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for this platform. '
      'Run `flutterfire configure` to generate real values.',
    );
  }

  // TODO: replaced automatically by `flutterfire configure`.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    databaseURL: 'REPLACE_ME',
  );

  // TODO: replaced automatically by `flutterfire configure`.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    iosBundleId: 'REPLACE_ME',
    databaseURL: 'REPLACE_ME',
  );
}
