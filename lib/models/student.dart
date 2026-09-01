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
  final String? busId;

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
    this.busId,
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

  /// Check if student is linked to a parent
  bool get isLinkedToParent => parentUid != null && parentUid!.isNotEmpty;

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
    };
  }

  factory Student.fromMap(Map<dynamic, dynamic> map, {String? id, String? busId}) {
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
      busId: busId,
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
    String? busId,
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
      busId: busId ?? this.busId,
    );
  }
}