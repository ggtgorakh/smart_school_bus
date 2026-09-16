// lib/services/notification_service.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';

/// Enhanced notification service with Firebase persistence and cross-device sync.
class NotificationService {
  NotificationService._() {
    _initializeListeners();
    _notificationStream = _buildNotificationStream();
  }

  static final NotificationService instance = NotificationService._();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier<List<AppNotification>>([]);

  late final Stream<List<AppNotification>> _notificationStream;

  StreamSubscription<DatabaseEvent>? _notificationsSubscription;
  StreamSubscription<User?>? _authSubscription;
  final Set<String> _pendingReadIds = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _requireUid() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Notification actions require an authenticated user.');
    }
    return uid;
  }

  String get _notificationsPath => 'notifications/$_uid';

  int get unreadCount =>
      notifications.value.where((n) => !n.isRead).length;

  /// Cached broadcast stream of the current user's notifications.
  Stream<List<AppNotification>> get notificationStream => _notificationStream;

  Stream<List<AppNotification>> _buildNotificationStream() {
    final controller =
        StreamController<List<AppNotification>>.broadcast();
    void listener() {
      if (!controller.isClosed) controller.add(notifications.value);
    }

    notifications.addListener(listener);
    controller.onListen = () {
      if (!controller.isClosed) controller.add(notifications.value);
    };
    return controller.stream;
  }

  void _initializeListeners() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      _notificationsSubscription?.cancel();
      _notificationsSubscription = null;
      if (user != null) {
        _listenToNotifications();
      } else {
        notifications.value = [];
      }
    });
  }

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

            updated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            notifications.value = updated;
          },
          onError: (error) {
            debugPrint('Notification listener error: $error');
          },
        );
  }

  /// Add a new notification (persists to Firebase).
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

    if (isSelfNotification) {
      final recentDuplicate = notifications.value.any(
        (n) =>
            ((eventKey != null &&
                    n.metadata?['eventKey']?.toString() == eventKey) ||
                (eventKey == null &&
                    n.title == title &&
                    n.message == message)) &&
            DateTime.now().difference(n.timestamp) <
                const Duration(minutes: 5),
      );
      if (recentDuplicate) return;
    }

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

    final notification = AppNotification(
      id: _db.child('notifications/$recipientUid').push().key!,
      kind: kind,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      busId: busId,
      studentId: studentId,
      metadata: {
        ...notificationMetadata,
        'role': role,
        'userId': senderUid,
      },
    );

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

  /// ─── BLOCK 8 ───────────────────────────────────────────────
  /// Public bulk helper: sends the same notification to a set of UIDs.
  /// Used by [AdminAlertService]. Best-effort: individual delivery
  /// failures are logged, not thrown, so a single bad UID can't abort
  /// the whole broadcast.
  ///
  /// Returns the number of successful deliveries.
  Future<int> broadcast({
    required List<String> recipientUids,
    required NotificationKind kind,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    if (recipientUids.isEmpty) return 0;
    var delivered = 0;
    for (final uid in recipientUids) {
      if (uid.trim().isEmpty) continue;
      try {
        await add(
          kind: kind,
          title: title,
          message: message,
          targetUid: uid.trim(),
          metadata: {
            ...?metadata,
            'broadcast': true,
          },
        );
        delivered++;
      } catch (e) {
        debugPrint('NotificationService.broadcast: failed for $uid: $e');
      }
    }
    return delivered;
  }

  Future<void> markAsRead(String id) async {
    _requireUid();

    AppNotification? target;
    for (final n in notifications.value) {
      if (n.id == id) {
        target = n;
        break;
      }
    }

    _pendingReadIds.add(id);
    notifications.value = notifications.value.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();

    if (target == null) {
      _pendingReadIds.remove(id);
      return;
    }

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

  Future<void> markAllAsRead() async {
    _requireUid();

    final ids =
        notifications.value.map((notification) => notification.id).toSet();
    _pendingReadIds.addAll(ids);

    notifications.value = notifications.value.map((n) {
      n.isRead = true;
      return n;
    }).toList();

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

  Future<void> deleteNotification(String id) async {
    _requireUid();

    notifications.value =
        notifications.value.where((n) => n.id != id).toList();

    try {
      await _db.child(_notificationsPath).child(id).remove();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Error deleting notification: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> clearAll() async {
    notifications.value = [];
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db.child('notifications/$uid').remove();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Error clearing notifications: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void clearSampleData() {
    notifications.value = [];
  }

  Future<void> dispose() async {
    await _notificationsSubscription?.cancel();
    await _authSubscription?.cancel();
    notifications.dispose();
  }

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

    final kind =
        isBoarding ? NotificationKind.boarding : NotificationKind.info;
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
}