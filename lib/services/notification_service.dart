import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

/// Simple in-app notification center. Not a push-notification service —
/// this drives the bell icon + notifications screen from things that
/// happen inside the app (bus status changes, boarding events, etc).
///
/// A ValueNotifier keeps this dependency-free (no provider/riverpod
/// needed) while still letting any widget rebuild on change via
/// ValueListenableBuilder.
class NotificationService {
  NotificationService._() {
    _seedSampleData();
  }
  static final NotificationService instance = NotificationService._();

  final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier<List<AppNotification>>([]);

  int get unreadCount =>
      notifications.value.where((n) => !n.isRead).length;

  void add({
    required NotificationKind kind,
    required String title,
    required String message,
  }) {
    // Dedupe: multiple mounted screens can watch the same live data (e.g.
    // two nav tabs both rendering LiveTrackingScreen via IndexedStack), so
    // the same real-world event can trigger add() more than once in quick
    // succession. Drop it if an identical notification just landed.
    final recentDuplicate = notifications.value.any((n) =>
        n.title == title &&
        n.message == message &&
        DateTime.now().difference(n.timestamp) < const Duration(seconds: 3));
    if (recentDuplicate) return;

    final notification = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      kind: kind,
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    notifications.value = [notification, ...notifications.value];
  }

  void markAsRead(String id) {
    notifications.value = notifications.value.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();
  }

  void markAllAsRead() {
    notifications.value = notifications.value.map((n) {
      n.isRead = true;
      return n;
    }).toList();
  }

  void clear() {
    notifications.value = [];
  }

  void _seedSampleData() {
    final now = DateTime.now();
    notifications.value = [
      AppNotification(
        id: 's1',
        kind: NotificationKind.boarding,
        title: 'Sarah boarded the bus',
        message: 'Checked in at Elm Street stop.',
        timestamp: now.subtract(const Duration(minutes: 22)),
        isRead: false,
      ),
      AppNotification(
        id: 's2',
        kind: NotificationKind.delay,
        title: 'Bus 42 running late',
        message: 'Currently 6 minutes behind schedule due to traffic.',
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      AppNotification(
        id: 's3',
        kind: NotificationKind.arrival,
        title: 'Bus arrived at school',
        message: 'Bus 42 arrived safely at Lincoln Elementary.',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }
}
