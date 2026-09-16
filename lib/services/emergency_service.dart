// lib/services/emergency_service.dart
//
// Triggers, acknowledges, and resolves SOS events. Writes to
// /emergencyEvents/{eventId} and dispatches an in-app emergency
// notification to the caller and to every Admin account.
//
// Admin UID discovery: this client cannot enumerate the /users tree for
// role='Admin' (the RTDB rules permit that read only to Admins themselves),
// and no Cloud Function is available in this project. To reach Admins we
// maintain a mirrored index at /adminIndex/{uid} = true, written by any
// Admin at login. Any authenticated user can read /adminIndex (its read
// rule allows auth != null), so the SOS sender can look up the current
// Admin set without needing elevated privileges.
//
// The index is kept in sync by main.dart (RoleResolutionShell).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_notification.dart';
import '../models/emergency_event.dart';
import 'notification_service.dart';

class EmergencyService {
  EmergencyService._();
  static final EmergencyService instance = EmergencyService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  // ─── Admin index ─────────────────────────────────────────────
  //
  // Reads /adminIndex (a flat uid→true map) maintained by Admin logins.
  // Returns an empty list on error rather than throwing — the caller is
  // usually in the middle of an emergency and must not be blocked.

  Future<List<String>> _fetchAdminUids() async {
    try {
      final snap = await _root.child('adminIndex').get();
      final raw = snap.value;
      if (raw is Map) {
        return raw.entries
            .where((e) => e.value == true)
            .map((e) => e.key.toString())
            .toList();
      }
    } catch (error) {
      debugPrint('EmergencyService: admin lookup failed: $error');
    }
    return const [];
  }

  /// Called by an Admin's app after role resolution to register its UID
  /// in the /adminIndex node. Safe to call repeatedly (idempotent).
  Future<void> registerAdminIndex(String uid) async {
    try {
      await _root.child('adminIndex/$uid').set(true);
    } catch (error) {
      debugPrint('EmergencyService: registerAdminIndex failed: $error');
    }
  }

  /// Removes a UID from the admin index (called on sign-out or role change).
  Future<void> unregisterAdminIndex(String uid) async {
    try {
      await _root.child('adminIndex/$uid').remove();
    } catch (error) {
      debugPrint('EmergencyService: unregisterAdminIndex failed: $error');
    }
  }

  // ─── Trigger SOS ─────────────────────────────────────────────

  /// Triggers an emergency. Returns the created event's ID.
  ///
  /// Order of operations (best-effort; each step is independently
  /// try/caught so a failure later does not block earlier steps):
  ///   1. Capture the current GPS fix (short timeout; may be null).
  ///   2. Write /emergencyEvents/{eventId}.
  ///   3. Send an in-app notification to the caller.
  ///   4. Fan out the same notification to every Admin UID.
  Future<String> triggerSOS({
    required String actorRole,
    required String alertType,
    String? description,
    String? busId,
    String? tripId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('SOS requires an authenticated user.');
    }

    // 1. GPS — best-effort, 4-second timeout.
    double? lat;
    double? lng;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (e) {
      debugPrint('EmergencyService: no GPS fix for SOS: $e');
    }

    // 2. Persist the event.
    final ref = _root.child('emergencyEvents').push();
    final eventId = ref.key;
    if (eventId == null) {
      throw StateError('Unable to allocate an emergency event ID.');
    }
    final event = EmergencyEvent(
      eventId: eventId,
      actorUid: uid,
      actorRole: actorRole,
      busId: busId,
      tripId: tripId,
      lat: lat,
      lng: lng,
      alertType: alertType,
      description: description,
      status: EmergencyStatus.active,
      timestamp: DateTime.now(),
    );

    try {
      await ref.set(event.toMap());
    } catch (error) {
      debugPrint('EmergencyService: event write failed: $error');
      // Continue — the notification is more urgent than the record.
    }

    // 3. Notify the caller.
    try {
      await NotificationService.instance.add(
        kind: NotificationKind.emergency,
        title: '🚨 SOS sent',
        message: '$alertType${busId != null ? ' • $busId' : ''}',
        busId: busId,
        metadata: {
          'emergencyEventId': eventId,
          'alertType': alertType,
          'lat': lat,
          'lng': lng,
        },
      );
    } catch (error) {
      debugPrint('EmergencyService: self-notify failed: $error');
    }

    // 4. Fan out to every Admin.
    final adminUids = await _fetchAdminUids();
    for (final adminUid in adminUids) {
      if (adminUid == uid) continue; // don't double-notify a self-Admin
      try {
        await NotificationService.instance.add(
          kind: NotificationKind.emergency,
          title: '🚨 SOS from ${actorRole.toLowerCase()}',
          message: '$alertType${busId != null ? ' on $busId' : ''}',
          busId: busId,
          targetUid: adminUid,
          metadata: {
            'emergencyEventId': eventId,
            'alertType': alertType,
            'actorUid': uid,
            'actorRole': actorRole,
            'lat': lat,
            'lng': lng,
          },
        );
      } catch (error) {
        debugPrint('EmergencyService: admin notify $adminUid failed: $error');
      }
    }

    if (kDebugMode) {
      debugPrint(
        'EmergencyService: SOS $eventId triggered by $uid '
        '(${adminUids.length} admins notified)',
      );
    }

    return eventId;
  }

