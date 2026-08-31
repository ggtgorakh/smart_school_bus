// lib/widgets/notification_badge.dart

import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationBadge extends StatelessWidget {
  final VoidCallback onTap;

  const NotificationBadge({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AppNotification>>(
      valueListenable: NotificationService.instance.notifications,
      builder: (context, items, _) {
        final unreadCount = items.where((n) => !n.isRead).length;
        final hasUnread = unreadCount > 0;

        return Stack(
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: onTap,
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(hasUnread ? 6 : 8),
                decoration: BoxDecoration(
                  color: hasUnread
                      ? AppColors.safetyBlue.withValues(alpha: 0.08)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasUnread
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: hasUnread ? AppColors.safetyBlue : null,
                  size: 24,
                ),
              ),
            ),
            if (hasUnread)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: AppColors.alertOrange,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}