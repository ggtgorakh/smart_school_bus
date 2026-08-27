import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/bus_location.dart';
import '../models/student.dart';

/// Central wrapper around Firebase Realtime Database for live telemetry
/// and real-time student attendance manifests.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  /// Default student roster used to seed RTDB if empty
  static final List<Student> defaultStudentRoster = [
    Student(
      id: 'S1',
      name: 'Liam Johnson',
      grade: 'Grade 3',
      seat: 'Seat 4A',
      photoUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=150',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S2',
      name: 'Maya Patel',
      grade: 'Grade 4',
      seat: 'Seat 2B',
      photoUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S3',
      name: 'Ethan Williams',
      grade: 'Grade 5',
      seat: 'Seat 8C',
      photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S4',
      name: 'Sophia Garcia',
      grade: 'Grade 2',
      seat: 'Seat 1A',
      photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S5',
      name: 'Jackson Davis',
      grade: 'Grade 3',
      seat: 'Seat 5D',
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
  ];

  /// Streams live telemetry for [busId] from /buses/{busId}.
  Stream<BusLocation?> streamBusLocation(String busId) {
    return _root.child('buses/$busId').onValue.map<BusLocation?>((event) {
      final rawData = event.snapshot.value;
      if (rawData == null) {
        // Auto seed default location if missing
        seedDefaultBusLocation(busId);
        return _fallbackBusLocation(busId);
      }

      if (rawData is Map) {
        return BusLocation.fromMap(rawData);
      }
      return null;
    }).handleError((error) {
      assert(() {
        // ignore: avoid_print
        print('Firebase RTDB Stream Error ($busId): $error');
        return true;
      }());
    });
  }

  /// Default fallback telemetry object
  BusLocation _fallbackBusLocation(String busId) {
    return BusLocation(
      lat: 37.7749,
      lng: -122.4194,
      speedKmph: 35.0,
      status: BusRunStatus.onRoute,
      lastUpdated: DateTime.now(),
      currentStopIndex: 2,
      totalStops: 6,
      currentStopLabel: 'Oak St & Maple Ave',
      etaMinutes: 6,
      busNumber: busId == 'bus_01' ? 'Bus 42' : busId.toUpperCase(),
    );
  }

  /// Seeds default bus telemetry into RTDB if not yet created
  Future<void> seedDefaultBusLocation(String busId) async {
    try {
      final snap = await _root.child('buses/$busId/busNumber').get();
      if (!snap.exists) {
        await _root.child('buses/$busId').update(_fallbackBusLocation(busId).toMap());
      }
    } catch (_) {}
  }

  /// Streams real-time student attendance for a given bus route
  Stream<List<Student>> streamStudents(String busId) {
    return _root.child('buses/$busId/students').onValue.map<List<Student>>((event) {
      final raw = event.snapshot.value;
      if (raw == null) {
        // Automatically seed default students into RTDB
        seedStudents(busId, defaultStudentRoster);
        return defaultStudentRoster;
      }

      if (raw is Map) {
        final List<Student> list = [];
        raw.forEach((key, val) {
          if (val is Map) {
            list.add(Student.fromMap(val, id: key.toString()));
          }
        });
        // Sort by ID
        list.sort((a, b) => a.id.compareTo(b.id));
        return list;
      } else if (raw is List) {
        final List<Student> list = [];
        for (int i = 0; i < raw.length; i++) {
          final item = raw[i];
          if (item is Map) {
            list.add(Student.fromMap(item, id: item['id']?.toString() ?? 'S$i'));
          }
        }
        return list;
      }
      return defaultStudentRoster;
    }).handleError((_) {
      return defaultStudentRoster;
    });
  }

  /// Streams a single child's status for the Parent Boarding Status screen
  Stream<Student> streamStudent(String busId, String studentId) {
    return _root
        .child('buses/$busId/students/$studentId')
        .onValue
        .map<Student>((event) {
      final val = event.snapshot.value;
      if (val != null && val is Map) {
        return Student.fromMap(val, id: studentId);
      }
      return defaultStudentRoster.firstWhere(
        (s) => s.id == studentId,
        orElse: () => defaultStudentRoster[1], // Maya Patel (S2)
      );
    }).handleError((_) {
      return defaultStudentRoster.firstWhere(
        (s) => s.id == studentId,
        orElse: () => defaultStudentRoster[1],
      );
    });
  }

  /// Updates a student's boarding status in Realtime Database
  Future<void> updateStudentStatus(
    String busId,
    String studentId,
    StudentStatus status, {
    String? stopName,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final Map<String, dynamic> updates = {
      'status': status.name,
      'boardedAt': status == StudentStatus.boarded ? now : null,
    };
    if (stopName != null) {
      updates['stopName'] = stopName;
    }
    await _root.child('buses/$busId/students/$studentId').update(updates);
  }

  /// Marks all students on the bus with the given status
  Future<void> markAllStudentsStatus(String busId, StudentStatus status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final snapshot = await _root.child('buses/$busId/students').get();
    final data = snapshot.value;

    if (data is Map) {
      final Map<String, Object?> updates = {};
      data.forEach((key, _) {
        updates['$key/status'] = status.name;
        updates['$key/boardedAt'] = status == StudentStatus.boarded ? now : null;
      });
      await _root.child('buses/$busId/students').update(updates);
    } else {
      // Seed default list with the new status
      final updated = defaultStudentRoster.map((s) => s.copyWith(
        status: status,
        boardedAt: status == StudentStatus.boarded ? DateTime.now() : null,
      )).toList();
      await seedStudents(busId, updated);
    }
  }

  /// Seeds a list of students into RTDB
  Future<void> seedStudents(String busId, List<Student> students) async {
    try {
      final Map<String, dynamic> data = {};
      for (final s in students) {
        data[s.id] = s.toMap();
      }
      await _root.child('buses/$busId/students').set(data);
    } catch (_) {}
  }

  /// One-off read for manual refresh checks.
  Future<BusLocation?> fetchBusLocationOnce(String busId) async {
    try {
      final snapshot = await _root.child('buses/$busId').get();
      final rawData = snapshot.value;

      if (rawData != null && rawData is Map) {
        return BusLocation.fromMap(rawData);
      }
      return _fallbackBusLocation(busId);
    } catch (e) {
      return _fallbackBusLocation(busId);
    }
  }

  /// Writes driver or hardware telemetry updates to Firebase (ESP32 Simulator / Testing)
  Future<void> updateBusLocation(String busId, BusLocation location) async {
    await _root.child('buses/$busId').update(location.toMap());
  }
}