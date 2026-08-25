import 'package:firebase_database/firebase_database.dart';
import '../models/bus_location.dart';

/// Thin wrapper around Firebase Realtime Database for the parent-facing
/// live tracking feature. Keeps all RTDB path/parsing knowledge in one
/// place so screens just consume a Stream<BusLocation?>.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  /// Streams live telemetry for [busId] from /buses/{busId}.
  ///
  /// Emits null if the node doesn't exist yet (e.g. ESP32 hasn't pushed
  /// its first reading since boot) so the UI can show a distinct
  /// "waiting for bus" state instead of a crash or a stale zero-value.
  Stream<BusLocation?> streamBusLocation(String busId) {
    return _root.child('buses/$busId').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      return BusLocation.fromMap(data);
    });
  }

  /// One-off read, useful for a manual refresh button or initial check
  /// before subscribing to the live stream.
  Future<BusLocation?> fetchBusLocationOnce(String busId) async {
    final snapshot = await _root.child('buses/$busId').get();
    final data = snapshot.value;
    if (data == null || data is! Map) return null;
    return BusLocation.fromMap(data);
  }
}
