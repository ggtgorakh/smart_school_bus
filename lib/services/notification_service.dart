import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_notification.dart';

/// Enhanced notification service with Firebase persistence and cross-device sync
class NotificationService {
  NotificationService._() {
    _initializeListeners();
  }

  static final NotificationService instance = NotificationService._();

  // Firebase Realtime Database reference
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // In-memory notification list
  final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier<List<AppNotification>>([]);
  StreamSubscription<DatabaseEvent>? _notificationsSubscription;
  StreamSubscription<User?>? _authSubscription;
  final Set<String> _pendingReadIds = {};

  // Current user's UID
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _requireUid() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Notification actions require an authenticated user.');
    }
    return uid;
  }

  // Notification path in Firebase: /notifications/{uid}/{notificationId}
  String get _notificationsPath => 'notifications/$_uid';

  // Unread count getter
  int get unreadCount => notifications.value.where((n) => !n.isRead).length;

  /// Stream for real-time updates - FIXED
  Stream<List<AppNotification>> get notificationStream {
    // Create a broadcast stream controller
    final controller = StreamController<List<AppNotification>>.broadcast();

    // Add listener to ValueNotifier
    VoidCallback listener = () {
      if (!controller.isClosed) {
        controller.add(notifications.value);
      }
    };

    notifications.addListener(listener);

    // Clean up when controller is disposed
    controller.onCancel = () {
      notifications.removeListener(listener);
    };

    // Add initial value
    controller.add(notifications.value);

    return controller.stream;
  }

  /// Initialize Firebase listeners for real-time notification sync
  void _initializeListeners() {
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _notificationsSubscription?.cancel();
      _notificationsSubscription = null;
      if (user != null) {
        _listenToNotifications();
      } else {
        notifications.value = [];
      }
    });
  }

  /// Listen to Firebase Realtime Database for notification changes
  void _listenToNotifications() {
    if (_uid == null) return;

    _notificationsSubscription = _db
        .child(_notificationsPath)
        .onValue
        .listen(
          (event) {
            final raw = event.snapshot.value;
            final List<AppNotification> updated = [];

            if (raw is Map) {
              raw.forEach((key, value) {
                if (value is Map) {
                  try {
                    final notification = AppNotification.fromMap(
                      Map<String, dynamic>.from(value),
                    );
                    if (_pendingReadIds.contains(notification.id)) {
                      notification.isRead = true;
                    }
                    updated.add(notification);
                  } catch (e) {
                    debugPrint('Error parsing notification: $e');
                  }
                }
              });
            }

            // Sort by timestamp (newest first)
            updated.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            notifications.value = updated;
          },
          onError: (error) {
            debugPrint('Notification listener error: $error');
          },
        );
  }

  /// Add a new notification (persists to Firebase).
  ///
  /// By default this writes to the CURRENT user's own notification list
  /// (`notifications/{currentUid}`). Pass [targetUid] to instead deliver the
  /// notification to a *different* user — e.g. a driver notifying a parent
  /// that their child boarded. When [targetUid] is used, the notification is
  /// written directly (it will not appear in this instance's in-memory
  /// `notifications` list, since that list only mirrors the signed-in
  /// user's own node).
  Future<void> add({
    required NotificationKind kind,
    required String title,
    required String message,
    String? busId,
    String? studentId,
    Map<String, dynamic>? metadata,
    String? targetUid,
    String? eventKey,
  }) async {
    final senderUid = _uid;
    if (senderUid == null) {
      throw StateError(
        'Cannot save a notification without an authenticated user.',
      );
    }

    final normalizedTargetUid = targetUid?.trim();
    if (targetUid != null &&
        (normalizedTargetUid == null || normalizedTargetUid.isEmpty)) {
      throw ArgumentError.value(targetUid, 'targetUid', 'must not be empty');
    }

    final recipientUid = normalizedTargetUid ?? senderUid;
    final isSelfNotification = recipientUid == senderUid;
    final notificationMetadata = <String, dynamic>{
      ...?metadata,
      ...?(eventKey == null ? null : {'eventKey': eventKey}),
    };

    // Deduplicate: prevent identical notifications within five minutes
    // (only meaningful for self-notifications, since that's the only case
    // where we have the recipient's existing list in memory).
    if (isSelfNotification) {
      final recentDuplicate = notifications.value.any(
        (n) =>
            ((eventKey != null &&
                    n.metadata?['eventKey']?.toString() == eventKey) ||
                (eventKey == null &&
                    n.title == title &&
                    n.message == message)) &&
            DateTime.now().difference(n.timestamp) < const Duration(minutes: 5),
      );
      if (recentDuplicate) return;
    }

    // Get current user's role for context
    late final String role;
    try {
      final roleSnapshot = await _db.child('users/$senderUid/role').get();
      role = roleSnapshot.value?.toString() ?? 'Parent';
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Unable to determine notification sender role: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }

    if (!isSelfNotification &&
        role != 'Admin' &&
        role != 'Driver' &&
        role != 'Conductor') {
      throw StateError(
        'This account is not authorized to notify another user.',
      );
    }

    // Enhance notification with role-based context
    final notification = AppNotification(
      id: _db.child('notifications/$recipientUid').push().key!,
      kind: kind,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      busId: busId,
      studentId: studentId,
      metadata: {...notificationMetadata, 'role': role, 'userId': senderUid},
    );

    // Save to Firebase Realtime Database
    try {
      await _db
          .child('notifications/$recipientUid')
          .child(notification.id)
          .set(notification.toMap());
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Error saving notification for $recipientUid: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Mark a single notification as read (persists to Firebase)
  Future<void> markAsRead(String id) async {
    _requireUid();

    // Find the notification locally so we can write its full record —
    // writing just the `isRead` leaf assumes the complete record already
    // exists in Firebase. If it doesn't (e.g. the original `add()` call
    // failed and fell back to local-only storage), a lone `isRead` field
    // fails the server's `hasChildren([...])` validation rule and gets
    // rejected as permission-denied.
    AppNotification? target;
    for (final n in notifications.value) {
      if (n.id == id) {
        target = n;
        break;
      }
    }

    // Update local state immediately for UI responsiveness
    _pendingReadIds.add(id);
    notifications.value = notifications.value.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();

    if (target == null) {
      _pendingReadIds.remove(id);
      return;
    }

    // Persist to Firebase — write the complete, now-updated record so the
    // write is self-sufficient regardless of whether it previously synced.
    try {
      await _db
          .child(_notificationsPath)
          .child(id)
          .set(target.copyWith(isRead: true).toMap());
      _pendingReadIds.remove(id);
    } on FirebaseException catch (error, stackTrace) {
      _pendingReadIds.remove(id);
      debugPrint('Error marking notification as read: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Mark all notifications as read (persists to Firebase)
  Future<void> markAllAsRead() async {
    _requireUid();

    final ids = notifications.value.map((notification) => notification.id).toSet();
    _pendingReadIds.addAll(ids);

    // Update local state
    notifications.value = notifications.value.map((n) {
      n.isRead = true;
      return n;
    }).toList();

    // Bulk update in Firebase — write each notification's complete record
    // (not just the `isRead` leaf) so any notification that never fully
    // synced still satisfies the server's hasChildren validation rule.
    try {
      final updates = <String, dynamic>{};
      for (final n in notifications.value) {
        updates[n.id] = n.copyWith(isRead: true).toMap();
      }
      await _db.child(_notificationsPath).update(updates);
      _pendingReadIds.removeAll(ids);
    } on FirebaseException catch (error, stackTrace) {
      _pendingReadIds.removeAll(ids);
      debugPrint('Error marking all notifications as read: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Delete a notification (persists to Firebase)
  Future<void> deleteNotification(String id) async {
    _requireUid();

    // Remove from local state
    notifications.value = notifications.value.where((n) => n.id != id).toList();

    // Remove from Firebase
    try {
      await _db.child(_notificationsPath).child(id).remove();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Error deleting notification: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Clear all notifications (persists to Firebase)
  Future<void> clearAll() async {
    notifications.value = [];
    final uid = _uid;
    if (uid == null) return;

    // Remove all from Firebase
    try {
      await _db.child('notifications/$uid').remove();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Error clearing notifications: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Clear sample data (for testing)
  void clearSampleData() {
    notifications.value = [];
  }

  Future<void> dispose() async {
    await _notificationsSubscription?.cancel();
    await _authSubscription?.cancel();
    notifications.dispose();
  }

  /// Generate notification for bus status change
  Future<void> notifyBusStatusChange({
    required String busId,
    required String busNumber,
    required String oldStatus,
    required String newStatus,
    required String stopLabel,
    required int etaMinutes,
  }) async {
    final normalizedOldStatus = _normalizeStatus(oldStatus);
    final normalizedNewStatus = _normalizeStatus(newStatus);
    if (normalizedOldStatus == normalizedNewStatus) return;

    String title;
    String message;
    NotificationKind kind;

    if (normalizedNewStatus == 'delayed') {
      kind = NotificationKind.delay;
      title = '$busNumber is running late';
      message = 'Currently delayed. ETA: ${etaMinutes}m at $stopLabel';
    } else if (normalizedNewStatus == 'arrived') {
      kind = NotificationKind.arrival;
      title = '$busNumber has arrived';
      message = 'Arrived at $stopLabel';
    } else if (normalizedNewStatus == 'on_route' &&
        normalizedOldStatus != 'on_route') {
      kind = NotificationKind.departure;
      title = '$busNumber has departed';
      message = 'Departed from the previous stop. Next stop: $stopLabel';
    } else {
      return;
    }

    await add(
      kind: kind,
      title: title,
      message: message,
      busId: busId,
      eventKey:
          'bus-status:$busId:$normalizedOldStatus:$normalizedNewStatus:$stopLabel',
      metadata: {
        'oldStatus': normalizedOldStatus,
        'newStatus': normalizedNewStatus,
        'stopLabel': stopLabel,
        'etaMinutes': etaMinutes,
        'busNumber': busNumber,
      },
    );
  }

  String _normalizeStatus(String status) {
    switch (status) {
      case 'onRoute':
      case 'on_route':
        return 'on_route';
      default:
        return status;
    }
  }

  /// Notify once when a bus stops reporting telemetry, or when it resumes.
  Future<void> notifyTrackerStale({
    required String busId,
    required String busNumber,
    required bool isStale,
    required DateTime lastUpdated,
  }) {
    final kind = isStale ? NotificationKind.alert : NotificationKind.info;
    final title = isStale
        ? '$busNumber tracking signal is stale'
        : '$busNumber tracking signal restored';
    final message = isStale
        ? 'No location update received since ${lastUpdated.toLocal()}'
        : 'Live location updates have resumed.';
    return add(
      kind: kind,
      title: title,
      message: message,
      busId: busId,
      eventKey: 'tracker-stale:$busId:${isStale ? 'stale' : 'restored'}',
      metadata: {
        'isStale': isStale,
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      },
    );
  }

  /// Generate notification for student boarding event, delivered to the
  /// linked parent's own notification list (not the calling driver's).
  Future<void> notifyStudentBoarding({
    required String studentName,
    required String busId,
    required String busNumber,
    required String stopName,
    required bool isBoarding,
    required String? parentUid,
    String? studentId,
  }) async {
    if (parentUid == null || parentUid.trim().isEmpty) return;

    final kind = isBoarding ? NotificationKind.boarding : NotificationKind.info;
    final title = isBoarding
        ? '$studentName boarded the bus'
        : '$studentName got off the bus';
    final message = isBoarding
        ? 'Checked in at $stopName on $busNumber'
        : 'Checked out at $stopName on $busNumber';

    await add(
      kind: kind,
      title: title,
      message: message,
      busId: busId,
      studentId: studentId,
      targetUid: parentUid,
      metadata: {
        'studentName': studentName,
        'stopName': stopName,
        'busNumber': busNumber,
        'isBoarding': isBoarding,
      },
    );
  }

  /// Generate an emergency alert and deliver it to each UID in
  /// [recipientUids] (in addition to the caller). Looking recipients up by
  /// role here isn't possible client-side — reading the full `/users` list
  /// is Admin-only under the database rules — so the caller (which already
  /// knows the relevant Admins/Drivers for this bus, e.g. from the fleet
  /// roster it has loaded) must supply the UIDs to notify.
  Future<void> notifyEmergency({
    required String busId,
    required String busNumber,
    required String alertType,
    required String description,
    List<String>? recipientRoles,
    List<String> recipientUids = const [],
  }) async {
    final title = '🚨 Emergency Alert - $busNumber';
    final message = '$alertType: $description';
    final metadata = {
      'alertType': alertType,
      'description': description,
      'severity': 'high',
      'recipientRoles': recipientRoles ?? ['Admin', 'Driver'],
    };

    // Always notify the caller themselves, plus every explicit recipient.
    final targets = <String>{...recipientUids};
    if (_uid != null) targets.add(_uid!);

    for (final uid in targets) {
      await add(
        kind: NotificationKind.emergency,
        title: title,
        message: message,
        busId: busId,
        metadata: metadata,
        targetUid: uid,
      );
    }
  }

  /// Get unread count as a stream for real-time updates - FIXED
  Stream<int> getUnreadCountStream() {
    final controller = StreamController<int>.broadcast();

    VoidCallback listener = () {
      if (!controller.isClosed) {
        final count = notifications.value.where((n) => !n.isRead).length;
        controller.add(count);
      }
    };

    notifications.addListener(listener);

    controller.onCancel = () {
      notifications.removeListener(listener);
    };

    // Add initial value
    controller.add(unreadCount);

    return controller.stream;
  }
}
