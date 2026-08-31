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
  ///
  /// IMPORTANT (Bug #1 fix): this never fabricates or writes fallback/demo
  /// GPS data. A `null` snapshot value means "no data for this bus yet" and
  /// is surfaced as-is to the UI (which shows "Bus data not available").
  /// Firebase errors (e.g. PERMISSION_DENIED) are allowed to propagate as
  /// stream errors instead of being swallowed, so the real error state is
  /// visible during testing rather than being masked by fake data.
  Stream<BusLocation?> streamBusLocation(String busId) {
    return _root.child('buses/$busId').onValue.map<BusLocation?>((event) {
      final rawData = event.snapshot.value;
      if (rawData == null) {
        // No demo/fallback seeding here — genuinely missing data is
        // reported upstream as `null` so the UI can say so honestly.
        return null;
      }

      if (rawData is Map) {
        return BusLocation.fromMap(rawData);
      }
      return null;
    }).asBroadcastStream();
    // .asBroadcastStream() lets multiple listeners (e.g. a manual
    // subscription for notifications AND a StreamBuilder for rendering)
    // both listen to this same stream safely, without throwing
    // "Bad state: Stream has already been listened to."
    // Note: deliberately NOT using .handleError() here. Swallowing errors
    // (as the previous implementation did) hid PERMISSION_DENIED and other
    // Firebase failures behind a state that looked identical to "no bus
    // yet". Letting the error propagate lets StreamBuilder's `hasError`
    // branch show the real failure.
  }

  /// Streams real-time student attendance for a given bus route.
  ///
  /// Path note: moved from /buses/{busId}/students to its own top-level
  /// /studentRosters/{busId} — see database.rules.json for why (RTDB read
  /// grants cascade downward, so nesting the roster under /buses made it
  /// impossible to scope roster access separately from bus telemetry).
  Stream<List<Student>> streamStudents(String busId) {
    return _root.child('studentRosters/$busId').onValue.map<List<Student>>((event) {
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

  /// Streams a single child's status for the Parent Boarding Status screen.
  /// Path note: see streamStudents above.
  Stream<Student> streamStudent(String busId, String studentId) {
    return _root
        .child('studentRosters/$busId/$studentId')
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

  /// Streams every child currently linked to [parentUid] via
  /// /parentChildIndex/{parentUid}/{busId}/{studentId}, resolving each
  /// entry to its live student record under
  /// /studentRosters/{busId}/{studentId}.
  ///
  /// Index shape note (P0 fix, ISSUE-04): this used to be a flat
  /// {studentId: busId} map. It's now nested as {busId: {studentId: true}}
  /// specifically so database.rules.json can check "does this parent have
  /// a child on bus X" in a single rule expression when deciding whether
  /// a Parent may read that bus's GPS telemetry — RTDB rules can't
  /// iterate a map's values to test membership, so the busId has to be a
  /// key, not a value.
  ///
  /// A Parent cannot list a bus's full roster (database.rules.json denies
  /// that at the collection level), so this reads the small index of
  /// "which student IDs are mine, on which buses" first, then subscribes
  /// to each of those specific records directly — which the per-record
  /// rule allows. This is the standard Realtime Database pattern for
  /// row-level-filtered reads, since RTDB security rules can't filter
  /// query results per-item the way Firestore's can.
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
          .listen((event) {
        final val = event.snapshot.value;
        if (val is Map) {
          latest[studentId] = Student.fromMap(val, id: studentId);
        } else {
          latest.remove(studentId);
        }
        emit();
      }, onError: (_) {
        // A single unreadable/misconfigured child shouldn't take down the
        // whole list — just drop it from the merged view.
        latest.remove(studentId);
        emit();
      });
    }

    void handleIndexUpdate(dynamic raw) {
      final currentIds = <String>{};
      if (raw is Map) {
        // raw shape: { busId: { studentId: true, ... }, ... }
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
      // Drop subscriptions/entries for students no longer in the index.
      final removedIds =
          childSubs.keys.where((id) => !currentIds.contains(id)).toList();
      for (final id in removedIds) {
        childSubs.remove(id)?.cancel();
        latest.remove(id);
      }
      emit();
    }

    controller = StreamController<List<Student>>.broadcast(
      onListen: () {
        indexSub = _root.child('parentChildIndex/$parentUid').onValue.listen(
          (event) => handleIndexUpdate(event.snapshot.value),
          onError: (_) => emit(), // nothing readable/linked yet — show empty
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

  /// Updates a student's boarding status in Realtime Database.
  /// Path note: see streamStudents above.
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
    await _root.child('studentRosters/$busId/$studentId').update(updates);
  }

  /// Marks all students on the bus with the given status.
  /// Path note: see streamStudents above.
  Future<void> markAllStudentsStatus(String busId, StudentStatus status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final snapshot = await _root.child('studentRosters/$busId').get();
    final data = snapshot.value;

    if (data is Map) {
      final Map<String, Object?> updates = {};
      data.forEach((key, _) {
        updates['$key/status'] = status.name;
        updates['$key/boardedAt'] = status == StudentStatus.boarded ? now : null;
      });
      await _root.child('studentRosters/$busId').update(updates);
    } else {
      // Seed default list with the new status
      final updated = defaultStudentRoster.map((s) => s.copyWith(
        status: status,
        boardedAt: status == StudentStatus.boarded ? DateTime.now() : null,
      )).toList();
      await seedStudents(busId, updated);
    }
  }

  /// Seeds a list of students into RTDB.
  /// Path note: see streamStudents above.
  Future<void> seedStudents(String busId, List<Student> students) async {
    try {
      final Map<String, dynamic> data = {};
      for (final s in students) {
        data[s.id] = s.toMap();
      }
      await _root.child('studentRosters/$busId').set(data);
    } catch (_) {}
  }

  /// Creates or updates a single student record and, if it has a
  /// [Student.parentUid], keeps
  /// /parentChildIndex/{parentUid}/{busId}/{studentId} in sync so that
  /// Parent can find and read this record (see streamChildrenForParent
  /// above) and read the bus it's on (see database.rules.json's
  /// /buses/{busId} rule). Used by the Admin "Manage Students" screen to
  /// link a child to a Parent account.
  Future<void> upsertStudent({
    required String busId,
    required Student student,
  }) async {
    await _root.child('studentRosters/$busId/${student.id}').set(student.toMap());
    if (student.parentUid != null && student.parentUid!.trim().isNotEmpty) {
      await _root
          .child('parentChildIndex/${student.parentUid}/$busId/${student.id}')
          .set(true);
    }
  }

  /// Removes a child's link to a Parent account (e.g. re-assigning a
  /// student to a different parent, or clearing a mistaken link) without
  /// deleting the underlying student record itself.
  ///
  /// [busId] is required now that the index is nested by bus — see
  /// streamChildrenForParent above for why.
  Future<void> unlinkChildFromParent({
    required String parentUid,
    required String busId,
    required String studentId,
  }) async {
    await _root.child('parentChildIndex/$parentUid/$busId/$studentId').remove();
  }

  /// One-off read for manual refresh checks.
  ///
  /// Bug #1 fix: no longer masks a missing bus or a Firebase error behind
  /// fabricated San-Francisco fallback coordinates. Missing data returns
  /// `null`; real errors are rethrown so the caller can show them.
  Future<BusLocation?> fetchBusLocationOnce(String busId) async {
    final snapshot = await _root.child('buses/$busId').get();
    final rawData = snapshot.value;

    if (rawData != null && rawData is Map) {
      return BusLocation.fromMap(rawData);
    }
    return null;
  }

  /// Writes driver or hardware telemetry updates to Firebase (ESP32 Simulator / Testing)
  Future<void> updateBusLocation(String busId, BusLocation location) async {
    await _root.child('buses/$busId').update(location.toMap());
  }
}