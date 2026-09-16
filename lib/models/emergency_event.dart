// lib/models/emergency_event.dart

enum EmergencyStatus { active, acknowledged, resolved, cancelled }

EmergencyStatus emergencyStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'acknowledged':
      return EmergencyStatus.acknowledged;
    case 'resolved':
      return EmergencyStatus.resolved;
    case 'cancelled':
      return EmergencyStatus.cancelled;
    case 'active':
    default:
      return EmergencyStatus.active;
  }
}

class EmergencyEvent {
  final String eventId;
  final String actorUid;
  final String actorRole;
  final String? busId;
  final String? tripId;
  final double? lat;
  final double? lng;
  final String alertType;
  final String? description;
  final EmergencyStatus status;
  final DateTime timestamp;
  final DateTime? acknowledgedAt;
  final String? acknowledgedByUid;
  final DateTime? resolvedAt;
  final String? resolvedByUid;
  final String? resolutionNote;

  const EmergencyEvent({
    required this.eventId,
    required this.actorUid,
    required this.actorRole,
    this.busId,
    this.tripId,
    this.lat,
    this.lng,
    required this.alertType,
    this.description,
    required this.status,
    required this.timestamp,
    this.acknowledgedAt,
    this.acknowledgedByUid,
    this.resolvedAt,
    this.resolvedByUid,
    this.resolutionNote,
  });

  String get statusLabel {
    switch (status) {
      case EmergencyStatus.active:
        return 'Active';
      case EmergencyStatus.acknowledged:
        return 'Acknowledged';
      case EmergencyStatus.resolved:
        return 'Resolved';
      case EmergencyStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get coordinateLabel {
    if (lat == null || lng == null) return 'No GPS fix';
    return '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}';
  }

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'actorUid': actorUid,
        'actorRole': actorRole,
        if (busId != null) 'busId': busId,
        if (tripId != null) 'tripId': tripId,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'alertType': alertType,
        if (description != null) 'description': description,
        'status': status.name,
        'timestamp': timestamp.millisecondsSinceEpoch,
        if (acknowledgedAt != null)
          'acknowledgedAt': acknowledgedAt!.millisecondsSinceEpoch,
        if (acknowledgedByUid != null) 'acknowledgedByUid': acknowledgedByUid,
        if (resolvedAt != null)
          'resolvedAt': resolvedAt!.millisecondsSinceEpoch,
        if (resolvedByUid != null) 'resolvedByUid': resolvedByUid,
        if (resolutionNote != null) 'resolutionNote': resolutionNote,
      };

  factory EmergencyEvent.fromMap(
    Map<dynamic, dynamic> map, {
    String? eventId,
  }) {
    DateTime? parse(dynamic raw) {
      if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return EmergencyEvent(
      eventId: eventId ?? map['eventId']?.toString() ?? '',
      actorUid: map['actorUid']?.toString() ?? '',
      actorRole: map['actorRole']?.toString() ?? '',
      busId: map['busId']?.toString(),
      tripId: map['tripId']?.toString(),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      alertType: map['alertType']?.toString() ?? 'General',
      description: map['description']?.toString(),
      status: emergencyStatusFromString(map['status']?.toString()),
      timestamp: parse(map['timestamp']) ?? DateTime.now(),
      acknowledgedAt: parse(map['acknowledgedAt']),
      acknowledgedByUid: map['acknowledgedByUid']?.toString(),
      resolvedAt: parse(map['resolvedAt']),
      resolvedByUid: map['resolvedByUid']?.toString(),
      resolutionNote: map['resolutionNote']?.toString(),
    );
  }
}