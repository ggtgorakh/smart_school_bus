enum TripStatus { scheduled, preparing, active, paused, completed, cancelled }

TripStatus tripStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'preparing':
      return TripStatus.preparing;
    case 'active':
      return TripStatus.active;
    case 'paused':
      return TripStatus.paused;
    case 'completed':
      return TripStatus.completed;
    case 'cancelled':
      return TripStatus.cancelled;
    case 'scheduled':
    default:
      return TripStatus.scheduled;
  }
}

class Trip {
  final String tripId;
  final String busId;
  final String routeId;
  final String driverUid;
  final String? conductorUid;
  final DateTime? startTime;
  final DateTime? endTime;
  final TripStatus status;

  const Trip({
    required this.tripId,
    required this.busId,
    required this.routeId,
    required this.driverUid,
    this.conductorUid,
    this.startTime,
    this.endTime,
    required this.status,
  });

  bool get isOpen =>
      status != TripStatus.completed && status != TripStatus.cancelled;

  Trip copyWith({
    String? conductorUid,
    DateTime? startTime,
    DateTime? endTime,
    TripStatus? status,
  }) {
    return Trip(
      tripId: tripId,
      busId: busId,
      routeId: routeId,
      driverUid: driverUid,
      conductorUid: conductorUid ?? this.conductorUid,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
    'tripId': tripId,
    'busId': busId,
    'routeId': routeId,
    'driverUid': driverUid,
    if (conductorUid != null) 'conductorUid': conductorUid,
    if (startTime != null) 'startTime': startTime!.millisecondsSinceEpoch,
    if (endTime != null) 'endTime': endTime!.millisecondsSinceEpoch,
    'status': status.name,
  };

  factory Trip.fromMap(Map<dynamic, dynamic> map, {String? tripId}) {
    DateTime? parseTime(dynamic value) {
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return Trip(
      tripId: tripId ?? map['tripId']?.toString() ?? '',
      busId: map['busId']?.toString() ?? '',
      routeId: map['routeId']?.toString() ?? '',
      driverUid: map['driverUid']?.toString() ?? '',
      conductorUid: map['conductorUid']?.toString(),
      startTime: parseTime(map['startTime']),
      endTime: parseTime(map['endTime']),
      status: tripStatusFromString(map['status']?.toString()),
    );
  }

  static bool canTransition(TripStatus from, TripStatus to) {
    if (from == to) return true;
    switch (from) {
      case TripStatus.scheduled:
        return to == TripStatus.preparing || to == TripStatus.cancelled;
      case TripStatus.preparing:
        return to == TripStatus.active || to == TripStatus.cancelled;
      case TripStatus.active:
        return to == TripStatus.paused ||
            to == TripStatus.completed ||
            to == TripStatus.cancelled;
      case TripStatus.paused:
        return to == TripStatus.active ||
            to == TripStatus.completed ||
            to == TripStatus.cancelled;
      case TripStatus.completed:
      case TripStatus.cancelled:
        return false;
    }
  }
}
