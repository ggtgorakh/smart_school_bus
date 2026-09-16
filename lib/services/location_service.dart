// lib/services/location_service.dart
//
// Driver location sharing, backed by geolocator's native foreground
// service on Android and iOS. Runs in the app's main isolate — the
// same isolate that owns the signed-in Firebase Auth user — so writes
// to /buses/{busId} succeed under the rules without any special
// authentication workaround.
//
// Previous versions of this file used flutter_background_service to
// run the GPS stream in a separate Dart isolate. That plugin no longer
// supports background isolates (see the runtime warning it prints), and
// the workaround — anonymous auth plus a relaxed RTDB rule — was worse
// than the problem. geolocator's built-in foreground service is the
// correct approach.
//
// As of Unit 4A, this file also starts and stops the StopProximityService
// alongside the position stream, so auto `coming` / `reached` / `leaved`
// events are emitted for the driver's assigned stops as the trip runs.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/bus_fleet.dart';
import 'firebase_service.dart';
import 'stop_proximity_service.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();
  factory LocationService() => instance;

  bool _isTracking = false;
  String? _currentBusId;
  StreamSubscription<Position>? _positionSub;

  bool get isTracking => _isTracking;
  String? get currentBusId => _currentBusId;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// No-op on the current architecture. Kept for source compatibility
  /// with main.dart, which still calls this at startup.
  Future<void> initialize() async {
    // Nothing to configure — geolocator is ready when it's ready.
  }

  /// Requests location and notification permissions. On Android, also
  /// asks for background location so the foreground service can
  /// continue when the app is minimized.
  Future<bool> requestPermissions() async {
    if (_isMobile) {
      final foreground = await Permission.location.request();
      if (foreground.isGranted) {
        try {
          await Permission.locationAlways.request();
        } catch (_) {}
      }
      try {
        await Permission.notification.request();
      } catch (_) {}
      return foreground.isGranted;
    } else {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    }
  }

  /// Starts sharing the phone's location for [busId].
  ///
  /// Guards:
  ///   1. There must be a signed-in Firebase user.
  ///   2. [busId] must be a registered fleet member.
  ///   3. The signed-in user must be the assigned driver of [busId].
  ///
  /// If any guard fails, tracking does not start and the method returns
  /// without throwing.
  Future<void> startTracking(String busId) async {
    if (_isTracking && _currentBusId == busId) return;

    // If tracking a different bus, stop the old one first.
    if (_isTracking && _currentBusId != null) {
      await stopTracking(busId: _currentBusId);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
        'LocationService.startTracking: refusing to start without a '
        'signed-in user (RTDB rules require a Driver session).',
      );
      return;
    }

    // Guard 1: bus must be a registered fleet member.
    final registered =
        await FirebaseService.instance.isBusRegisteredInFleet(busId);
    if (!registered) {
      debugPrint(
        'LocationService.startTracking: refused — "$busId" is not a '
        'registered fleet member. Refusing to create a ghost bus.',
      );
      return;
    }

    // Guard 2: the signed-in user must be the assigned driver of this bus.
    final assigned = await FirebaseService.instance
        .isDriverAssignedToBus(user.uid, busId);
    if (!assigned) {
      debugPrint(
        'LocationService.startTracking: refused — ${user.uid} is not '
        'the assigned driver of "$busId".',
      );
      return;
    }

    await requestPermissions();

    _currentBusId = busId;
    _isTracking = true;

    // Mirror the fleet status so the Admin's Fleet tab agrees with the
    // live map. Best-effort.
    try {
      await FirebaseService.instance
          .updateFleetStatus(busId, FleetStatus.onRoute);
    } catch (e) {
      debugPrint('LocationService: fleet status mirror failed: $e');
    }

    // Immediate fix so the parent map doesn't sit empty.
    try {
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      await _push(initial);
    } catch (e) {
      debugPrint('LocationService: initial fix unavailable: $e');
    }

    // Continuous stream. On Android, geolocator starts a foreground
    // service so the stream continues while the app is backgrounded.
    // On iOS, the UIBackgroundModes:[location] entry in Info.plist
    // allows the same behavior.
    final settings = _isMobile
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20,
            forceLocationManager: false,
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Trip in progress — sharing location',
              notificationText: 'Live school bus location is active',
              notificationChannelName: 'Bus tracking',
              notificationIcon:
                  AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
              enableWakeLock: true,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20,
          );

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) async {
        await _push(position);
      },
      onError: (e) {
        debugPrint('LocationService: position stream error: $e');
      },
    );

    // Start the auto-transition engine. It needs the driver's trip.
    try {
      final trip = await FirebaseService.instance
          .streamActiveTrip(busId)
          .first;
      if (trip != null && trip.routeId.isNotEmpty) {
        await StopProximityService.instance.start(
          busId: busId,
          tripId: trip.tripId,
          routeId: trip.routeId,
        );
      } else {
        debugPrint(
          'LocationService: no active trip for $busId — '
          'StopProximityService not started.',
        );
      }
    } catch (e) {
      debugPrint('LocationService: stop proximity start failed: $e');
    }
  }

  Future<void> _push(Position p) async {
    final busId = _currentBusId;
    if (busId == null || busId.isEmpty) return;
    try {
      await FirebaseService.instance.updateBusLocationCoordinates(
        busId: busId,
        lat: p.latitude,
        lng: p.longitude,
        speedKmph: p.speed > 0 ? p.speed * 3.6 : 0.0,
      );
    } catch (e) {
      debugPrint('LocationService: push failed: $e');
    }
  }

  /// Stops tracking, cancels the stream, and marks the bus offline.
  /// [busId] can be passed explicitly to ensure the correct bus is
  /// updated even if the in-memory state was lost (e.g. after an app
  /// restart mid-trip).
  Future<void> stopTracking({String? busId}) async {
    _isTracking = false;
    await _positionSub?.cancel();
    _positionSub = null;

    final targetBusId = busId ?? _currentBusId;
    _currentBusId = null;

    // Stop the auto-transition engine too.
    try {
      await StopProximityService.instance.stop();
    } catch (e) {
      debugPrint('LocationService: stop proximity stop failed: $e');
    }

    if (targetBusId != null && targetBusId.isNotEmpty) {
      try {
        await FirebaseService.instance.setBusOffline(targetBusId);
      } catch (e) {
        debugPrint('LocationService: setBusOffline failed: $e');
      }
      try {
        await FirebaseService.instance
            .updateFleetStatus(targetBusId, FleetStatus.idle);
      } catch (e) {
        debugPrint('LocationService: fleet status mirror failed: $e');
      }
    }
  }
}