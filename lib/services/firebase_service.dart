// lib/services/firebase_service.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/bus_fleet.dart';
import '../models/bus_location.dart';
import '../models/student.dart';
import '../models/attendance_event.dart';
import '../models/trip.dart';
import 'offline_write_queue.dart';

/// Central wrapper around Firebase Realtime Database for live telemetry
/// and real-time student attendance manifests.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();
  final OfflineWriteQueue _writeQueue = OfflineWriteQueue.instance;

  String? get currentUserUid => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<Trip>> streamTripsForBus(String busId) {
    return _root.child('trips/$busId').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <Trip>[];
      final trips = <Trip>[];
      raw.forEach((key, value) {
        if (value is Map) {
          trips.add(Trip.fromMap(value, tripId: key.toString()));
        }
      });
      trips.sort((a, b) {
        final aTime = a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return trips;
    });
  }

  Stream<Trip?> streamActiveTrip(String busId) {
    return streamTripsForBus(busId).map((trips) {
      for (final trip in trips) {
        if (trip.isOpen) return trip;
      }
      return null;
    });
  }

  Future<Trip> createTrip({
    required String busId,
    required String routeId,
    required String driverUid,
    String? conductorUid,
  }) async {
    final active = await _root.child('trips/$busId').get();
    if (active.value is Map) {
      for (final entry in (active.value as Map).entries) {
        if (entry.value is Map) {
          final trip = Trip.fromMap(
            entry.value as Map,
            tripId: entry.key.toString(),
          );
          if (trip.isOpen) {
            throw StateError('This bus already has an open trip.');
          }
        }
      }
    }

    final tripId = _root.child('trips/$busId').push().key;
    if (tripId == null) throw StateError('Unable to create a trip ID.');
    final trip = Trip(
      tripId: tripId,
      busId: busId,
      routeId: routeId,
      driverUid: driverUid,
      conductorUid: conductorUid,
      status: TripStatus.scheduled,
    );
    await _root.child('trips/$busId/$tripId').set(trip.toMap());
    return trip;
  }

  Future<Trip> transitionTrip({
    required String busId,
    required String tripId,
    required TripStatus nextStatus,
  }) async {
    final snapshot = await _root.child('trips/$busId/$tripId').get();
    if (snapshot.value is! Map) {
      throw StateError('Trip $tripId does not exist.');
    }
    final current = Trip.fromMap(snapshot.value as Map, tripId: tripId);
    if (!Trip.canTransition(current.status, nextStatus)) {
      throw StateError(
        'Cannot transition trip from ${current.status.name} to ${nextStatus.name}.',
      );
    }

    final now = DateTime.now();
    final updates = <String, dynamic>{'status': nextStatus.name};
    if (nextStatus == TripStatus.active && current.startTime == null) {
      updates['startTime'] = now.millisecondsSinceEpoch;
    }
    if (nextStatus == TripStatus.completed ||
        nextStatus == TripStatus.cancelled) {
      updates['endTime'] = now.millisecondsSinceEpoch;
    }
    await _root.child('trips/$busId/$tripId').update(updates);
    return current.copyWith(
      status: nextStatus,
      startTime: updates.containsKey('startTime') ? now : current.startTime,
      endTime: updates.containsKey('endTime') ? now : current.endTime,
    );
  }

  Stream<List<AttendanceEvent>> streamAttendanceEvents(String tripId) {
    return _root.child('attendanceEvents').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <AttendanceEvent>[];
      final events = <AttendanceEvent>[];
      raw.forEach((busId, busEvents) {
        if (busEvents is! Map) return;
        busEvents.forEach((key, value) {
          if (value is Map && value['tripId']?.toString() == tripId) {
            events.add(AttendanceEvent.fromMap(value, eventId: key.toString()));
          }
        });
      });
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return events;
    });
  }

  Future<AttendanceEvent> recordAttendanceEvent({
    required String studentId,
    required String busId,
    required String tripId,
    required AttendanceEventStatus status,
    required String source,
    String? correctionOf,
    String? correctionReason,
  }) async {
    final actorUid = currentUserUid;
    if (actorUid == null) {
      throw StateError('Attendance updates require an authenticated user.');
    }
    final eventId = _root.child('attendanceEvents').push().key;
    if (eventId == null) throw StateError('Unable to create an attendance ID.');
    final event = AttendanceEvent(
      eventId: eventId,
      studentId: studentId,
      busId: busId,
      tripId: tripId,
      actorUid: actorUid,
      status: status,
      source: source,
      timestamp: DateTime.now(),
      correctionOf: correctionOf,
      correctionReason: correctionReason,
    );
    final eventPath = 'attendanceEvents/$busId/$eventId';
    final studentPath = 'studentRosters/$busId/$studentId';
    final studentUpdates = <String, dynamic>{
      'status': status == AttendanceEventStatus.boarded
          ? StudentStatus.boarded.name
          : status == AttendanceEventStatus.flagged
          ? StudentStatus.alert.name
          : StudentStatus.pending.name,
      'boardedAt': status == AttendanceEventStatus.boarded
          ? event.timestamp.millisecondsSinceEpoch
          : null,
    };
    try {
      final updates = <String, dynamic>{
        eventPath: event.toMap(),
        '$studentPath/status': studentUpdates['status'],
        '$studentPath/boardedAt': studentUpdates['boardedAt'],
      };
      await _root.update(updates);
    } catch (error) {
      if (_shouldQueueWrite(error)) {
        await _writeQueue.enqueue(
          path: '',
          operation: OfflineWriteOperation.update,
          value: {
            eventPath: event.toMap(),
            '$studentPath/status': studentUpdates['status'],
            '$studentPath/boardedAt': studentUpdates['boardedAt'],
          },
          userId: actorUid,
          busId: busId,
          tripId: tripId,
          studentId: studentId,
          eventId: eventId,
          source: source,
        );
      }
      rethrow;
    }
    return event;
  }

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
          userId: currentUserUid,
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
          userId: currentUserUid,
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

  /// Streams every available live bus telemetry record for Admin fleet views.
  Stream<Map<String, BusLocation>> streamAllBusLocations() {
    return _root.child('buses').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <String, BusLocation>{};
      final locations = <String, BusLocation>{};
      raw.forEach((key, value) {
        if (value is Map) {
          locations[key.toString()] = BusLocation.fromMap(value);
        }
      });
      return locations;
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

  /// Streams every student roster for Admin-wide student management views.
  Stream<List<Student>> streamAllStudents() {
    return _root.child('studentRosters').onValue.map<List<Student>>((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <Student>[];

      final students = <Student>[];
      raw.forEach((busId, roster) {
        if (roster is! Map) return;
        roster.forEach((studentId, value) {
          if (value is Map) {
            students.add(
              Student.fromMap(
                value,
                id: studentId.toString(),
                busId: busId.toString(),
              ),
            );
          }
        });
      });
      students.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return students;
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
                latest[studentId] = Student.fromMap(
                  val,
                  id: studentId,
                  busId: busId,
                );
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

  Future<void> updateStudentParentDetails(
    String busId,
    String studentId,
    Map<String, dynamic> parentFields,
  ) async {
    final path = 'studentRosters/$busId/$studentId';
    final updates = <String, dynamic>{};

    for (final entry in parentFields.entries) {
      final key = entry.key;
      final rawValue = entry.value;
      if (rawValue == null) {
        updates[key] = null;
        continue;
      }
      if (rawValue is String) {
        final value = rawValue.trim();
        updates[key] = value.isEmpty ? null : value;
      } else {
        updates[key] = rawValue;
      }
    }

    if (updates.isEmpty) return;

    try {
      await _root.child(path).update(updates);
    } catch (error) {
      if (_shouldQueueWrite(error)) {
        await _writeQueue.enqueue(
          path: path,
          operation: OfflineWriteOperation.update,
          value: updates,
          userId: currentUserUid,
          busId: busId,
          studentId: studentId,
        );
      }
      rethrow;
    }
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
          userId: currentUserUid,
          busId: busId,
          studentId: studentId,
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
            userId: currentUserUid,
            busId: busId,
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
      final studentRef = _root.child('studentRosters/$busId/${student.id}');
      final previousSnapshot = await studentRef.get();
      final previousParentUid = previousSnapshot.value is Map
          ? (previousSnapshot.value as Map)['parentUid']?.toString().trim()
          : null;
      final nextParentUid = student.parentUid?.trim();
      final updates = <String, dynamic>{
        'studentRosters/$busId/${student.id}': student.toMap(),
      };

      if (previousParentUid != null &&
          previousParentUid.isNotEmpty &&
          previousParentUid != nextParentUid) {
        updates['parentChildIndex/$previousParentUid/$busId/${student.id}'] =
            null;
      }
      if (nextParentUid != null && nextParentUid.isNotEmpty) {
        updates['parentChildIndex/$nextParentUid/$busId/${student.id}'] = true;
      }
      await _root.update(updates);
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

  /// Streams one fleet record. Parents must use this scoped read because
  /// Firebase rules allow them to read only a bus assigned to their child.
  Stream<BusFleet?> streamFleetBus(String busId) {
    return _root.child('busesFleet/$busId').onValue.map<BusFleet?>((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return null;
      return BusFleet.fromMap(raw, busId: busId);
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
    String? conductorUid,
    String? conductorName,
    String? conductorPhone,
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
      if (conductorUid != null) {
        updates['conductorUid'] = conductorUid.trim().isEmpty
            ? null
            : conductorUid.trim();
      }
      if (conductorName != null) {
        updates['conductorName'] = conductorName.trim().isEmpty
            ? null
            : conductorName.trim();
      }
      if (conductorPhone != null) {
        updates['conductorPhone'] = conductorPhone.trim().isEmpty
            ? null
            : conductorPhone.trim();
      }
      await _root.child('busesFleet/$busId').update(updates);
    } catch (error) {
      print('FirebaseService: Error updating fleet status: $error');
      rethrow;
    }
  }

  Future<void> updateFleetAssignmentForRole(
    String busId, {
    required String role,
    required String? uid,
    required String name,
    required String? phone,
  }) async {
    final prefix = role == 'Driver' ? 'driver' : 'conductor';
    try {
      await _root.child('busesFleet/$busId').update({
        '${prefix}Uid': uid,
        '${prefix}Name': name,
        '${prefix}Phone': phone,
      });
    } catch (error) {
      print('FirebaseService: Error updating $role assignment: $error');
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
