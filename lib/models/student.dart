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
  // Parent-child linkage: the Firebase Auth uid of this child's Parent
  // account. Nullable because existing/legacy student records created
  // before this field existed won't have it set — those show up as
  // "unlinked" in the Admin UI rather than crashing on a missing field.
  final String? parentUid;

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
  });

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

  factory Student.fromMap(Map<dynamic, dynamic> map, {String? id}) {
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
    );
  }
}