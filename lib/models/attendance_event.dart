enum AttendanceEventStatus {
  boarded,
  pending,
  notBoarded,
  flagged,
  // New states for the four-step parent-facing protocol.
  coming,  // bus approaching the child's stop (auto)
  reached, // bus arrived at stop (auto)
  picked,  // child boarded (conductor manual)
  leaved,  // bus departed the stop (auto)
  // Parent signal: "my child is at the stop, ready to board"
  atStop,
}

AttendanceEventStatus attendanceEventStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'boarded':
      return AttendanceEventStatus.boarded;
    case 'notboarded':
    case 'not_boarded':
      return AttendanceEventStatus.notBoarded;
    case 'flagged':
      return AttendanceEventStatus.flagged;
    case 'coming':
      return AttendanceEventStatus.coming;
    case 'reached':
      return AttendanceEventStatus.reached;
    case 'picked':
      return AttendanceEventStatus.picked;
    case 'leaved':
      return AttendanceEventStatus.leaved;
    case 'atstop':
    case 'at_stop':
      return AttendanceEventStatus.atStop;
    case 'pending':
    default:
      return AttendanceEventStatus.pending;
  }
}

/// Human-readable label for a status value. Used by UI to avoid a
/// switch-case cascade at every call site.
extension AttendanceEventStatusLabel on AttendanceEventStatus {
  String get label {
    switch (this) {
      case AttendanceEventStatus.boarded:
        return 'Boarded';
      case AttendanceEventStatus.pending:
        return 'Pending';
      case AttendanceEventStatus.notBoarded:
        return 'Not Boarded';
      case AttendanceEventStatus.flagged:
        return 'Flagged';
      case AttendanceEventStatus.coming:
        return 'Bus coming';
      case AttendanceEventStatus.reached:
        return 'Bus arrived';
      case AttendanceEventStatus.picked:
        return 'Picked up';
      case AttendanceEventStatus.leaved:
        return 'Bus departed';
      case AttendanceEventStatus.atStop:
        return 'At stop';
    }
  }
}

class AttendanceEvent {
  final String eventId;
  final String studentId;
  final String busId;
  final String tripId;
  final String actorUid;
  final AttendanceEventStatus status;
  final String source;
  final DateTime timestamp;
  final String? correctionOf;
  final String? correctionReason;

  const AttendanceEvent({
    required this.eventId,
    required this.studentId,
    required this.busId,
    required this.tripId,
    required this.actorUid,
    required this.status,
    required this.source,
    required this.timestamp,
    this.correctionOf,
    this.correctionReason,
  });

  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'studentId': studentId,
    'busId': busId,
    'tripId': tripId,
    'actorUid': actorUid,
    'status': status.name,
    'source': source,
    'timestamp': timestamp.millisecondsSinceEpoch,
    if (correctionOf != null) 'correctionOf': correctionOf,
    if (correctionReason != null) 'correctionReason': correctionReason,
  };

  factory AttendanceEvent.fromMap(
    Map<dynamic, dynamic> map, {
    String? eventId,
  }) {
    final rawTimestamp = map['timestamp'];
    final timestamp = rawTimestamp is num
        ? DateTime.fromMillisecondsSinceEpoch(rawTimestamp.toInt())
        : DateTime.tryParse(rawTimestamp?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);

    return AttendanceEvent(
      eventId: eventId ?? map['eventId']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      busId: map['busId']?.toString() ?? '',
      tripId: map['tripId']?.toString() ?? '',
      actorUid: map['actorUid']?.toString() ?? '',
      status: attendanceEventStatusFromString(map['status']?.toString()),
      source: map['source']?.toString() ?? 'manual',
      timestamp: timestamp,
      correctionOf: map['correctionOf']?.toString(),
      correctionReason: map['correctionReason']?.toString(),
    );
  }
}