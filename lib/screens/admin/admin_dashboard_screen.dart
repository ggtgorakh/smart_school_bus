// lib/screens/admin/admin_dashboard_screen.dart
//
// Landing screen for the Admin role. On laptop it shows KPIs, a real map
// with all active buses, a bus list with status, and recent activity. On
// mobile it shows the same content in a stacked, read-only layout.

import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../models/bus_fleet.dart';
import '../../models/bus_location.dart';
import '../../models/student.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_utils.dart';
import '../../widgets/live_map_canvas.dart';
import '../admin_fleet_tracking_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final laptop = isLaptopPlatform();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<BusFleet>>(
        stream: FirebaseService.instance.streamFleet(),
        builder: (context, fleetSnap) {
          final fleet = fleetSnap.data ?? const <BusFleet>[];
          return StreamBuilder<List<Student>>(
            stream: FirebaseService.instance.streamAllStudents(),
            builder: (context, studentSnap) {
              final students = studentSnap.data ?? const <Student>[];
              return StreamBuilder<Map<String, BusLocation>>(
                stream: FirebaseService.instance.streamAllBusLocations(),
                builder: (context, locSnap) {
                  final locations =
                      locSnap.data ?? const <String, BusLocation>{};
                  return _buildContent(
                    context,
                    fleet,
                    students,
                    locations,
                    laptop,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<BusFleet> fleet,
    List<Student> students,
    Map<String, BusLocation> locations,
    bool laptop,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(laptop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: 16),
          _kpiRow(context, fleet, students, locations),
          const SizedBox(height: 16),
          if (laptop) ...[
            // Laptop: side-by-side, fixed heights so IntrinsicHeight is
            // not required and Expanded has a bound.
            SizedBox(
              height: 520,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: _mapCard(context, locations),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: _busListCard(context, fleet, locations),
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _activityCard(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Mobile: stack with explicit heights so nothing tries to
            // expand into infinite vertical space.
            SizedBox(
              height: 320,
              child: _mapCard(context, locations),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 420,
              child: _busListCard(context, fleet, locations),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: _activityCard(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.dashboard_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'Live overview of the fleet, students, and active alerts.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kpiRow(
    BuildContext context,
    List<BusFleet> fleet,
    List<Student> students,
    Map<String, BusLocation> locations,
  ) {
    final activeBuses =
        fleet.where((b) => b.status == FleetStatus.onRoute).length;
    final boarded =
        students.where((s) => s.status == StudentStatus.boarded).length;
    final alerts = locations.values.where((l) => l.isStale()).length;

    final isMobile = !isLaptopPlatform();

    final cards = [
      _Kpi(
        label: 'Active Buses',
        value: '$activeBuses/${fleet.length}',
        icon: Icons.directions_bus_rounded,
        color: AppColors.successGreen,
      ),
      _Kpi(
        label: 'Students Boarded',
        value: '$boarded',
        icon: Icons.how_to_reg_rounded,
        color: AppColors.safetyBlue,
      ),
      _Kpi(
        label: 'Stale Trackers',
        value: '$alerts',
        icon: Icons.warning_amber_rounded,
        color: alerts > 0 ? AppColors.alertOrange : AppColors.outline,
      ),
      _Kpi(
        label: 'Reporting',
        value: '${locations.length}',
        icon: Icons.gps_fixed_rounded,
        color: AppColors.safetyBlue,
      ),
    ];

    if (isMobile) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards.map((c) => SizedBox(width: 170, child: c)).toList(),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _mapCard(
    BuildContext context,
    Map<String, BusLocation> locations,
  ) {
    BusLocation? selected;
    String selectedId = '';
    if (locations.isNotEmpty) {
      final sorted = locations.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      selectedId = sorted.first.key;
      selected = sorted.first.value;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.map_rounded, color: AppColors.safetyBlue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Live Fleet Map',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${locations.length} reporting',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // The map must have a bounded height or FlutterMap will throw.
          // Expanded is fine *here* because it's inside a Column whose
          // parent (this Card) is itself inside a SizedBox with an
          // explicit height from _buildContent.
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: LiveMapCanvas(
                lat: selected?.lat,
                lng: selected?.lng,
                busStatus: selected?.statusLabel ?? 'No buses',
                etaTime: selected?.etaLabel ?? '--',
                busNumber:
                    selectedId.isEmpty ? '--' : selectedId.toUpperCase(),
                speedKmph: selected?.speedKmph ?? 0,
                stops: const [],
                currentStopIndex: -1,
                showInfoOverlay: false,
                showRecenterButton: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _busListCard(
    BuildContext context,
    List<BusFleet> fleet,
    Map<String, BusLocation> locations,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.safetyBlue,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Fleet Status',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (isLaptopPlatform())
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminFleetTrackingScreen(),
                      ),
                    ),
                    child: const Text('Open full map'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: fleet.isEmpty
                ? const Center(child: Text('No buses configured yet.'))
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: fleet.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final bus = fleet[i];
                      final loc = locations[bus.busId];
                      final color = switch (bus.status) {
                        FleetStatus.onRoute => AppColors.successGreen,
                        FleetStatus.delayed => AppColors.alertOrange,
                        FleetStatus.maintenance => AppColors.errorRed,
                        FleetStatus.idle => AppColors.outline,
                      };
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.circle, size: 12, color: color),
                        title: Text(
                          bus.busId.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${bus.routeName} • ${bus.statusLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: loc == null
                            ? const Text(
                                '—',
                                style: TextStyle(fontSize: 12),
                              )
                            : Text(
                                '${loc.speedKmph.toStringAsFixed(0)} km/h',
                                style: const TextStyle(fontSize: 12),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _activityCard(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.notifications_rounded, color: AppColors.safetyBlue),
                SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder<List<AppNotification>>(
              valueListenable: NotificationService.instance.notifications,
              builder: (context, items, _) {
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No recent activity'),
                    ),
                  );
                }
                final recent = items.take(5).toList();
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: recent.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final n = recent[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        _iconFor(n.kind),
                        color: Color(n.kindColor),
                        size: 20,
                      ),
                      title: Text(
                        n.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        n.relativeTime,
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.arrival:
        return Icons.directions_bus_rounded;
      case NotificationKind.boarding:
        return Icons.face_rounded;
      case NotificationKind.delay:
      case NotificationKind.alert:
        return Icons.warning_amber_rounded;
      case NotificationKind.emergency:
        return Icons.sos_rounded;
      case NotificationKind.departure:
        return Icons.play_arrow_rounded;
      case NotificationKind.info:
        return Icons.info_outline_rounded;
    }
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}