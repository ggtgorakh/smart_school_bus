// lib/services/student_absence_service.dart
//
// Parents can mark their child absent for a specific date. This is the
// single most requested feature in school-transport apps: it lets the
// driver skip a stop without waiting.
//
// Storage shape:
//   /studentAbsences/{busId}/{studentId}/{yyyy-mm-dd} = {
//     markedAt: epoch_ms,
//     markedByUid: <parent uid>,
//     reason: <optional string>,
//   }
//
// A day entry exists => the child is absent that day.
// A day entry is removed => the child is expected on the bus again.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class StudentAbsenceService {
  StudentAbsenceService._();
  static final StudentAbsenceService instance = StudentAbsenceService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Streams whether the given child is marked absent today.
  ///
  /// Emits `true` when a today-key entry exists, `false` otherwise.
  /// Parents see only their own children (enforced by RTDB rules).
  Stream<bool> streamAbsentToday({
    required String busId,
    required String studentId,
  }) {
    final key = _dateKey(DateTime.now());
    return _root
        .child('studentAbsences/$busId/$studentId/$key')
        .onValue
        .map((event) => event.snapshot.value != null);
  }

  /// Streams the full absent-day map for a student: `{yyyy-mm-dd: true}`.
  /// Useful for rendering a small calendar.
  Stream<Set<String>> streamAbsentDays({
    required String busId,
    required String studentId,
  }) {
    return _root
        .child('studentAbsences/$busId/$studentId')
        .onValue
        .map<Set<String>>((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <String>{};
      return raw.keys.map((k) => k.toString()).toSet();
    });
  }

  /// Marks the child absent for a specific date. Defaults to today.
  Future<void> markAbsent({
    required String busId,
    required String studentId,
    DateTime? date,
    String? reason,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Absence marking requires an authenticated user.');
    }
    final key = _dateKey(date ?? DateTime.now());
    final payload = <String, dynamic>{
      'markedAt': DateTime.now().millisecondsSinceEpoch,
      'markedByUid': uid,
      if (reason != null && reason.trim().isNotEmpty)
        'reason': reason.trim(),
    };
    try {
      await _root
          .child('studentAbsences/$busId/$studentId/$key')
          .set(payload);
    } catch (e) {
      debugPrint('StudentAbsenceService.markAbsent failed: $e');
      rethrow;
    }
  }

  /// Removes the "absent" mark for a date, so the child is expected back.
  Future<void> clearAbsence({
    required String busId,
    required String studentId,
    DateTime? date,
  }) async {
    final key = _dateKey(date ?? DateTime.now());
    try {
      await _root
          .child('studentAbsences/$busId/$studentId/$key')
          .remove();
    } catch (e) {
      debugPrint('StudentAbsenceService.clearAbsence failed: $e');
      rethrow;
    }
  }

  /// One-shot read used by the Driver's trip screen to know which stops
  /// can be skipped this morning.
  Future<Set<String>> fetchAbsentStudentIdsForBus(String busId) async {
    try {
      final key = _dateKey(DateTime.now());
      final snap = await _root.child('studentAbsences/$busId').get();
      final raw = snap.value;
      if (raw is! Map) return <String>{};
      final result = <String>{};
      raw.forEach((studentId, daysMap) {
        if (daysMap is Map && daysMap.containsKey(key)) {
          result.add(studentId.toString());
        }
      });
      return result;
    } catch (e) {
      debugPrint('StudentAbsenceService.fetchAbsentStudentIdsForBus: $e');
      return <String>{};
    }
  }
}