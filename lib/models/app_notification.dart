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

  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
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
      isRead: map['isRead'] ?? false,
      busId: map['busId'],
      studentId: map['studentId'],
      metadata: map['metadata'] as Map<String, dynamic>?,
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