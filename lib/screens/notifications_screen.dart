import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.delay:
        return Icons.schedule_rounded;
      case NotificationKind.arrival:
        return Icons.directions_bus_filled_rounded;
      case NotificationKind.boarding:
        return Icons.face_rounded;
      case NotificationKind.alert:
        return Icons.warning_amber_rounded;
      case NotificationKind.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _colorFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.delay:
        return AppColors.alertOrangeDark;
      case NotificationKind.arrival:
        return AppColors.safetyBlue;
      case NotificationKind.boarding:
        return AppColors.successGreen;
      case NotificationKind.alert:
        return AppColors.alertOrangeDark;
      case NotificationKind.info:
        return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
        ),
        actions: [
          TextButton(
            onPressed: service.markAllAsRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<AppNotification>>(
        valueListenable: service.notifications,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 48, color: AppColors.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final n = items[index];
              return Material(
                color: n.isRead
                    ? Colors.white
                    : AppColors.safetyBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => service.markAsRead(n.id),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _colorFor(n.kind).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconFor(n.kind),
                              color: _colorFor(n.kind), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                              fontWeight: n.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.bold,
                                              fontSize: 14),
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin:
                                          const EdgeInsets.only(left: 6, top: 2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.alertOrange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.message,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 12.5),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.relativeTime,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: AppColors.outline,
                                        fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
