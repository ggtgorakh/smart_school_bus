/// Live telemetry for a single bus, as pushed by the ESP32
/// (NEO-6M GPS + SIM800L GSM) to Firebase Realtime Database at:
///   /buses/{busId}
enum BusRunStatus { onRoute, delayed, arrived, idle }

BusRunStatus _statusFromString(String? raw) {
  switch (raw) {
    case 'delayed':
      return BusRunStatus.delayed;
    case 'arrived':
      return BusRunStatus.arrived;
    case 'idle':
      return BusRunStatus.idle;
    case 'on_route':
    default:
      return BusRunStatus.onRoute;
  }
}

class BusLocation {
  final double lat;
  final double lng;
  final double speedKmph;
  final BusRunStatus status;
  final DateTime lastUpdated;
  final int currentStopIndex;
  final int totalStops;
  final String currentStopLabel;
  final int etaMinutes;
  final String busNumber;

  const BusLocation({
    required this.lat,
    required this.lng,
    required this.speedKmph,
    required this.status,
    required this.lastUpdated,
    required this.currentStopIndex,
    required this.totalStops,
    required this.currentStopLabel,
    required this.etaMinutes,
    required this.busNumber,
  });

  /// True if the last GPS push was more than [staleAfter] ago
  bool isStale({Duration staleAfter = const Duration(minutes: 2)}) {
    return DateTime.now().difference(lastUpdated) > staleAfter;
  }

  String get statusLabel {
    switch (status) {
      case BusRunStatus.onRoute:
        return 'On Route';
      case BusRunStatus.delayed:
        return 'Delayed';
      case BusRunStatus.arrived:
        return 'Arrived';
      case BusRunStatus.idle:
        return 'Idle';
    }
  }

  String get etaLabel {
    if (status == BusRunStatus.arrived) return 'Arrived';
    if (etaMinutes <= 0) return 'Arriving now';
    return '$etaMinutes min${etaMinutes == 1 ? '' : 's'} away';
  }

  factory BusLocation.fromMap(Map<dynamic, dynamic> map) {
    // 1. Safe parsing for timestamps (Handles epoch millis, ISO strings, and invalid placeholders)
    DateTime parseLastUpdated(dynamic raw) {
      if (raw is num) {
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      } else if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return BusLocation(
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      speedKmph: (map['speedKmph'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromString(map['status'] as String?),
      lastUpdated: parseLastUpdated(map['lastUpdated']),
      currentStopIndex: (map['currentStopIndex'] as num?)?.toInt() ?? 0,
      totalStops: (map['totalStops'] as num?)?.toInt() ?? 1,
      currentStopLabel: map['currentStopLabel'] as String? ?? '—',
      etaMinutes: (map['etaMinutes'] as num?)?.toInt() ?? 0,
      busNumber: map['busNumber'] as String? ?? 'Bus',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'speedKmph': speedKmph,
      'status': status.name,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'currentStopIndex': currentStopIndex,
      'totalStops': totalStops,
      'currentStopLabel': currentStopLabel,
      'etaMinutes': etaMinutes,
      'busNumber': busNumber,
    };
  }
}