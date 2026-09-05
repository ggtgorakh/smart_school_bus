// lib/models/app_notification.dart

enum NotificationKind {
  delay,
  arrival,
  boarding,
  alert,
  info,
  departure,
  emergency,
}

class AppNotification {
  final String id;
  final NotificationKind kind;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? busId;
  final String? studentId;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.busId,
    this.studentId,
    this.metadata,
  });

  /// Get human-readable kind label
  String get kindLabel {
    switch (kind) {
      case NotificationKind.delay:
        return 'Delayed';
      case NotificationKind.arrival:
        return 'Arrived';
      case NotificationKind.boarding:
        return 'Boarded';
      case NotificationKind.alert:
        return 'Alert';
      case NotificationKind.info:
        return 'Info';
      case NotificationKind.departure:
        return 'Departed';
      case NotificationKind.emergency:
        return 'Emergency';
    }
  }

  /// Get kind color
  int get kindColor {
    switch (kind) {
      case NotificationKind.delay:
        return 0xFFB45309;
      case NotificationKind.arrival:
        return 0xFF2563EB;
      case NotificationKind.boarding:
        return 0xFF16A34A;
      case NotificationKind.alert:
        return 0xFFB45309;
      case NotificationKind.info:
        return 0xFF64748B;
      case NotificationKind.departure:
        return 0xFF2563EB;
      case NotificationKind.emergency:
        return 0xFFDC2626;
    }
  }

  /// Get kind icon
  String get kindIcon {
    switch (kind) {
      case NotificationKind.delay:
        return 'schedule';
      case NotificationKind.arrival:
        return 'directions_bus';
      case NotificationKind.boarding:
        return 'face';
      case NotificationKind.alert:
        return 'warning_amber';
      case NotificationKind.info:
        return 'info';
      case NotificationKind.departure:
        return 'play_arrow';
      case NotificationKind.emergency:
        return 'sos';
    }
  }

  /// Get relative time string
  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  /// Check if notification is urgent
  bool get isUrgent {
    return kind == NotificationKind.emergency || kind == NotificationKind.alert;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kind': kind.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'busId': busId,
      'studentId': studentId,
      'metadata': metadata,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      kind: NotificationKind.values.firstWhere(
        (e) => e.name == map['kind'],
        orElse: () => NotificationKind.info,
      ),
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] is num
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'].toInt())
          : DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      isRead: map['isRead'] == true ||
          map['isRead']?.toString().toLowerCase() == 'true',
      busId: map['busId']?.toString(),
      studentId: map['studentId']?.toString(),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  AppNotification copyWith({
    String? id,
    NotificationKind? kind,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? busId,
    String? studentId,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      busId: busId ?? this.busId,
      studentId: studentId ?? this.studentId,
      metadata: metadata ?? this.metadata,
    );
  }
}