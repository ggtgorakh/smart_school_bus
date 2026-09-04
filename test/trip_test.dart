import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbus_safe/models/trip.dart';

void main() {
  test('trip lifecycle allows only valid transitions', () {
    expect(
      Trip.canTransition(TripStatus.scheduled, TripStatus.preparing),
      isTrue,
    );
    expect(Trip.canTransition(TripStatus.preparing, TripStatus.active), isTrue);
    expect(Trip.canTransition(TripStatus.active, TripStatus.paused), isTrue);
    expect(Trip.canTransition(TripStatus.paused, TripStatus.active), isTrue);
    expect(
      Trip.canTransition(TripStatus.completed, TripStatus.active),
      isFalse,
    );
  });

  test('trip serialization preserves lifecycle fields', () {
    final trip = Trip(
      tripId: 'trip-1',
      busId: 'bus_01',
      routeId: 'route-1',
      driverUid: 'driver-1',
      status: TripStatus.active,
      startTime: DateTime.fromMillisecondsSinceEpoch(1000),
    );

    final restored = Trip.fromMap(trip.toMap(), tripId: trip.tripId);
    expect(restored.tripId, 'trip-1');
    expect(restored.busId, 'bus_01');
    expect(restored.status, TripStatus.active);
    expect(restored.startTime, DateTime.fromMillisecondsSinceEpoch(1000));
  });
}
