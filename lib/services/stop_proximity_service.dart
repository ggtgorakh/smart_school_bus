// lib/services/stop_proximity_service.dart
//
// Watches the driver's own bus position against the current trip's
// route stops, and publishes `coming` / `reached` / `leaved` events
// to /attendanceEvents as the bus crosses proximity thresholds.
//
// Runs in the driver app only. Started by LocationService when a trip
// goes active. Stopped when the trip ends.

import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/attendance_event.dart';
import 'firebase_service.dart';

/// Per-stop proximity thresholds (metres).
class _Thresholds {
  /// Enter "coming" state within this distance of the stop.
  static const double comingMeters = 500;

  /// Enter "reached" within this distance AND below [reachedMaxSpeedKmh].
  static const double reachedMeters = 50;
  static const double reachedMaxSpeedKmh = 10;

  /// Enter "leaved" once past the stop by this distance AND moving.
  static const double leavedMeters = 200;
  static const double leavedMinSpeedKmh = 10;

  /// Hysteresis: minimum gap between two events for the same stop.
  static const Duration minTimeBetweenEvents = Duration(seconds: 20);
}

enum _StopPhase { none, coming, reached, leaved }

class _StopState {
  final String stopId;
  final String stopName;
  final double lat;
  final double lng;
  _StopPhase phase = _StopPhase.none;
  DateTime? lastEventAt;

  _StopState({
    required this.stopId,
    required this.stopName,
    required this.lat,
    required this.lng,
  });
}

class StopProximityService {
  StopProximityService._();
  static final StopProximityService instance = StopProximityService._();

  StreamSubscription<Position>? _positionSub;
  String? _busId;
  String? _tripId;
  final List<_StopState> _stops = [];
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<void> start({
    required String busId,
    required String tripId,
    required String routeId,
  }) async {
    if (_isRunning && _busId == busId && _tripId == tripId) return;
    if (_isRunning) await stop();

    _busId = busId;
    _tripId = tripId;

    try {
      final rawStops =
          await FirebaseService.instance.streamRouteStops(routeId).first;
      for (final s in rawStops) {
        final lat = (s['lat'] as num?)?.toDouble();
        final lng = (s['lng'] as num?)?.toDouble();
        final name = s['name']?.toString();
        final id = s['id']?.toString();
        if (lat == null || lng == null || name == null || id == null) {
          continue;
        }
        _stops.add(
          _StopState(stopId: id, stopName: name, lat: lat, lng: lng),
        );
      }
    } catch (e) {
      debugPrint('StopProximityService: failed to load stops: $e');
      return;
    }

    if (_stops.isEmpty) {
      debugPrint('StopProximityService: route has no stops, not starting.');
      return;
    }

    _isRunning = true;
    debugPrint(
      'StopProximityService: watching ${_stops.length} stops on '
      'trip $tripId for bus $busId.',
    );

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition, onError: (e) {
      debugPrint('StopProximityService: position error: $e');
    });
  }

  Future<void> stop() async {
    _isRunning = false;
    await _positionSub?.cancel();
    _positionSub = null;
    _busId = null;
    _tripId = null;
    _stops.clear();
  }

  Future<void> _onPosition(Position p) async {
    if (!_isRunning) return;
    final busId = _busId;
    final tripId = _tripId;
    if (busId == null || tripId == null) return;

    for (final stop in _stops) {
      final distance = _distanceMeters(
        p.latitude,
        p.longitude,
        stop.lat,
        stop.lng,
      );
      final speed = p.speed > 0 ? p.speed * 3.6 : 0.0;

      final last = stop.lastEventAt;
      if (last != null &&
          DateTime.now().difference(last) <
              _Thresholds.minTimeBetweenEvents) {
        continue;
      }

      switch (stop.phase) {
        case _StopPhase.none:
          if (distance < _Thresholds.comingMeters) {
            await _emit(stop, AttendanceEventStatus.coming);
            stop.phase = _StopPhase.coming;
            stop.lastEventAt = DateTime.now();
          }
          break;
        case _StopPhase.coming:
          if (distance < _Thresholds.reachedMeters &&
              speed < _Thresholds.reachedMaxSpeedKmh) {
            await _emit(stop, AttendanceEventStatus.reached);
            stop.phase = _StopPhase.reached;
            stop.lastEventAt = DateTime.now();
          } else if (distance > _Thresholds.comingMeters * 1.5) {
            stop.phase = _StopPhase.none;
          }
          break;
        case _StopPhase.reached:
          if (distance > _Thresholds.leavedMeters &&
              speed > _Thresholds.leavedMinSpeedKmh) {
            await _emit(stop, AttendanceEventStatus.leaved);
            stop.phase = _StopPhase.leaved;
            stop.lastEventAt = DateTime.now();
          }
          break;
        case _StopPhase.leaved:
          break;
      }
    }
  }

  Future<void> _emit(_StopState stop, AttendanceEventStatus status) async {
    final busId = _busId;
    final tripId = _tripId;
    final actorUid = FirebaseAuth.instance.currentUser?.uid;
    if (busId == null || tripId == null || actorUid == null) return;

    List<dynamic> students;
    try {
      students =
          await FirebaseService.instance.streamStudents(busId).first;
    } catch (e) {
      debugPrint('StopProximityService: student load failed: $e');
      return;
    }

    for (final s in students) {
      final stopName = s.stopName?.toString();
      if (stopName != stop.stopName) continue;
      try {
        await FirebaseService.instance.recordAttendanceEvent(
          studentId: s.id,
          busId: busId,
          tripId: tripId,
          status: status,
          source: 'auto',
        );
      } catch (e) {
        debugPrint(
          'StopProximityService: emit ${status.name} for ${s.id} failed: $e',
        );
      }
    }
  }

  double _distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * 3.1415926535897932 / 180.0;
}