import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

      // Notification button
      actions: [
        SizedBox(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No new notifications'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.safetyBlue,
                  size: 26,
                ),
              ),

              // Notification indicator
              Positioned(
                right: 7,
                top: 10,
                child: IgnorePointer(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.alertOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}