// lib/services/device_class_guard.dart

import 'package:flutter/foundation.dart';

import '../utils/platform_utils.dart';

/// Thrown when a laptop-only action is attempted from a mobile device.
///
/// This is a **UX guard**, not a security boundary. Firebase rules remain
/// the source of truth for authorization. The guard exists so the app
/// refuses to do the wrong thing on the wrong device rather than silently
/// performing an edit a phone user can't easily review.
class LaptopOnlyActionException implements Exception {
  final String action;
  const LaptopOnlyActionException(this.action);

  @override
  String toString() =>
      'The action "$action" must be performed from the laptop version of '
      'the app. Please sign in on a laptop to continue.';
}

/// Wraps a laptop-only async action. On mobile, throws
/// [LaptopOnlyActionException] before running the inner function.
Future<T> requireLaptop<T>(
  String actionName,
  Future<T> Function() action,
) async {
  if (!isLaptopPlatform()) {
    throw LaptopOnlyActionException(actionName);
  }
  return action();
}

/// Synchronous variant.
T requireLaptopSync<T>(
  String actionName,
  T Function() action,
) {
  if (!isLaptopPlatform()) {
    throw LaptopOnlyActionException(actionName);
  }
  return action();
}

/// Non-throwing helper for UI gating. Returns `true` on laptop, `false`
/// on mobile. Use this to hide buttons and menu items.
bool isLaptopActionAllowed() {
  final allowed = isLaptopPlatform();
  if (!allowed && kDebugMode) {
    debugPrint(
      'DeviceClassGuard: laptop-only action blocked on mobile device.',
    );
  }
  return allowed;
}