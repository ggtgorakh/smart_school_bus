import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A horizontal, metro-line-style progress track showing stops already
/// passed, the current position, and stops still to come.
///
/// This is the app's one recurring signature element — used in the Live
/// Tracking bottom sheet and echoed (in a compact form) on the Profile
/// screen — so the "where is the bus, right now" idea has a single
/// consistent visual language across the app.
class RouteProgressTrack extends StatelessWidget {
  final int totalStops;
  final int currentStopIndex; // 0-based index of the stop just reached/next
  final String currentStopLabel;
  final String etaLabel;
  final bool compact;

  const RouteProgressTrack({
    super.key,
    required this.totalStops,
    required this.currentStopIndex,
    required this.currentStopLabel,
    required this.etaLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = compact ? 8.0 : 10.0;
    final lineHeight = compact ? 3.0 : 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalStops * 2 - 1, (i) {
            // Even indices are stops, odd indices are the connecting segments.
            if (i.isEven) {
              final stopIdx = i ~/ 2;
              final isDone = stopIdx < currentStopIndex;
              final isCurrent = stopIdx == currentStopIndex;
              return Container(
                width: isCurrent ? dotSize + 6 : dotSize,
                height: isCurrent ? dotSize + 6 : dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isCurrent
                      ? AppColors.trackComplete
                      : AppColors.trackPending,
                  border: isCurrent
                      ? Border.all(
                          color: AppColors.alertOrange, width: 2.5)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppColors.alertOrange.withValues(alpha: 0.35),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              );
            } else {
              final segmentIdx = i ~/ 2;
              final isDone = segmentIdx < currentStopIndex;
              return Expanded(
                child: Container(
                  height: lineHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.trackComplete
                        : AppColors.trackPending,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }
          }),
        ),
        if (!compact) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentStopLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textMain,
                      ),
                ),
              ),
              Text(
                etaLabel,
                style: AppTheme.tabularTime(
                  fontSize: 13,
                  color: AppColors.alertOrangeDark,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
