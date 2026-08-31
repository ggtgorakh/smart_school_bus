// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../widgets/notification_badge.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _service = NotificationService.instance;
  late AnimationController _animationController;
  String _filterType = 'all';
  bool _isLoading = false;

  final List<Map<String, String>> _filterOptions = [
    {'key': 'all', 'label': 'All', 'icon': '📋'},
    {'key': 'delay', 'label': 'Delayed', 'icon': '⏰'},
    {'key': 'arrival', 'label': 'Arrived', 'icon': '✅'},
    {'key': 'boarding', 'label': 'Boarding', 'icon': '🚌'},
    {'key': 'departure', 'label': 'Departed', 'icon': '🚀'},
    {'key': 'emergency', 'label': 'Emergency', 'icon': '🚨'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
      case NotificationKind.departure:
        return Icons.play_arrow_rounded;
      case NotificationKind.emergency:
        return Icons.sos_rounded;
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
      case NotificationKind.departure:
        return AppColors.safetyBlue;
      case NotificationKind.emergency:
        return AppColors.errorRed;
    }
  }

  String _labelFor(NotificationKind kind) {
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

  List<AppNotification> _filterNotifications(List<AppNotification> items) {
    if (_filterType == 'all') return items;
    return items.where((n) => n.kind.name == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: ValueListenableBuilder<List<AppNotification>>(
              valueListenable: _service.notifications,
              builder: (context, items, _) {
                final filteredItems = _filterNotifications(items);
                final unreadCount = items.where((n) => !n.isRead).length;

                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                if (filteredItems.isEmpty) {
                  return _buildEmptyFilterState();
                }

                return RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final notification = filteredItems[index];
                      final isLast = index == filteredItems.length - 1;

                      return FadeTransition(
                        opacity: Tween<double>(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index / filteredItems.length * 0.6,
                              1.0,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.3, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                index / filteredItems.length * 0.6,
                                1.0,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: isLast ? 0 : 12,
                            ),
                            child: _NotificationCard(
                              notification: notification,
                              onTap: () => _service.markAsRead(notification.id),
                              onDismiss: () => _service.deleteNotification(notification.id),
                              icon: _iconFor(notification.kind),
                              color: _colorFor(notification.kind),
                              kindLabel: _labelFor(notification.kind),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        // Unread count badge
        ValueListenableBuilder<List<AppNotification>>(
          valueListenable: _service.notifications,
          builder: (context, items, _) {
            final unread = items.where((n) => !n.isRead).length;
            if (unread == 0) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.alertOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unread new',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        IconButton(
          onPressed: _service.markAllAsRead,
          icon: const Icon(Icons.done_all_rounded),
          tooltip: 'Mark all as read',
        ),
        IconButton(
          onPressed: _showDeleteDialog,
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'Clear all',
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) {
            final isSelected = _filterType == filter['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(filter['icon'] ?? ''),
                    const SizedBox(width: 4),
                    Text(filter['label'] ?? ''),
                  ],
                ),
                onSelected: (_) {
                  setState(() {
                    _filterType = filter['key'] ?? 'all';
                  });
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: AppColors.safetyBlue.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.safetyBlue
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.safetyBlue
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Notifications will appear here when bus status changes or students board the bus.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_filterType} notifications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different filter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _filterType = 'all'),
            child: const Text('Show all notifications'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isLoading = false);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.errorRed,
            ),
            const SizedBox(width: 8),
            const Text('Clear all notifications?'),
          ],
        ),
        content: const Text(
          'This action cannot be undone. All notifications will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _service.clearAll();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final IconData icon;
  final Color color;
  final String kindLabel;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    required this.icon,
    required this.color,
    required this.kindLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: Material(
        color: notification.isRead
            ? Colors.transparent
            : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: notification.isRead
                    ? Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.2),
                width: notification.isRead ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: isDark ? 0.1 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    fontSize: 14,
                                    color: notification.isRead
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildBadge(
                            context,
                            kindLabel,
                            color,
                          ),
                          _buildBadge(
                            context,
                            notification.relativeTime,
                            Theme.of(context).colorScheme.onSurfaceVariant,
                            icon: Icons.schedule_rounded,
                          ),
                          if (notification.busId != null)
                            _buildBadge(
                              context,
                              notification.busId!,
                              AppColors.safetyBlue,
                              icon: Icons.directions_bus_rounded,
                            ),
                          if (notification.metadata?['stopLabel'] != null)
                            _buildBadge(
                              context,
                              notification.metadata!['stopLabel'].toString(),
                              AppColors.alertOrangeDark,
                              icon: Icons.location_on_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context,
    String label,
    Color color, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: color,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}