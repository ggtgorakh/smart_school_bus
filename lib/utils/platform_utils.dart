// lib/utils/platform_utils.dart

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Returns `true` when the current runtime is "laptop-class":
///
///   - Flutter web (any browser, any OS)
///   - Native Windows / macOS / Linux Flutter app
///
/// Returns `false` on native Android and iOS.
///
/// The rule is deliberately platform-based, not screen-width-based, so a
/// phone in landscape or a tablet in portrait cannot accidentally flip
/// category. If you later want tablets classified as laptops, adjust
/// this single function — every caller goes through it.
bool isLaptopPlatform() {
  if (kIsWeb) return true;
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return true;
  }
  return false;
}

/// Convenience inverse for the common case.
bool isMobilePlatform() => !isLaptopPlatform();