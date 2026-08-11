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
}
