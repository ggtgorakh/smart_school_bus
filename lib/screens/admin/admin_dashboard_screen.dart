// lib/screens/admin/admin_dashboard_screen.dart

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
                // Active fleet only — matches the Fleet Map tab and
                // hides unassigned / ghost buses.
                stream: FirebaseService.instance.streamActiveFleetLocations(),
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
    final stats = _computeStats(fleet, students, locations);

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
            SizedBox(
              height: 520,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: _mapCard(context, fleet, stats),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: _busListCard(context, fleet, stats),
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
            SizedBox(
              height: 320,
              child: _mapCard(context, fleet, stats),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 420,
              child: _busListCard(context, fleet, stats),
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

  Map<String, _BusStats> _computeStats(
    List<BusFleet> fleet,
    List<Student> students,
    Map<String, BusLocation> locations,
  ) {
    final byBus = <String, List<Student>>{};
    for (final s in students) {
      final busId = s.busId;
      if (busId == null || busId.isEmpty) continue;
      byBus.putIfAbsent(busId, () => []).add(s);
    }

    final result = <String, _BusStats>{};
    for (final bus in fleet) {
      final roster = byBus[bus.busId] ?? const <Student>[];
      final boarded = roster
          .where((s) => s.status == StudentStatus.boarded)
          .length;
      final alert = roster
          .where((s) => s.status == StudentStatus.alert)
          .length;
      final pending = roster
          .where((s) => s.status == StudentStatus.pending)
          .length;
      result[bus.busId] = _BusStats(
        busId: bus.busId,
        total: roster.length,
        boarded: boarded,
        pending: pending,
        alert: alert,
        location: locations[bus.busId],
      );
    }
    return result;
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
    // "Active" means assigned AND streaming (has a location record).
    final activeBuses = locations.length;
    final assigned =
        fleet.where((b) => b.driverName != 'Unassigned').length;
    final boarded =
        students.where((s) => s.status == StudentStatus.boarded).length;
    final stale = locations.values.where((l) => l.isStale()).length;

    final isMobile = !isLaptopPlatform();

    final cards = [
      _Kpi(
        label: 'Active Buses',
        value: '$activeBuses/$assigned',
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
        value: '$stale',
        icon: Icons.warning_amber_rounded,
        color: stale > 0 ? AppColors.alertOrange : AppColors.outline,
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
    List<BusFleet> fleet,
    Map<String, _BusStats> stats,
  ) {
    String primaryBusId = '';
    BusLocation? primaryLocation;

    final reporting = <MapEntry<String, BusLocation>>[];
    for (final entry in stats.entries) {
      final loc = entry.value.location;
      if (loc != null) reporting.add(MapEntry(entry.key, loc));
    }
    reporting.sort((a, b) => a.key.compareTo(b.key));

    if (reporting.isNotEmpty) {
      primaryBusId = reporting.first.key;
      primaryLocation = reporting.first.value;
    }

    final extraBuses = <ExtraBusMarker>[];
    for (final entry in reporting) {
      if (entry.key == primaryBusId) continue;
      final loc = entry.value;
      extraBuses.add(
        ExtraBusMarker(
          busId: entry.key,
          lat: loc.lat,
          lng: loc.lng,
          statusLabel: loc.statusLabel,
          isStale: loc.isStale(),
        ),
      );
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
                  '${reporting.length} reporting',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: LiveMapCanvas(
                lat: primaryLocation?.lat,
                lng: primaryLocation?.lng,
                busStatus: primaryLocation?.statusLabel ?? 'No buses',
                etaTime: primaryLocation?.etaLabel ?? '--',
                busNumber: primaryBusId.isEmpty
                    ? '--'
                    : primaryBusId.toUpperCase(),
                speedKmph: primaryLocation?.speedKmph ?? 0,
                stops: const [],
                currentStopIndex: -1,
                showInfoOverlay: false,
                showRecenterButton: false,
                additionalBuses: extraBuses,
                onExtraBusTap: (bus) => _showBusDetailsSheet(
                  context,
                  bus.busId,
                  stats[bus.busId],
                ),
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
    Map<String, _BusStats> stats,
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
                      final stat = stats[bus.busId];
                      final loc = stat?.location;
                      final color = switch (bus.status) {
                        FleetStatus.onRoute => AppColors.successGreen,
                        FleetStatus.delayed => AppColors.alertOrange,
                        FleetStatus.maintenance => AppColors.errorRed,
                        FleetStatus.idle => AppColors.outline,
                      };
                      final boarded = stat?.boarded ?? 0;
                      final total = stat?.total ?? 0;
                      final isAssigned =
                          bus.driverName != 'Unassigned';
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.circle, size: 12, color: color),
                        title: Row(
                          children: [
                            Text(
                              bus.busId.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!isAssigned) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.outline
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'IDLE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          isAssigned
                              ? '$total students • $boarded boarded'
                              : 'Unassigned',
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
                        onTap: () => _showBusDetailsSheet(
                          context,
                          bus.busId,
                          stat,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showBusDetailsSheet(
    BuildContext context,
    String busId,
    _BusStats? stat,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final total = stat?.total ?? 0;
        final boarded = stat?.boarded ?? 0;
        final pending = stat?.pending ?? 0;
        final alert = stat?.alert ?? 0;
        final loc = stat?.location;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            busId.toUpperCase(),
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            loc == null
                                ? 'Not reporting'
                                : '${loc.statusLabel} • ${loc.speedKmph.toStringAsFixed(0)} km/h',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _StatRow(
                  label: 'Total assigned',
                  value: '$total',
                  icon: Icons.group_rounded,
                  color: AppColors.safetyBlue,
                ),
                const SizedBox(height: 10),
                _StatRow(
                  label: 'Boarded',
                  value: '$boarded',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.successGreen,
                ),
                const SizedBox(height: 10),
                _StatRow(
                  label: 'Pending',
                  value: '$pending',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.alertOrange,
                ),
                const SizedBox(height: 10),
                _StatRow(
                  label: 'Flagged',
                  value: '$alert',
                  icon: Icons.error_outline_rounded,
                  color: AppColors.errorRed,
                ),
                if (total > 0) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : boarded / total,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.successGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    total == 0
                        ? 'No students assigned'
                        : '$boarded of $total boarded '
                            '(${((boarded / total) * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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

// ============================================================
// INTERNAL HELPERS
// ============================================================

class _BusStats {
  final String busId;
  final int total;
  final int boarded;
  final int pending;
  final int alert;
  final BusLocation? location;

  const _BusStats({
    required this.busId,
    required this.total,
    required this.boarded,
    required this.pending,
    required this.alert,
    required this.location,
  });
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
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