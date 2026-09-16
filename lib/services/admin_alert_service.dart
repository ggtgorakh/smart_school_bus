// lib/services/admin_alert_service.dart
//
// Bulk messaging from the Admin to groups of users (all parents of a
// bus, all drivers, everyone). Each recipient gets an in-app notification
// via NotificationService. Nothing here uses FCM — this is the in-app
// version only.

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'notification_service.dart';

class AdminAlertService {
  AdminAlertService._();
  static final AdminAlertService instance = AdminAlertService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  /// Sends a broadcast to every user with the given role.
  ///
  /// Reads `/users` once (Admin-only per RTDB rules) to discover UIDs,
  /// then writes a per-recipient notification via NotificationService.
  /// Returns the number of recipients reached.
  Future<int> broadcastToRole({
    required String role,
    required String title,
    required String message,
  }) async {
    final uids = await _fetchUidsByRole(role);
    return _fanOut(uids, title: title, message: message);
  }

  /// Sends a broadcast to every parent whose child is on [busId].
  Future<int> broadcastToBusParents({
    required String busId,
    required String title,
    required String message,
  }) async {
    final uids = await _fetchParentUidsForBus(busId);
    return _fanOut(uids, title: title, message: message);
  }

  /// Sends a broadcast to every user in the system.
  Future<int> broadcastToEveryone({
    required String title,
    required String message,
  }) async {
    final uids = await _fetchAllUids();
    return _fanOut(uids, title: title, message: message);
  }

  // ─── Internals ─────────────────────────────────────────────

  Future<int> _fanOut(
    List<String> uids, {
    required String title,
    required String message,
  }) async {
    var delivered = 0;
    for (final uid in uids) {
      try {
        await NotificationService.instance.add(
          kind: NotificationKind.info,
          title: title,
          message: message,
          targetUid: uid,
          metadata: {'broadcast': true},
        );
        delivered++;
      } catch (e) {
        debugPrint('AdminAlertService: failed to notify $uid: $e');
      }
    }
    return delivered;
  }

  Future<List<String>> _fetchUidsByRole(String role) async {
    try {
      final snap = await _root.child('users').get();
      final raw = snap.value;
      if (raw is! Map) return [];
      final out = <String>[];
      raw.forEach((uid, value) {
        if (value is Map && value['role']?.toString() == role) {
          out.add(uid.toString());
        }
      });
      return out;
    } catch (e) {
      debugPrint('AdminAlertService._fetchUidsByRole: $e');
      return [];
    }
  }

  Future<List<String>> _fetchParentUidsForBus(String busId) async {
    try {
      final snap = await _root.child('studentRosters/$busId').get();
      final raw = snap.value;
      if (raw is! Map) return [];
      final parents = <String>{};
      raw.forEach((_, student) {
        if (student is Map) {
          final p = student['parentUid']?.toString();
          if (p != null && p.isNotEmpty) parents.add(p);
        }
      });
      return parents.toList();
    } catch (e) {
      debugPrint('AdminAlertService._fetchParentUidsForBus: $e');
      return [];
    }
  }

  Future<List<String>> _fetchAllUids() async {
    try {
      final snap = await _root.child('users').get();
      final raw = snap.value;
      if (raw is! Map) return [];
      return raw.keys.map((k) => k.toString()).toList();
    } catch (e) {
      debugPrint('AdminAlertService._fetchAllUids: $e');
      return [];
    }
  }
}