import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbus_safe/models/attendance_event.dart';

void main() {
  test('attendance event serialization preserves audit context', () {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(5000);
    final event = AttendanceEvent(
      eventId: 'event-1',
      studentId: 'student-1',
      busId: 'bus_01',
      tripId: 'trip-1',
      actorUid: 'conductor-1',
      status: AttendanceEventStatus.boarded,
      source: 'manual',
      timestamp: timestamp,
      correctionOf: 'event-0',
      correctionReason: 'Student was marked at the wrong stop',
    );

    final restored = AttendanceEvent.fromMap(
      event.toMap(),
      eventId: event.eventId,
    );
    expect(restored.eventId, 'event-1');
    expect(restored.studentId, 'student-1');
    expect(restored.status, AttendanceEventStatus.boarded);
    expect(restored.actorUid, 'conductor-1');
    expect(restored.correctionOf, 'event-0');
    expect(restored.correctionReason, contains('wrong stop'));
  });
}
