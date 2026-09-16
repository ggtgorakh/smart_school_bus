// lib/config/school_config.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Static, in-code defaults for the school's configuration.
///
/// At runtime, the app prefers values loaded from `/config/school` in
/// Firebase (editable from the Admin laptop dashboard). If a value is
/// missing or the read fails, we fall back to these constants so the UI
/// always has something sensible to render.
class SchoolConfig {
  final String shortName;
  final String fullName;
  final String address;
  final String phone;
  final String email;
  final String transportCoordinatorName;
  final String transportCoordinatorPhone;
  final String emergencyNumber;
  final String medicalEmergencyNumber;
  final String academicYear;
  final String appTagline;
  final double latitude;
  final double longitude;

  const SchoolConfig({
    required this.shortName,
    required this.fullName,
    required this.address,
    required this.phone,
    required this.email,
    required this.transportCoordinatorName,
    required this.transportCoordinatorPhone,
    required this.emergencyNumber,
    required this.medicalEmergencyNumber,
    required this.academicYear,
    required this.appTagline,
    required this.latitude,
    required this.longitude,
  });

  /// Defaults for the Amravati deployment. Any of these can be overridden
  /// at runtime from the Admin config screen without a code change.
  static const SchoolConfig defaults = SchoolConfig(
    shortName: 'Edify Amravati',
    fullName: 'Edify School Amravati',
    address:
        'Survey No. 112, Kathora, Chandurbazar Road, Amravati, Maharashtra – 444602',
    phone: '+91 9511914901',
    email: 'info@edifyschoolamravati.com',
    transportCoordinatorName: 'Transport Coordinator',
    transportCoordinatorPhone: '+91 00000 00000',
    emergencyNumber: '112',
    medicalEmergencyNumber: '108',
    academicYear: '2025–2026',
    appTagline: 'Safe • Tracked • Connected',
    latitude: 21.0040687,
    longitude: 77.7539332,
  );

  SchoolConfig copyWith({
    String? shortName,
    String? fullName,
    String? address,
    String? phone,
    String? email,
    String? transportCoordinatorName,
    String? transportCoordinatorPhone,
    String? emergencyNumber,
    String? medicalEmergencyNumber,
    String? academicYear,
    String? appTagline,
    double? latitude,
    double? longitude,
  }) {
    return SchoolConfig(
      shortName: shortName ?? this.shortName,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      transportCoordinatorName:
          transportCoordinatorName ?? this.transportCoordinatorName,
      transportCoordinatorPhone:
          transportCoordinatorPhone ?? this.transportCoordinatorPhone,
      emergencyNumber: emergencyNumber ?? this.emergencyNumber,
      medicalEmergencyNumber:
          medicalEmergencyNumber ?? this.medicalEmergencyNumber,
      academicYear: academicYear ?? this.academicYear,
      appTagline: appTagline ?? this.appTagline,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() => {
        'shortName': shortName,
        'fullName': fullName,
        'address': address,
        'phone': phone,
        'email': email,
        'transportCoordinatorName': transportCoordinatorName,
        'transportCoordinatorPhone': transportCoordinatorPhone,
        'emergencyNumber': emergencyNumber,
        'medicalEmergencyNumber': medicalEmergencyNumber,
        'academicYear': academicYear,
        'appTagline': appTagline,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory SchoolConfig.fromMap(Map<dynamic, dynamic> map) {
    String readString(String key, String fallback) {
      final v = map[key];
      if (v == null) return fallback;
      final s = v.toString().trim();
      return s.isEmpty ? fallback : s;
    }

    double readDouble(String key, double fallback) {
      final v = map[key];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    return SchoolConfig(
      shortName: readString('shortName', defaults.shortName),
      fullName: readString('fullName', defaults.fullName),
      address: readString('address', defaults.address),
      phone: readString('phone', defaults.phone),
      email: readString('email', defaults.email),
      transportCoordinatorName: readString(
        'transportCoordinatorName',
        defaults.transportCoordinatorName,
      ),
      transportCoordinatorPhone: readString(
        'transportCoordinatorPhone',
        defaults.transportCoordinatorPhone,
      ),
      emergencyNumber:
          readString('emergencyNumber', defaults.emergencyNumber),
      medicalEmergencyNumber: readString(
        'medicalEmergencyNumber',
        defaults.medicalEmergencyNumber,
      ),
      academicYear: readString('academicYear', defaults.academicYear),
      appTagline: readString('appTagline', defaults.appTagline),
      latitude: readDouble('latitude', defaults.latitude),
      longitude: readDouble('longitude', defaults.longitude),
    );
  }
}

/// Process-wide holder for the current [SchoolConfig].
///
/// `main.dart` hydrates this once at startup with a synchronous default;
/// then it subscribes to `/config/school` and updates the in-memory copy
/// whenever the Admin changes config on any device.
class SchoolConfigController extends ChangeNotifier {
  SchoolConfigController._();
  static final SchoolConfigController instance = SchoolConfigController._();

  SchoolConfig _config = SchoolConfig.defaults;
  SchoolConfig get config => _config;

  /// Replace the current config (used for both initial load and live
  /// updates from the Firebase stream).
  void hydrate(SchoolConfig config) {
    _config = config;
    notifyListeners();
  }

  /// Push the current in-memory config to Firebase. Admin-only.
  /// On success, the local value stays; the stream will echo it back.
  Future<void> pushRemote() async {
    await FirebaseDatabase.instance
        .ref('config/school')
        .update(_config.toMap());
  }
}