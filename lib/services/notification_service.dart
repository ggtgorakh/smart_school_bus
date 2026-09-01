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

  // Current user's UID
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

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
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _listenToNotifications();
      } else {
        notifications.value = [];
      }
    });

    // If already signed in, start listening
    if (FirebaseAuth.instance.currentUser != null) {
      _listenToNotifications();
    }
  }

  /// Listen to Firebase Realtime Database for notification changes
  void _listenToNotifications() {
    if (_uid == null) return;

    _db
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
                      Map<String, dynamic>.from(value as Map),
                    );
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

  /// Add a new notification (persists to Firebase)
  Future<void> add({
    required NotificationKind kind,
    required String title,
    required String message,
    String? busId,
    String? studentId,
    Map<String, dynamic>? metadata,
  }) async {
    if (_uid == null) return;

    // Deduplicate: prevent identical notifications within 3 seconds
    final recentDuplicate = notifications.value.any(
      (n) =>
          n.title == title &&
          n.message == message &&
          DateTime.now().difference(n.timestamp) < const Duration(seconds: 3),
    );

    if (recentDuplicate) return;

    // Get current user's role for context
    final roleSnapshot = await _db.child('users/$_uid/role').get();
    final role = roleSnapshot.value?.toString() ?? 'Parent';

    // Enhance notification with role-based context
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      kind: kind,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      busId: busId,
      studentId: studentId,
      metadata: {...?metadata, 'role': role, 'userId': _uid},
    );

    // Save to Firebase Realtime Database
    try {
      await _db
          .child(_notificationsPath)
          .child(notification.id)
          .set(notification.toMap());
    } catch (e) {
      debugPrint('Error saving notification: $e');
      // Fallback: add to local list only
      notifications.value = [notification, ...notifications.value];
    }
  }

  /// Mark a single notification as read (persists to Firebase)
  Future<void> markAsRead(String id) async {
    if (_uid == null) return;

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
    notifications.value = notifications.value.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();

    if (target == null) return;

    // Persist to Firebase — write the complete, now-updated record so the
    // write is self-sufficient regardless of whether it previously synced.
    try {
      await _db
          .child(_notificationsPath)
          .child(id)
          .set(target.copyWith(isRead: true).toMap());
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read (persists to Firebase)
  Future<void> markAllAsRead() async {
    if (_uid == null) return;

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
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification (persists to Firebase)
  Future<void> deleteNotification(String id) async {
    if (_uid == null) return;

    // Remove from local state
    notifications.value = notifications.value.where((n) => n.id != id).toList();

    // Remove from Firebase
    try {
      await _db.child(_notificationsPath).child(id).remove();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications (persists to Firebase)
  Future<void> clearAll() async {
    if (_uid == null) return;

    notifications.value = [];

    // Remove all from Firebase
    try {
      await _db.child(_notificationsPath).remove();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  /// Clear sample data (for testing)
  void clearSampleData() {
    notifications.value = [];
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
    String title;
    String message;
    NotificationKind kind;

    if (newStatus == 'delayed') {
      kind = NotificationKind.delay;
      title = '$busNumber is running late';
      message = 'Currently delayed. ETA: ${etaMinutes}m at $stopLabel';
    } else if (newStatus == 'arrived') {
      kind = NotificationKind.arrival;
      title = '$busNumber has arrived';
      message = 'Arrived at $stopLabel';
    } else if (newStatus == 'on_route' && oldStatus != 'on_route') {
      kind = NotificationKind.info;
      title = '$busNumber is now on route';
      message = 'Departed from previous stop. Next stop: $stopLabel';
    } else {
      kind = NotificationKind.info;
      title = '$busNumber status updated';
      message = 'Current status: $newStatus at $stopLabel';
    }

    await add(
      kind: kind,
      title: title,
      message: message,
      busId: busId,
      metadata: {
        'oldStatus': oldStatus,
        'newStatus': newStatus,
        'stopLabel': stopLabel,
        'etaMinutes': etaMinutes,
        'busNumber': busNumber,
      },
    );
  }

  /// Generate notification for student boarding event
  Future<void> notifyStudentBoarding({
    required String studentName,
    required String busId,
    required String busNumber,
    required String stopName,
    required bool isBoarding,
    required String? parentUid,
  }) async {
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
      studentId: parentUid,
      metadata: {
        'studentName': studentName,
        'stopName': stopName,
        'busNumber': busNumber,
        'isBoarding': isBoarding,
      },
    );
  }

  /// Generate notification for emergency alert
  Future<void> notifyEmergency({
    required String busId,
    required String busNumber,
    required String alertType,
    required String description,
    List<String>? recipientRoles,
  }) async {
    final title = '🚨 Emergency Alert - $busNumber';
    final message = '$alertType: $description';

    await add(
      kind: NotificationKind.emergency,
      title: title,
      message: message,
      busId: busId,
      metadata: {
        'alertType': alertType,
        'description': description,
        'severity': 'high',
        'recipientRoles': recipientRoles ?? ['Admin', 'Driver'],
      },
    );
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
