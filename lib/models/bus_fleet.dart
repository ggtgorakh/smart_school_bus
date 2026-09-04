// lib/models/bus_fleet.dart

enum FleetStatus { onRoute, delayed, maintenance, idle }

/// Parses a status string stored in Firebase (/busesFleet/{busId}/status)
/// back into a FleetStatus. Defaults to idle for unknown/missing values so
/// a bus never silently shows as "On Route" when its real state is unknown.
FleetStatus fleetStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'onroute':
    case 'on_route':
      return FleetStatus.onRoute;
    case 'delayed':
      return FleetStatus.delayed;
    case 'maintenance':
      return FleetStatus.maintenance;
    case 'idle':
    default:
      return FleetStatus.idle;
  }
}

class BusFleet {
  final String busId;
  final String driverName;
  final String? driverUid;
  final String? driverPhone;
  final String routeName;
  final String estArrival;
  final FleetStatus status;
  final int speedMph;
  final int fuelPercent;

  BusFleet({
    required this.busId,
    required this.driverName,
    this.driverUid,
    this.driverPhone,
    required this.routeName,
    required this.estArrival,
    required this.status,
    required this.speedMph,
    required this.fuelPercent,
  });

  /// Get human-readable status label
  String get statusLabel {
    switch (status) {
      case FleetStatus.onRoute:
        return 'On Route';
      case FleetStatus.delayed:
        return 'Delayed';
      case FleetStatus.maintenance:
        return 'Maintenance';
      case FleetStatus.idle:
        return 'Idle';
    }
  }

  /// Get status color
  int get statusColor {
    switch (status) {
      case FleetStatus.onRoute:
        return 0xFF16A34A;
      case FleetStatus.delayed:
        return 0xFFF59E0B;
      case FleetStatus.maintenance:
        return 0xFFDC2626;
      case FleetStatus.idle:
        return 0xFF6B7280;
    }
  }

  /// Get status icon
  String get statusIcon {
    switch (status) {
      case FleetStatus.onRoute:
        return 'play_arrow';
      case FleetStatus.delayed:
        return 'warning_amber';
      case FleetStatus.maintenance:
        return 'build';
      case FleetStatus.idle:
        return 'pause_circle';
    }
  }

  /// Check if fuel level is low
  bool get isFuelLow => fuelPercent < 20;

  /// Check if fuel level is critical
  bool get isFuelCritical => fuelPercent < 10;

  /// Get fuel level color
  int get fuelColor {
    if (isFuelCritical) return 0xFFDC2626;
    if (isFuelLow) return 0xFFF59E0B;
    return 0xFF16A34A;
  }

  /// Get speed category
  String get speedCategory {
    if (speedMph < 10) return 'Slow';
    if (speedMph < 30) return 'Moderate';
    if (speedMph < 45) return 'Normal';
    return 'Fast';
  }

  BusFleet copyWith({
    String? busId,
    String? driverName,
    String? driverUid,
    String? driverPhone,
    String? routeName,
    String? estArrival,
    FleetStatus? status,
    int? speedMph,
    int? fuelPercent,
  }) {
    return BusFleet(
      busId: busId ?? this.busId,
      driverName: driverName ?? this.driverName,
      driverUid: driverUid ?? this.driverUid,
      driverPhone: driverPhone ?? this.driverPhone,
      routeName: routeName ?? this.routeName,
      estArrival: estArrival ?? this.estArrival,
      status: status ?? this.status,
      speedMph: speedMph ?? this.speedMph,
      fuelPercent: fuelPercent ?? this.fuelPercent,
    );
  }

  /// Serializes this bus for storage at /busesFleet/{busId} in Firebase.
  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'driverName': driverName,
      if (driverUid != null && driverUid!.trim().isNotEmpty)
        'driverUid': driverUid!.trim(),
      if (driverPhone != null && driverPhone!.trim().isNotEmpty)
        'driverPhone': driverPhone!.trim(),
      'routeName': routeName,
      'estArrival': estArrival,
      'status': status.name,
      'speedMph': speedMph,
      'fuelPercent': fuelPercent,
    };
  }

  /// Builds a BusFleet from a /busesFleet/{busId} Firebase snapshot.
  /// [busId] should be passed explicitly (the RTDB key), falling back to
  /// any 'busId' field inside the map itself.
  factory BusFleet.fromMap(Map<dynamic, dynamic> map, {String? busId}) {
    return BusFleet(
      busId: busId ?? (map['busId']?.toString() ?? ''),
      driverName: map['driverName']?.toString() ?? 'Unassigned',
      driverUid: map['driverUid']?.toString(),
      driverPhone: map['driverPhone']?.toString(),
      routeName: map['routeName']?.toString() ?? 'No route assigned',
      estArrival: map['estArrival']?.toString() ?? '--',
      status: fleetStatusFromString(map['status']?.toString()),
      speedMph: (map['speedMph'] is num) ? (map['speedMph'] as num).toInt() : 0,
      fuelPercent: (map['fuelPercent'] is num)
          ? (map['fuelPercent'] as num).toInt()
          : 100,
    );
  }
}

class StopInfo {
  final int stopNumber;
  final int totalStops;
  final String stopName;
  final String minsAway;

  StopInfo({
    required this.stopNumber,
    required this.totalStops,
    required this.stopName,
    required this.minsAway,
  });

  /// Get progress percentage
  double get progress => totalStops > 0 ? stopNumber / totalStops : 0.0;

  /// Check if this is the first stop
  bool get isFirst => stopNumber == 1;

  /// Check if this is the last stop
  bool get isLast => stopNumber == totalStops;
}
