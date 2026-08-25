import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/live_map_canvas.dart';

// 1. Define a Data Model for the stops
class RouteStop {
  final String time;
  final String name;
  final int studentsCount;
  final bool isCompleted;
  final bool isCurrent;

  const RouteStop({
    required this.time,
    required this.name,
    this.studentsCount = 0,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}

class RoutePlanningScreen extends StatelessWidget {
  const RoutePlanningScreen({super.key});

  // 2. Define your list of data (Replace this with Firebase data later)
  static const List<RouteStop> mockStops = [
    RouteStop(
      time: '07:30 AM',
      name: 'Depot Departure (Central Station)',
      isCompleted: true,
    ),
    RouteStop(
      time: '07:45 AM',
      name: 'Stop 1: Pine & 5th Avenue',
      studentsCount: 4,
      isCompleted: true,
    ),
    RouteStop(
      time: '08:00 AM',
      name: 'Stop 2: Elm Street & Park Rd',
      studentsCount: 6,
      isCompleted: true,
    ),
    RouteStop(
      time: '08:14 AM',
      name: 'Stop 3: Oak St & Maple Ave',
      studentsCount: 5,
      isCurrent: true,
    ),
    RouteStop(
      time: '08:28 AM',
      name: 'Stop 4: Sycamore Lane',
      studentsCount: 3,
    ),
    RouteStop(
      time: '08:45 AM',
      name: 'Destination: Oakridge Elementary',
      studentsCount: 18,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pass the total stops to the header dynamically
              _buildPageHeader(context, totalStops: mockStops.length),

              const SizedBox(height: 16),

              // Map preview
              Container(
                height: 220,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.surfaceContainerHighest,
                  ),
                ),
                child: const LiveMapCanvas(
                  busStatus: 'Planned Route',
                  etaTime: '07:30 AM Start',
                  busNumber: 'Route 7A',
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Stop Schedule Timeline',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textMain,
                ),
              ),

              const SizedBox(height: 12),

              // 3. Pass the dynamic list to the timeline builder
              _buildTimelineCard(mockStops),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, {required int totalStops}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Planning',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Route 7A - Oakridge Elementary Morning Run',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        );

        final stopsBadge = Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: AppColors.safetyBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_bus,
                size: 16,
                color: AppColors.safetyBlue,
              ),
              const SizedBox(width: 6),
              Text(
                '$totalStops Stops Active', // Dynamic count
                style: const TextStyle(
                  color: AppColors.safetyBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

        if (isSmallScreen) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 10),
              stopsBadge,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 12),
            stopsBadge,
          ],
        );
      },
    );
  }

  // 4. Generate UI from the list of models automatically
  Widget _buildTimelineCard(List<RouteStop> stops) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceContainerHighest,
        ),
      ),
      child: Column(
        children: List.generate(stops.length, (index) {
          final stop = stops[index];
          return _buildTimelineItem(
            time: stop.time,
            stopName: stop.name,
            studentsCount: stop.studentsCount,
            isCompleted: stop.isCompleted,
            isCurrent: stop.isCurrent,
            isFirst: index == 0,
            isLast: index == stops.length - 1,
          );
        }),
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
    final Color nodeColor = isCompleted
        ? AppColors.safetyBlue
        : isCurrent
        ? AppColors.alertOrange
        : AppColors.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time
        SizedBox(
          width: 68,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? AppColors.alertOrange : AppColors.textMain,
                fontSize: 12,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Timeline Node/Line
        SizedBox(
          width: 16,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: nodeColor,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: isCurrent
                      ? [
                    BoxShadow(
                      color: AppColors.alertOrange.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ]
                      : null,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 48,
                  color: isCompleted
                      ? AppColors.safetyBlue
                      : AppColors.surfaceContainerHighest,
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Stop details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stopName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrent || isCompleted
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                    height: 1.25,
                    color: AppColors.textMain,
                  ),
                ),
                if (studentsCount > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    '$studentsCount students pick-up',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}