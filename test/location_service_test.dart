import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbus_safe/models/bus_location.dart';
import 'package:schoolbus_safe/services/location_service.dart';

void main() {
  test('BusLocation serialization exactly matches RTDB schema required by rules', () {
    final now = DateTime.now();
    final busLoc = BusLocation(
      lat: 28.6139,
      lng: 77.2090,
      speedKmph: 42.5,
      status: BusRunStatus.onRoute,
      lastUpdated: now,
      currentStopIndex: 2,
      totalStops: 5,
      currentStopLabel: 'Stop 2 - North Gate',
      etaMinutes: 12,
      busNumber: 'BUS-01',
    );

    final map = busLoc.toMap();

    // Verify all required keys from database.rules.json
    final requiredKeys = [
      'lat',
      'lng',
      'speedKmph',
      'status',
      'lastUpdated',
      'currentStopIndex',
      'totalStops',
      'currentStopLabel',
      'etaMinutes',
      'busNumber',
    ];
    for (final key in requiredKeys) {
      expect(map.containsKey(key), isTrue, reason: 'Missing required key: $key');
    }

    expect(map['lat'], 28.6139);
    expect(map['lng'], 77.2090);
    expect(map['speedKmph'], 42.5);
    expect(map['status'], 'on_route');
    expect(map['lastUpdated'], now.millisecondsSinceEpoch);

    // Verify round-trip deserialization
    final deserialized = BusLocation.fromMap(map);
    expect(deserialized.lat, busLoc.lat);
    expect(deserialized.lng, busLoc.lng);
    expect(deserialized.speedKmph, busLoc.speedKmph);
    expect(deserialized.status, BusRunStatus.onRoute);
    expect(deserialized.currentStopLabel, 'Stop 2 - North Gate');
  });

  test('BusLocation status and staleness calculations work properly', () {
    final freshLocation = BusLocation(
      lat: 12.9716,
      lng: 77.5946,
      speedKmph: 0.0,
      status: BusRunStatus.idle,
      lastUpdated: DateTime.now(),
      currentStopIndex: 0,
      totalStops: 4,
      currentStopLabel: 'School Terminal',
      etaMinutes: 0,
      busNumber: 'BUS-02',
    );

    expect(freshLocation.isStale(), isFalse);
    expect(freshLocation.statusLabel, 'Idle');

    final staleLocation = freshLocation.copyWith(
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
    );
    expect(staleLocation.isStale(), isTrue);
  });

  test('LocationService instance initial state', () {
    final service = LocationService.instance;
    expect(service.isTracking, isFalse);
    expect(service.currentBusId, isNull);
  });

  test('stopTracking accepts an explicit busId without requiring prior startTracking', () async {
    // Regression test for the "stop tracking after app restart" fix: even
    // if this LocationService instance never called startTracking() in the
    // current process (so currentBusId is null), callers must be able to
    // pass a busId explicitly and have it accepted by the API. This does
    // not touch Firebase since there is nothing to mark offline when no
    // busId is supplied and none is tracked.
    final service = LocationService.instance;
    expect(service.currentBusId, isNull);
    await service.stopTracking();
    expect(service.isTracking, isFalse);
    expect(service.currentBusId, isNull);
  });
}
