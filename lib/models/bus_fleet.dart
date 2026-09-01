// lib/models/bus_fleet.dart

enum FleetStatus { onRoute, delayed, maintenance }

class BusFleet {
  final String busId;
  final String driverName;
  final String routeName;
  final String estArrival;
  final FleetStatus status;
  final int speedMph;
  final int fuelPercent;

  BusFleet({
    required this.busId,
    required this.driverName,
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
    String? routeName,
    String? estArrival,
    FleetStatus? status,
    int? speedMph,
    int? fuelPercent,
  }) {
    return BusFleet(
      busId: busId ?? this.busId,
      driverName: driverName ?? this.driverName,
      routeName: routeName ?? this.routeName,
      estArrival: estArrival ?? this.estArrival,
      status: status ?? this.status,
      speedMph: speedMph ?? this.speedMph,
      fuelPercent: fuelPercent ?? this.fuelPercent,
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