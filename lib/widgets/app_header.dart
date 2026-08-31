import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../screens/notifications_screen.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationPressed;
  final String? avatarUrl;

  const AppHeader({
    super.key,
    this.title = 'SchoolBus Safe',
    this.onNotificationPressed,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 18,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<List<AppNotification>>(
          valueListenable: NotificationService.instance.notifications,
          builder: (context, items, _) {
            final unreadCount = items.where((n) => !n.isRead).length;
            return Stack(
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: onNotificationPressed ??
                      () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          ),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: scheme.error,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.surface, width: 1.5),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        PopupMenuButton<ThemeMode>(
          tooltip: 'Choose theme',
          icon: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
          onSelected: ThemeController.instance.setMode,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: ThemeMode.light,
              child: Row(children: [Icon(Icons.light_mode_outlined, size: 18), SizedBox(width: 10), Text('Day theme')]),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: Row(children: [Icon(Icons.dark_mode_outlined, size: 18), SizedBox(width: 10), Text('Dark theme')]),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
