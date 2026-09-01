// lib/models/bus_location.dart

/// Live telemetry for a single bus, as pushed by the ESP32
/// (NEO-6M GPS + SIM800L GSM) to Firebase Realtime Database at:
/// /buses/{busId}

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

String _statusToString(BusRunStatus status) {
  switch (status) {
    case BusRunStatus.onRoute:
      return 'on_route';
    case BusRunStatus.delayed:
      return 'delayed';
    case BusRunStatus.arrived:
      return 'arrived';
    case BusRunStatus.idle:
      return 'idle';
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

  /// Get human-readable status label
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

  /// Get human-readable ETA label
  String get etaLabel {
    if (status == BusRunStatus.arrived) return 'Arrived';
    if (etaMinutes <= 0) return 'Arriving now';
    return '$etaMinutes min${etaMinutes == 1 ? '' : 's'} away';
  }

  /// Get status color
  int get statusColor {
    switch (status) {
      case BusRunStatus.onRoute:
        return 0xFF16A34A; // success green
      case BusRunStatus.delayed:
        return 0xFFF59E0B; // alert orange
      case BusRunStatus.arrived:
        return 0xFF2563EB; // safety blue
      case BusRunStatus.idle:
        return 0xFF718096; // gray
    }
  }

  /// Get status icon
  String get statusIcon {
    switch (status) {
      case BusRunStatus.onRoute:
        return 'play_arrow';
      case BusRunStatus.delayed:
        return 'warning_amber';
      case BusRunStatus.arrived:
        return 'check_circle';
      case BusRunStatus.idle:
        return 'pause_circle';
    }
  }

  factory BusLocation.fromMap(Map<dynamic, dynamic> map) {
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
      currentStopLabel: map['currentStopLabel'] as String? ?? '---',
      etaMinutes: (map['etaMinutes'] as num?)?.toInt() ?? 0,
      busNumber: map['busNumber'] as String? ?? 'Bus',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'speedKmph': speedKmph,
      'status': _statusToString(status),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'currentStopIndex': currentStopIndex,
      'totalStops': totalStops,
      'currentStopLabel': currentStopLabel,
      'etaMinutes': etaMinutes,
      'busNumber': busNumber,
    };
  }

  BusLocation copyWith({
    double? lat,
    double? lng,
    double? speedKmph,
    BusRunStatus? status,
    DateTime? lastUpdated,
    int? currentStopIndex,
    int? totalStops,
    String? currentStopLabel,
    int? etaMinutes,
    String? busNumber,
  }) {
    return BusLocation(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speedKmph: speedKmph ?? this.speedKmph,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      totalStops: totalStops ?? this.totalStops,
      currentStopLabel: currentStopLabel ?? this.currentStopLabel,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      busNumber: busNumber ?? this.busNumber,
    );
  }
}