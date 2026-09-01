// lib/services/firebase_service.dart

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
      photoUrl:
          'https://images.unsplash.com/photo-1544717305-2782549b5136?w=150',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S2',
      name: 'Maya Patel',
      grade: 'Grade 4',
      seat: 'Seat 2B',
      photoUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S3',
      name: 'Ethan Williams',
      grade: 'Grade 5',
      seat: 'Seat 8C',
      photoUrl:
          'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S4',
      name: 'Sophia Garcia',
      grade: 'Grade 2',
      seat: 'Seat 1A',
      photoUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S5',
      name: 'Jackson Davis',
      grade: 'Grade 3',
      seat: 'Seat 5D',
      photoUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
  ];

  /// Streams live telemetry for [busId] from /buses/{busId}.
  Stream<BusLocation?> streamBusLocation(String busId) {
    return _root
        .child('buses/$busId')
        .onValue
        .map<BusLocation?>((event) {
          final rawData = event.snapshot.value;
          if (rawData == null) {
            return null;
          }
          if (rawData is Map) {
            return BusLocation.fromMap(rawData);
          }
          return null;
        })
        .asBroadcastStream()
        .handleError((error) {
          // Log error for debugging
          print('FirebaseService: Error streaming bus location: $error');
          return null;
        });
  }

  /// Streams real-time student attendance for a given bus route.
  Stream<List<Student>> streamStudents(String busId) {
    return _root
        .child('studentRosters/$busId')
        .onValue
        .map<List<Student>>((event) {
          final raw = event.snapshot.value;
          if (raw == null) {
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
          return defaultStudentRoster;
        })
        .handleError((error) {
          print('FirebaseService: Error streaming students: $error');
          return defaultStudentRoster;
        });
  }

  /// Streams a single child's status for the Parent Boarding Status screen.
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
            orElse: () => defaultStudentRoster[1],
          );
        })
        .handleError((error) {
          print('FirebaseService: Error streaming student: $error');
          return defaultStudentRoster.firstWhere(
            (s) => s.id == studentId,
            orElse: () => defaultStudentRoster[1],
          );
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
          .listen((event) {
            final val = event.snapshot.value;
            if (val is Map) {
              latest[studentId] = Student.fromMap(val, id: studentId);
            } else {
              latest.remove(studentId);
            }
            emit();
          }, onError: (_) {
            latest.remove(studentId);
            emit();
          });
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
    await _root
        .child('studentRosters/$busId/$studentId')
        .update(updates)
        .catchError((error) {
      print('FirebaseService: Error updating student status: $error');
    });
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
        updates['$key/boardedAt'] = status == StudentStatus.boarded ? now : null;
      });
      await _root.child('studentRosters/$busId').update(updates);
    } else {
      final updated = defaultStudentRoster.map((s) => s.copyWith(
            status: status,
            boardedAt: status == StudentStatus.boarded ? DateTime.now() : null,
          )).toList();
      await seedStudents(busId, updated);
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
}