import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final double? progress;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.badgeText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppTheme.panelDecoration(context),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface)),
                const SizedBox(height: 2),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                if (progress != null) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.safetyBlue),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(7)),
            child: Text(badgeText, style: TextStyle(color: badgeTextColor, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
