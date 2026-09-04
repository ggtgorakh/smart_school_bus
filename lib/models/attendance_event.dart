enum AttendanceEventStatus { boarded, pending, notBoarded, flagged }

AttendanceEventStatus attendanceEventStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'boarded':
      return AttendanceEventStatus.boarded;
    case 'notboarded':
    case 'not_boarded':
      return AttendanceEventStatus.notBoarded;
    case 'flagged':
      return AttendanceEventStatus.flagged;
    case 'pending':
    default:
      return AttendanceEventStatus.pending;
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
