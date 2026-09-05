// lib/models/student.dart

enum StudentStatus { boarded, pending, alert }

StudentStatus studentStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'boarded':
      return StudentStatus.boarded;
    case 'alert':
      return StudentStatus.alert;
    case 'pending':
    default:
      return StudentStatus.pending;
  }
}

class Student {
  final String id;
  final String name;
  final String grade;
  final String seat;
  final String photoUrl;
  StudentStatus status;
  final String stopName;
  final DateTime? boardedAt;
  final String? parentUid;
  final String? parentName;
  final String? parentPhone;
  final String? busId;
  final String? section;
  final String? schoolName;
  final String? schoolId;
  final DateTime? dateOfBirth;
  final String? homeAddress;
  final String? pickupStop;
  final String? dropOffStop;
  final String? emergencyContact;
  final String? authorizedPickupPerson;
  final String? transportationInstructions;
  final String? medicalNotes;
  final String? rollNumber;

  Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.seat,
    required this.photoUrl,
    required this.status,
    required this.stopName,
    this.boardedAt,
    this.parentUid,
    this.parentName,
    this.parentPhone,
    this.busId,
    this.section,
    this.schoolName,
    this.schoolId,
    this.dateOfBirth,
    this.homeAddress,
    this.pickupStop,
    this.dropOffStop,
    this.emergencyContact,
    this.authorizedPickupPerson,
    this.transportationInstructions,
    this.medicalNotes,
    this.rollNumber,
  });

  /// Get human-readable status label
  String get statusLabel {
    switch (status) {
      case StudentStatus.boarded:
        return 'Boarded';
      case StudentStatus.pending:
        return 'Pending';
      case StudentStatus.alert:
        return 'Alert';
    }
  }

  /// Get status color
  int get statusColor {
    switch (status) {
      case StudentStatus.boarded:
        return 0xFF16A34A;
      case StudentStatus.pending:
        return 0xFFF59E0B;
      case StudentStatus.alert:
        return 0xFFDC2626;
    }
  }

  /// Get status icon
  String get statusIcon {
    switch (status) {
      case StudentStatus.boarded:
        return 'check_circle';
      case StudentStatus.pending:
        return 'hourglass_top';
      case StudentStatus.alert:
        return 'error';
    }
  }

  /// Check if student is linked to a parent (has a real login account)
  bool get isLinkedToParent => parentUid != null && parentUid!.isNotEmpty;

  /// Best-available parent display name — falls back gracefully when only
  /// one of the two (uid-linked account vs. imported contact info) exists.
  String get parentDisplayName =>
      (parentName != null && parentName!.trim().isNotEmpty)
          ? parentName!.trim()
          : 'No parent info';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'seat': seat,
      'photoUrl': photoUrl,
      'status': status.name,
      'stopName': stopName,
      'boardedAt': boardedAt?.millisecondsSinceEpoch,
      'parentUid': parentUid,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'section': section,
      'schoolName': schoolName,
      'schoolId': schoolId,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'homeAddress': homeAddress,
      'pickupStop': pickupStop,
      'dropOffStop': dropOffStop,
      'emergencyContact': emergencyContact,
      'authorizedPickupPerson': authorizedPickupPerson,
      'transportationInstructions': transportationInstructions,
      'medicalNotes': medicalNotes,
      'rollNumber': rollNumber ?? id,
    };
  }

  factory Student.fromMap(Map<dynamic, dynamic> map, {String? id, String? busId}) {
    DateTime? parseDate(dynamic raw) {
      if (raw is num) {
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      } else if (raw is String) {
        return DateTime.tryParse(raw);
      }
      return null;
    }

    DateTime? parseBoardedAt(dynamic raw) {
      if (raw is num) {
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      } else if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed;
      }
      return null;
    }

    return Student(
      id: id ?? (map['id']?.toString() ?? ''),
      name: map['name']?.toString() ?? 'Student',
      grade: map['grade']?.toString() ?? 'Grade 1',
      seat: map['seat']?.toString() ?? 'Seat 1A',
      photoUrl: map['photoUrl']?.toString() ?? '',
      status: studentStatusFromString(map['status']?.toString()),
      stopName: map['stopName']?.toString() ?? 'Main Stop',
      boardedAt: parseBoardedAt(map['boardedAt']),
      parentUid: map['parentUid']?.toString(),
      parentName: map['parentName']?.toString(),
      parentPhone: map['parentPhone']?.toString(),
      busId: busId,
      section: map['section']?.toString(),
      schoolName: map['schoolName']?.toString(),
      schoolId: map['schoolId']?.toString(),
      dateOfBirth: parseDate(map['dateOfBirth']),
      homeAddress: map['homeAddress']?.toString(),
      pickupStop: map['pickupStop']?.toString(),
      dropOffStop: map['dropOffStop']?.toString() ?? map['dropoffStop']?.toString(),
      emergencyContact: map['emergencyContact']?.toString(),
      authorizedPickupPerson: map['authorizedPickupPerson']?.toString(),
      transportationInstructions: map['transportationInstructions']?.toString(),
      medicalNotes: map['medicalNotes']?.toString(),
      rollNumber: map['rollNumber']?.toString() ?? map['studentId']?.toString(),
    );
  }

  Student copyWith({
    String? id,
    String? name,
    String? grade,
    String? seat,
    String? photoUrl,
    StudentStatus? status,
    String? stopName,
    DateTime? boardedAt,
    String? parentUid,
    String? parentName,
    String? parentPhone,
    String? busId,
    String? section,
    String? schoolName,
    String? schoolId,
    DateTime? dateOfBirth,
    String? homeAddress,
    String? pickupStop,
    String? dropOffStop,
    String? emergencyContact,
    String? authorizedPickupPerson,
    String? transportationInstructions,
    String? medicalNotes,
    String? rollNumber,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      seat: seat ?? this.seat,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      stopName: stopName ?? this.stopName,
      boardedAt: boardedAt ?? this.boardedAt,
      parentUid: parentUid ?? this.parentUid,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      busId: busId ?? this.busId,
      section: section ?? this.section,
      schoolName: schoolName ?? this.schoolName,
      schoolId: schoolId ?? this.schoolId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      homeAddress: homeAddress ?? this.homeAddress,
      pickupStop: pickupStop ?? this.pickupStop,
      dropOffStop: dropOffStop ?? this.dropOffStop,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      authorizedPickupPerson: authorizedPickupPerson ?? this.authorizedPickupPerson,
      transportationInstructions:
          transportationInstructions ?? this.transportationInstructions,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      rollNumber: rollNumber ?? this.rollNumber,
    );
  }
}









