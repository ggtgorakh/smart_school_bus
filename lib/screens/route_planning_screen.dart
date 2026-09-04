// lib/screens/route_planning_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/live_map_canvas.dart';
import '../services/firebase_service.dart';

// Data Model for stops
class RouteStop {
  final String time;
  final String name;
  final int studentsCount;
  final bool isCompleted;
  final bool isCurrent;
  final String? eta;
  final String? statusMessage;

  const RouteStop({
    required this.time,
    required this.name,
    this.studentsCount = 0,
    this.isCompleted = false,
    this.isCurrent = false,
    this.eta,
    this.statusMessage,
  });

  RouteStop copyWith({
    String? time,
    String? name,
    int? studentsCount,
    bool? isCompleted,
    bool? isCurrent,
    String? eta,
    String? statusMessage,
  }) {
    return RouteStop(
      time: time ?? this.time,
      name: name ?? this.name,
      studentsCount: studentsCount ?? this.studentsCount,
      isCompleted: isCompleted ?? this.isCompleted,
      isCurrent: isCurrent ?? this.isCurrent,
      eta: eta ?? this.eta,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  Map<String, dynamic> toMap(int order) => {
    'order': order,
    'time': time,
    'name': name,
    'studentsCount': studentsCount,
    'isCompleted': isCompleted,
    'isCurrent': isCurrent,
    if (eta != null) 'eta': eta,
    if (statusMessage != null) 'statusMessage': statusMessage,
  };

  factory RouteStop.fromMap(Map<dynamic, dynamic> map) => RouteStop(
    time: map['time']?.toString() ?? '',
    name: map['name']?.toString() ?? 'Unnamed stop',
    studentsCount: (map['studentsCount'] as num?)?.toInt() ?? 0,
    isCompleted: map['isCompleted'] == true,
    isCurrent: map['isCurrent'] == true,
    eta: map['eta']?.toString(),
    statusMessage: map['statusMessage']?.toString(),
  );
}

class RoutePlanningScreen extends StatefulWidget {
  const RoutePlanningScreen({super.key});

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _selectedView = 'timeline'; // 'timeline' or 'map'
  static const _routeId = 'route_7a_morning';
  StreamSubscription<List<Map<String, dynamic>>>? _routeSubscription;

  static List<RouteStop> _stops = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
    _routeSubscription = FirebaseService.instance
        .streamRouteStops(_routeId)
        .listen((items) {
          if (!mounted || items.isEmpty) return;
          setState(() => _stops = items.map(RouteStop.fromMap).toList());
        });
  }

  @override
  void dispose() {
    _routeSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),

                // View Selector
                _buildViewSelector(),

                // Content
                Expanded(
                  child: _selectedView == 'timeline'
                      ? _buildTimelineView(context)
                      : _buildMapView(context),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final isMobile = context.isMobile;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route 7A - Morning Run',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 17 : 20,
                  ),
                ),
                Text(
                  'Oakridge Elementary • ${_stops.length} stops • ${_getTotalStudents()} students',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VIEW SELECTOR
  // ============================================================

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _buildViewOption('Timeline', 'timeline', Icons.timeline_rounded),
            _buildViewOption('Map', 'map', Icons.map_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOption(String label, String value, IconData icon) {
    final isSelected = _selectedView == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedView = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.safetyBlue
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.safetyBlue
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TIMELINE VIEW
  // ============================================================

  Widget _buildTimelineView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Summary
          _buildProgressSummary(),
          const SizedBox(height: 16),

          // Stop Timeline
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _stops.asMap().entries.map((entry) {
                final index = entry.key;
                final stop = entry.value;
                return _buildTimelineItem(
                  context,
                  stop: stop,
                  index: index,
                  isFirst: index == 0,
                  isLast: index == _stops.length - 1,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Route Stats
          _buildRouteStats(),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS SUMMARY
  // ============================================================

  Widget _buildProgressSummary() {
    final completedCount = _stops.where((s) => s.isCompleted).length;
    final totalCount = _stops.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.safetyBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Route Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completedCount / $totalCount',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Complete',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIMELINE ITEM
  // ============================================================

  Widget _buildTimelineItem(
    BuildContext context, {
    required RouteStop stop,
    required int index,
    required bool isFirst,
    required bool isLast,
  }) {
    final Color nodeColor = stop.isCompleted
        ? AppColors.successGreen
        : stop.isCurrent
        ? AppColors.alertOrange
        : AppColors.outlineVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showStopDetails(context, stop),
      child: Padding(
        padding: EdgeInsets.only(top: index == 0 ? 0 : 8, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Column
            SizedBox(
              width: 70,
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  stop.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: stop.isCurrent
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: stop.isCurrent
                        ? AppColors.alertOrange
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Timeline Node
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: nodeColor,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: stop.isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.alertOrange.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: stop.isCompleted
                          ? AppColors.successGreen
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Stop Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: stop.isCurrent || stop.isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                        height: 1.25,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (stop.studentsCount > 0)
                          _buildChip(
                            icon: Icons.people_rounded,
                            label: '${stop.studentsCount} students',
                            color: AppColors.safetyBlue,
                          ),
                        if (stop.eta != null)
                          _buildChip(
                            icon: Icons.timer_rounded,
                            label: stop.eta!,
                            color: AppColors.alertOrange,
                          ),
                        if (stop.statusMessage != null)
                          _buildChip(
                            icon: stop.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.info_rounded,
                            label: stop.statusMessage!,
                            color: stop.isCompleted
                                ? AppColors.successGreen
                                : AppColors.alertOrange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Status Icon
            if (stop.isCompleted)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successGreen,
                size: 20,
              )
            else if (stop.isCurrent)
              const Icon(
                Icons.navigation_rounded,
                color: AppColors.alertOrange,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROUTE STATS
  // ============================================================

  Widget _buildRouteStats() {
    final totalStudents = _getTotalStudents();
    final completedStops = _stops.where((s) => s.isCompleted).length;
    final remainingStops = _stops.length - completedStops;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.school_rounded,
            label: 'Total Students',
            value: '$totalStudents',
            color: AppColors.safetyBlue,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            icon: Icons.check_circle_rounded,
            label: 'Completed Stops',
            value: '$completedStops',
            color: AppColors.successGreen,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            icon: Icons.timer_rounded,
            label: 'Remaining',
            value: '$remainingStops',
            color: AppColors.alertOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAP VIEW
  // ============================================================

  Widget _buildMapView(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: const LiveMapCanvas(
          busStatus: 'Planned Route',
          etaTime: '07:30 AM Start',
          busNumber: 'Route 7A',
          progress: 0.4,
          speedKmph: 0,
        ),
      ),
    );
  }

  // ============================================================
  // FLOATING ACTION BUTTON
  // ============================================================

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddStopDialog(),
      backgroundColor: AppColors.safetyBlue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Stop'),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ============================================================
  // DIALOGS
  // ============================================================

  void _showStopDetails(BuildContext context, RouteStop stop) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(
              stop.isCompleted
                  ? Icons.check_circle_rounded
                  : stop.isCurrent
                  ? Icons.navigation_rounded
                  : Icons.location_on_rounded,
              color: stop.isCompleted
                  ? AppColors.successGreen
                  : stop.isCurrent
                  ? AppColors.alertOrange
                  : AppColors.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(stop.name, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Scheduled Time', stop.time),
            if (stop.studentsCount > 0)
              _buildDetailRow('Students', '${stop.studentsCount}'),
            if (stop.eta != null) _buildDetailRow('ETA', stop.eta!),
            if (stop.statusMessage != null)
              _buildDetailRow('Status', stop.statusMessage!),
            _buildDetailRow(
              'Status',
              stop.isCompleted
                  ? '✅ Completed'
                  : stop.isCurrent
                  ? '🟠 In Progress'
                  : '⏳ Scheduled',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          if (!stop.isCompleted)
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() {
                  final index = _stops.indexOf(stop);
                  _stops = _stops.map((s) {
                    if (s == stop) {
                      return s.copyWith(isCompleted: true, isCurrent: false);
                    }
                    return s;
                  }).toList();
                  // Mark next stop as current
                  if (index + 1 < _stops.length) {
                    _stops = _stops.map((s) {
                      if (_stops.indexOf(s) == index + 1) {
                        return s.copyWith(isCurrent: true);
                      }
                      return s;
                    }).toList();
                  }
                });
                await _persistStops();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.safetyBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark Complete'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStopDialog() {
    final nameController = TextEditingController();
    final timeController = TextEditingController();
    final studentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.add_location_rounded, color: AppColors.safetyBlue),
            const SizedBox(width: 8),
            const Text('Add New Stop'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Stop Name',
                hintText: 'e.g. Main Street & 5th Ave',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'e.g. 08:30 AM',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: studentsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Students Count',
                hintText: 'e.g. 5',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _stops.add(
                    RouteStop(
                      time: timeController.text.isNotEmpty
                          ? timeController.text
                          : '--:--',
                      name: nameController.text,
                      studentsCount: int.tryParse(studentsController.text) ?? 0,
                    ),
                  );
                });
                await _persistStops();
                Navigator.of(ctx).pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.safetyBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Stop'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _getTotalStudents() {
    return _stops.fold(0, (sum, stop) => sum + stop.studentsCount);
  }

  Future<void> _persistStops() async {
    await Future.wait([
      for (var index = 0; index < _stops.length; index++)
        FirebaseService.instance.saveRouteStop(
          _routeId,
          'stop_${index + 1}',
          _stops[index].toMap(index),
        ),
    ]);
  }
}
