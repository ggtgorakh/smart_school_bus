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
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      toolbarHeight: kToolbarHeight,

      title: Row(
        children: [
          // App logo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.brandGradient,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.safetyBlue.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: avatarUrl != null
                  ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.directions_bus_filled_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.directions_bus_filled_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Responsive title
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),

      // Notification button — real unread badge, opens NotificationsScreen.
      actions: [
        ValueListenableBuilder<List<AppNotification>>(
          valueListenable: NotificationService.instance.notifications,
          builder: (context, items, _) {
            final unreadCount = items.where((n) => !n.isRead).length;

            return SizedBox(
              width: 48,
              height: kToolbarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: onNotificationPressed ??
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.safetyBlue,
                      size: 26,
                    ),
                  ),

                  // Unread badge — only shown when there's something unread.
                  if (unreadCount > 0)
                    Positioned(
                      right: 4,
                      top: 6,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.alertOrange,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}