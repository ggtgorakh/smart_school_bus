import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/live_map_canvas.dart';

class RoutePlanningScreen extends StatelessWidget {
  const RoutePlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Planning',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                    ),
                    Text(
                      'Route 7A - Oakridge Elementary Morning Run',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.safetyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.directions_bus,
                          size: 16, color: AppColors.safetyBlue),
                      SizedBox(width: 6),
                      Text(
                        '8 Stops Active',
                        style: TextStyle(
                          color: AppColors.safetyBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Map preview box
            Container(
              height: 220,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerHighest),
              ),
              child: const LiveMapCanvas(
                busStatus: 'Planned Route',
                etaTime: '07:30 AM Start',
                busNumber: 'Route 7A',
              ),
            ),
            const SizedBox(height: 20),

            // Schedule Timeline Section
            Text(
              'Stop Schedule Timeline',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textMain,
                  ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerHighest),
              ),
              child: Column(
                children: [
                  _buildTimelineItem(
                    time: '07:30 AM',
                    stopName: 'Depot Departure (Central Station)',
                    studentsCount: 0,
                    isCompleted: true,
                    isFirst: true,
                  ),
                  _buildTimelineItem(
                    time: '07:45 AM',
                    stopName: 'Stop 1: Pine & 5th Avenue',
                    studentsCount: 4,
                    isCompleted: true,
                  ),
                  _buildTimelineItem(
                    time: '08:00 AM',
                    stopName: 'Stop 2: Elm Street & Park Rd',
                    studentsCount: 6,
                    isCompleted: true,
                  ),
                  _buildTimelineItem(
                    time: '08:14 AM',
                    stopName: 'Stop 3: Oak St & Maple Ave',
                    studentsCount: 5,
                    isCurrent: true,
                  ),
                  _buildTimelineItem(
                    time: '08:28 AM',
                    stopName: 'Stop 4: Sycamore Lane',
                    studentsCount: 3,
                  ),
                  _buildTimelineItem(
                    time: '08:45 AM',
                    stopName: 'Destination: Oakridge Elementary',
                    studentsCount: 18,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String stopName,
    required int studentsCount,
    bool isCompleted = false,
    bool isCurrent = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    Color nodeColor = isCompleted
        ? AppColors.safetyBlue
        : isCurrent
            ? AppColors.alertOrange
            : AppColors.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time column
        SizedBox(
          width: 70,
          child: Text(
            time,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent ? AppColors.alertOrange : AppColors.textMain,
              fontSize: 13,
            ),
          ),
        ),
        // Timeline Line & Node
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: nodeColor,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.alertOrange.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? AppColors.safetyBlue
                    : AppColors.surfaceContainerHighest,
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Stop details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stopName,
                style: TextStyle(
                  fontWeight:
                      isCurrent || isCompleted ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                  color: AppColors.textMain,
                ),
              ),
              if (studentsCount > 0)
                Text(
                  '$studentsCount students pick-up',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
