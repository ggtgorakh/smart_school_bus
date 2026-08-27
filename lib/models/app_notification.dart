enum NotificationKind { delay, arrival, boarding, alert, info }

class AppNotification {
  final String id;
  final NotificationKind kind;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
