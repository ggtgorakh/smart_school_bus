// lib/services/firebase_service.dart

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/bus_fleet.dart';
import '../models/bus_location.dart';
import '../models/student.dart';
import 'offline_write_queue.dart';

/// Central wrapper around Firebase Realtime Database for live telemetry
/// and real-time student attendance manifests.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();
  final OfflineWriteQueue _writeQueue = OfflineWriteQueue.instance;

  bool _shouldQueueWrite(Object error) {
    if (error is! FirebaseException) return true;
    return error.code == 'network-error' ||
        error.code == 'disconnected' ||
        error.code == 'unavailable' ||
        error.code == 'timeout';
  }

  /// Streams the administrator's route plan from Realtime Database.
  Stream<List<Map<String, dynamic>>> streamRouteStops(String routeId) {
    return _root.child('routes/$routeId/stops').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <Map<String, dynamic>>[];
      final stops = <Map<String, dynamic>>[];
      raw.forEach((key, value) {
        if (value is Map) {
          stops.add({
            'id': key.toString(),
            ...Map<String, dynamic>.from(value),
          });
        }
      });
      stops.sort(
        (a, b) => (a['order'] as num? ?? 0).compareTo(b['order'] as num? ?? 0),
      );
      return stops;
    });
  }

  Future<void> saveRouteStop(
    String routeId,
    String stopId,
    Map<String, dynamic> stop,
  ) async {
    final path = 'routes/$routeId/stops/$stopId';
    try {
      await _root.child(path).set(stop);
    } catch (error) {
      if (_shouldQueueWrite(error)) {
        await _writeQueue.enqueue(
          path: path,
          operation: OfflineWriteOperation.set,
          value: stop,
        );
      }
      rethrow;
    }
  }

  Future<void> removeRouteStop(String routeId, String stopId) async {
    final path = 'routes/$routeId/stops/$stopId';
    try {
      await _root.child(path).remove();
    } catch (error) {
      if (_shouldQueueWrite(error)) {
        await _writeQueue.enqueue(
          path: path,
          operation: OfflineWriteOperation.remove,
        );
      }
      rethrow;
    }
  }

  /// Streams live telemetry for [busId] from /buses/{busId}.
  Stream<BusLocation?> streamBusLocation(String busId) {
    return _root.child('buses/$busId').onValue.map<BusLocation?>((event) {
      final rawData = event.snapshot.value;
      if (rawData == null) {
        return null;
      }
      if (rawData is Map) {
        return BusLocation.fromMap(rawData);
      }
      return null;
    }).asBroadcastStream();
  }

  /// Streams real-time student attendance for a given bus route.
  Stream<List<Student>> streamStudents(String busId) {
    return _root.child('studentRosters/$busId').onValue.map<List<Student>>((
      event,
    ) {
      final raw = event.snapshot.value;
      if (raw == null) {
        // No roster imported yet for this bus — return an honest empty
        // list instead of silently seeding fake demo students.
        return <Student>[];
      }
      if (raw is Map) {
        final List<Student> list = [];
        raw.forEach((key, val) {
          if (val is Map) {
            list.add(Student.fromMap(val, id: key.toString()));
          }
        });
        list.sort((a, b) => a.id.compareTo(b.id));
        return list;
      } else if (raw is List) {
        final List<Student> list = [];
        for (int i = 0; i < raw.length; i++) {
          final item = raw[i];
          if (item is Map) {
            list.add(
              Student.fromMap(item, id: item['id']?.toString() ?? 'S$i'),
            );
          }
        }
        return list;
      }
      return <Student>[];
    });
  }

  /// Streams a single child's status for the Parent Boarding Status screen.
  /// Emits null when the student doesn't exist (yet) instead of falling
  /// back to fake demo data.
  Stream<Student?> streamStudent(String busId, String studentId) {
    return _root
        .child('studentRosters/$busId/$studentId')
        .onValue
        .map<Student?>((event) {
          final val = event.snapshot.value;
          if (val != null && val is Map) {
            return Student.fromMap(val, id: studentId);
          }
          return null;
        });
  }

  /// Streams every child currently linked to [parentUid].
  Stream<List<Student>> streamChildrenForParent(String parentUid) {
    late StreamController<List<Student>> controller;
    StreamSubscription<DatabaseEvent>? indexSub;
    final Map<String, StreamSubscription<DatabaseEvent>> childSubs = {};
    final Map<String, Student> latest = {};

    void emit() {
      final list = latest.values.toList()..sort((a, b) => a.id.compareTo(b.id));
      if (!controller.isClosed) controller.add(list);
    }

    void subscribeToChild(String busId, String studentId) {
      childSubs[studentId]?.cancel();
      childSubs[studentId] = _root
          .child('studentRosters/$busId/$studentId')
          .onValue
          .listen(
            (event) {
              final val = event.snapshot.value;
              if (val is Map) {
                latest[studentId] = Student.fromMap(val, id: studentId);
              } else {
                latest.remove(studentId);
              }
              emit();
            },
            onError: (_) {
              latest.remove(studentId);
              emit();
            },
          );
    }

    void handleIndexUpdate(dynamic raw) {
      final currentIds = <String>{};
      if (raw is Map) {
        raw.forEach((busId, studentsOnBus) {
          if (studentsOnBus is Map) {
            studentsOnBus.forEach((studentId, linked) {
              if (linked == true) {
                currentIds.add(studentId.toString());
                subscribeToChild(busId.toString(), studentId.toString());
              }
            });
          }
        });
      }

      final removedIds = childSubs.keys
          .where((id) => !currentIds.contains(id))
          .toList();
      for (final id in removedIds) {
        childSubs.remove(id)?.cancel();
        latest.remove(id);
      }
      emit();
    }

    controller = StreamController<List<Student>>.broadcast(
      onListen: () {
        indexSub = _root
            .child('parentChildIndex/$parentUid')
            .onValue
            .listen(
              (event) => handleIndexUpdate(event.snapshot.value),
              onError: (_) => emit(),
            );
      },
      onCancel: () {
        indexSub?.cancel();
        for (final sub in childSubs.values) {
          sub.cancel();
        }
        childSubs.clear();
      },
    );

    return controller.stream;
  }

  /// Updates a student's boarding status.
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
    final path = 'studentRosters/$busId/$studentId';
    try {
      await _root.child(path).update(updates);
    } catch (error) {
      if (_shouldQueueWrite(error)) {
        await _writeQueue.enqueue(
          path: path,
          operation: OfflineWriteOperation.update,
          value: updates,
        );
      }
      print('FirebaseService: Error updating student status: $error');
      rethrow;
    }
  }

  /// Marks all students on the bus with the given status.
  Future<void> markAllStudentsStatus(String busId, StudentStatus status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final snapshot = await _root.child('studentRosters/$busId').get();
    final data = snapshot.value;

    if (data is Map) {
      final Map<String, Object?> updates = {};
      data.forEach((key, _) {
        updates['$key/status'] = status.name;
        updates['$key/boardedAt'] = status == StudentStatus.boarded
            ? now
            : null;
      });
      final path = 'studentRosters/$busId';
      try {
        await _root.child(path).update(updates);
      } catch (error) {
        if (_shouldQueueWrite(error)) {
          await _writeQueue.enqueue(
            path: path,
            operation: OfflineWriteOperation.update,
            value: updates,
          );
        }
        print('FirebaseService: Error marking all student statuses: $error');
        rethrow;
      }
    } else {
      // No roster exists for this bus yet — nothing to mark, so no-op
      // instead of seeding fake demo students.
      print(
        'FirebaseService: markAllStudentsStatus skipped — no roster for $busId',
      );
    }
  }

  /// Seeds a list of students into RTDB.
  Future<void> seedStudents(String busId, List<Student> students) async {
    try {
      final Map<String, dynamic> data = {};
      for (final s in students) {
        data[s.id] = s.toMap();
      }
      await _root.child('studentRosters/$busId').set(data);
    } catch (error) {
      print('FirebaseService: Error seeding students: $error');
    }
  }

  /// Creates or updates a single student record.
  Future<void> upsertStudent({
    required String busId,
    required Student student,
  }) async {
    try {
      await _root
          .child('studentRosters/$busId/${student.id}')
          .set(student.toMap());

      if (student.parentUid != null && student.parentUid!.trim().isNotEmpty) {
        await _root
            .child('parentChildIndex/${student.parentUid}/$busId/${student.id}')
            .set(true);
      }
    } catch (error) {
      print('FirebaseService: Error upserting student: $error');
      rethrow;
    }
  }

  /// Removes a child's link to a Parent account.
  Future<void> unlinkChildFromParent({
    required String parentUid,
    required String busId,
    required String studentId,
  }) async {
    try {
      await _root
          .child('parentChildIndex/$parentUid/$busId/$studentId')
          .remove();
    } catch (error) {
      print('FirebaseService: Error unlinking child: $error');
      rethrow;
    }
  }

  /// One-off read for manual refresh checks.
  Future<BusLocation?> fetchBusLocationOnce(String busId) async {
    try {
      final snapshot = await _root.child('buses/$busId').get();
      final rawData = snapshot.value;
      if (rawData != null && rawData is Map) {
        return BusLocation.fromMap(rawData);
      }
      return null;
    } catch (error) {
      print('FirebaseService: Error fetching bus location: $error');
      return null;
    }
  }

  /// Writes driver or hardware telemetry updates to Firebase.
  Future<void> updateBusLocation(String busId, BusLocation location) async {
    try {
      await _root.child('buses/$busId').update(location.toMap());
    } catch (error) {
      print('FirebaseService: Error updating bus location: $error');
      rethrow;
    }
  }

  // ============================================================
  // ADDITIONAL UTILITY METHODS
  // ============================================================

  /// Check if a bus exists in the database.
  Future<bool> busExists(String busId) async {
    try {
      final snapshot = await _root.child('buses/$busId').get();
      return snapshot.exists;
    } catch (error) {
      print('FirebaseService: Error checking bus exists: $error');
      return false;
    }
  }

  /// Get all bus IDs.
  Future<List<String>> getAllBusIds() async {
    try {
      final snapshot = await _root.child('buses').get();
      final data = snapshot.value;
      if (data is Map) {
        return data.keys.map((key) => key.toString()).toList();
      }
      return [];
    } catch (error) {
      print('FirebaseService: Error getting bus IDs: $error');
      return [];
    }
  }

  /// Get student by ID across all buses.
  Future<Student?> findStudentById(String studentId) async {
    try {
      final snapshot = await _root.child('studentRosters').get();
      final data = snapshot.value;
      if (data is Map) {
        for (final busEntry in data.entries) {
          final busData = busEntry.value as Map?;
          if (busData != null && busData.containsKey(studentId)) {
            final studentData = busData[studentId] as Map?;
            if (studentData != null) {
              return Student.fromMap(
                studentData,
                id: studentId,
                busId: busEntry.key.toString(),
              );
            }
          }
        }
      }
      return null;
    } catch (error) {
      print('FirebaseService: Error finding student: $error');
      return null;
    }
  }

  /// Get all students across all buses (Admin only).
  Future<List<Student>> getAllStudents() async {
    try {
      final List<Student> allStudents = [];
      final snapshot = await _root.child('studentRosters').get();
      final data = snapshot.value;
      if (data is Map) {
        for (final busEntry in data.entries) {
          final busId = busEntry.key.toString();
          final busData = busEntry.value as Map?;
          if (busData != null) {
            for (final studentEntry in busData.entries) {
              final studentData = studentEntry.value as Map?;
              if (studentData != null) {
                allStudents.add(
                  Student.fromMap(
                    studentData,
                    id: studentEntry.key.toString(),
                    busId: busId,
                  ),
                );
              }
            }
          }
        }
      }
      allStudents.sort((a, b) => a.name.compareTo(b.name));
      return allStudents;
    } catch (error) {
      print('FirebaseService: Error getting all students: $error');
      return [];
    }
  }

  // ============================================================
  // FLEET MANAGEMENT (10 physical buses, /busesFleet/{busId})
  //
  // Kept separate from /buses/{busId}, which is owned by the ESP32
  // hardware telemetry pipeline and must never be written to from here.
  // ============================================================

  static const int totalFleetSize = 10;

  String _padBusId(int n) => 'bus_${n.toString().padLeft(2, '0')}';

  /// Ensures exactly bus_01..bus_10 exist under /busesFleet, creating any
  /// missing ones with status idle and placeholder driver/route info.
  /// Safe to call repeatedly — it never overwrites a bus that already
  /// exists, so it will not clobber a real, already-imported roster's
  /// on-route status.
  Future<void> ensureTenBusesExist() async {
    try {
      final snapshot = await _root.child('busesFleet').get();
      final existing = snapshot.value;
      final existingIds = <String>{};
      if (existing is Map) {
        existingIds.addAll(existing.keys.map((k) => k.toString()));
      }

      final Map<String, dynamic> missing = {};
      for (int i = 1; i <= totalFleetSize; i++) {
        final id = _padBusId(i);
        if (!existingIds.contains(id)) {
          missing[id] = BusFleet(
            busId: id,
            driverName: 'Unassigned',
            routeName: 'No route assigned',
            estArrival: '--',
            status: FleetStatus.idle,
            speedMph: 0,
            fuelPercent: 100,
          ).toMap();
        }
      }

      if (missing.isNotEmpty) {
        await _root.child('busesFleet').update(missing);
      }
    } catch (error) {
      print('FirebaseService: Error ensuring fleet exists: $error');
    }
  }

  /// Streams all 10 buses from /busesFleet, sorted by busId (bus_01 first).
  Stream<List<BusFleet>> streamFleet() {
    return _root
        .child('busesFleet')
        .onValue
        .map<List<BusFleet>>((event) {
          final raw = event.snapshot.value;
          if (raw is! Map) return <BusFleet>[];
          final List<BusFleet> list = [];
          raw.forEach((key, val) {
            if (val is Map) {
              list.add(BusFleet.fromMap(val, busId: key.toString()));
            }
          });
          list.sort((a, b) => a.busId.compareTo(b.busId));
          return list;
        })
        .handleError((error) {
          print('FirebaseService: Error streaming fleet: $error');
          return <BusFleet>[];
        });
  }

  /// Updates just the given fields of one bus under /busesFleet/{busId}.
  /// Uses update() (not set()) so unrelated fields (e.g. fuelPercent) are
  /// never clobbered by a status-only change.
  Future<void> updateFleetStatus(
    String busId,
    FleetStatus status, {
    String? driverName,
    String? routeName,
    String? driverUid,
    String? driverPhone,
  }) async {
    try {
      final Map<String, dynamic> updates = {'status': status.name};
      if (driverName != null && driverName.trim().isNotEmpty) {
        updates['driverName'] = driverName.trim();
      }
      if (routeName != null && routeName.trim().isNotEmpty) {
        updates['routeName'] = routeName.trim();
      }
      if (driverUid != null) {
        updates['driverUid'] = driverUid.trim().isEmpty
            ? null
            : driverUid.trim();
      }
      if (driverPhone != null) {
        updates['driverPhone'] = driverPhone.trim().isEmpty
            ? null
            : driverPhone.trim();
      }
      await _root.child('busesFleet/$busId').update(updates);
    } catch (error) {
      print('FirebaseService: Error updating fleet status: $error');
      rethrow;
    }
  }

  Future<BusFleet?> fetchFleetBusOnce(String busId) async {
    try {
      final snapshot = await _root.child('busesFleet/$busId').get();
      final value = snapshot.value;
      if (value is Map) {
        return BusFleet.fromMap(value, busId: busId);
      }
    } catch (error) {
      print('FirebaseService: Error fetching fleet bus: $error');
    }
    return null;
  }

  Future<void> syncDriverContactToFleet({
    required String uid,
    required String busId,
    required String name,
    required String phone,
  }) async {
    await _root.child('busesFleet/$busId').update({
      'driverUid': uid,
      'driverName': name.trim(),
      'driverPhone': phone.trim().isEmpty ? null : phone.trim(),
    });
  }
}