  // ─── Admin: acknowledge / resolve ─────────────────────────────

  Future<void> acknowledge({
    required String eventId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _root.child('emergencyEvents/$eventId').update({
        'status': EmergencyStatus.acknowledged.name,
        'acknowledgedAt': DateTime.now().millisecondsSinceEpoch,
        'acknowledgedByUid': uid,
      });
    } catch (error) {
      debugPrint('EmergencyService: acknowledge failed: $error');
      rethrow;
    }
  }

  Future<void> resolve({
    required String eventId,
    required String resolutionNote,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _root.child('emergencyEvents/$eventId').update({
        'status': EmergencyStatus.resolved.name,
        'resolvedAt': DateTime.now().millisecondsSinceEpoch,
        'resolvedByUid': uid,
        'resolutionNote': resolutionNote.trim(),
      });
    } catch (error) {
      debugPrint('EmergencyService: resolve failed: $error');
      rethrow;
    }
  }

  // ─── Streams ─────────────────────────────────────────────────

  /// Streams every emergency event, newest first. Admin-only screen.
  Stream<List<EmergencyEvent>> streamAllEvents() {
    return _root.child('emergencyEvents').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <EmergencyEvent>[];
      final list = <EmergencyEvent>[];
      raw.forEach((key, value) {
        if (value is Map) {
          list.add(
            EmergencyEvent.fromMap(value, eventId: key.toString()),
          );
        }
      });
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  /// Streams the sender's own emergencies, newest first.
  Stream<List<EmergencyEvent>> streamMyEvents(String uid) {
    return streamAllEvents().map(
      (all) => all.where((e) => e.actorUid == uid).toList(),
    );
  }

  /// Cheap helper used by the Trip and Attendance screens to decide
  /// whether to show a "You have an active SOS" banner.
  Future<bool> hasActiveSOSForBus(String busId) async {
    try {
      final snap = await _root.child('emergencyEvents').get();
      final raw = snap.value;
      if (raw is! Map) return false;
      for (final entry in raw.entries) {
        final v = entry.value;
        if (v is! Map) continue;
        if (v['busId']?.toString() != busId) continue;
        final status = v['status']?.toString();
        if (status == EmergencyStatus.active.name ||
            status == EmergencyStatus.acknowledged.name) {
          return true;
        }
      }
    } catch (error) {
      debugPrint('EmergencyService: hasActiveSOSForBus failed: $error');
    }
    return false;
  }
}