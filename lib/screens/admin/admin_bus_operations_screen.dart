// lib/screens/admin/admin_bus_operations_screen.dart

import 'package:flutter/material.dart';

import '../../models/bus_fleet.dart';
import '../../models/student.dart';
import '../../services/firebase_service.dart';
import '../../services/device_class_guard.dart';
import '../../theme/app_theme.dart';
import '../route_planning_screen.dart';
import 'emergency_log_screen.dart';

class AdminBusOperationsScreen extends StatelessWidget {
  const AdminBusOperationsScreen({super.key});

  bool get _laptop => isLaptopActionAllowed();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusFleet>>(
      stream: FirebaseService.instance.streamFleet(),
      builder: (context, fleetSnapshot) {
        if (fleetSnapshot.hasError) {
          return Center(
            child: Text('Unable to load buses: ${fleetSnapshot.error}'),
          );
        }
        if (!fleetSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<Student>>(
          stream: FirebaseService.instance.streamAllStudents(),
          builder: (context, studentSnapshot) {
            if (!studentSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final buses = fleetSnapshot.data!;
            final students = studentSnapshot.data!;
            final boarded = students
                .where((s) => s.status == StudentStatus.boarded)
                .length;
            final dispatched =
                buses.where((b) => b.status == FleetStatus.onRoute).length;
            final pending = students
                .where((s) => s.status == StudentStatus.pending)
                .length;

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                title: const Text(
                  'Bus Operations & Routes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Emergency log',
                    icon: const Icon(Icons.emergency_rounded),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmergencyLogScreen(),
                      ),
                    ),
                  ),
                  if (_laptop)
                    IconButton(
                      tooltip: 'Manage all routes',
                      icon: const Icon(Icons.alt_route_rounded),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RoutePlanningScreen(),
                        ),
                      ),
                    ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Bus Operations & Assignments',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage route assignments and monitor current boarding and dispatch totals.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _Kpi(
                        label: 'Total Buses',
                        value: '${buses.length}',
                        icon: Icons.directions_bus_rounded,
                        color: AppColors.safetyBlue,
                      ),
                      _Kpi(
                        label: 'Dispatched',
                        value: '$dispatched',
                        icon: Icons.send_rounded,
                        color: AppColors.successGreen,
                      ),
                      _Kpi(
                        label: 'Total Boarded',
                        value: '$boarded',
                        icon: Icons.how_to_reg_rounded,
                        color: AppColors.successGreen,
                      ),
                      _Kpi(
                        label: 'Pending',
                        value: '$pending',
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.alertOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...buses.map((bus) =>
                      _BusOperationCard(bus: bus, showManage: _laptop)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BusOperationCard extends StatelessWidget {
  final BusFleet bus;
  final bool showManage;

  const _BusOperationCard({required this.bus, required this.showManage});

  Future<void> _manageRoute(BuildContext context) async {
    final routes = await FirebaseService.instance.streamAllRoutes().first;
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.alt_route_rounded,
                      color: AppColors.safetyBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Assign route to ${bus.busId.toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (bus.routeId != null && bus.routeId!.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.link_off_rounded,
                    color: AppColors.errorRed,
                  ),
                  title: const Text('Clear route assignment'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    <String, dynamic>{'id': null, 'name': null},
                  ),
                ),
              if (routes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No routes exist yet. Tap "Create new route…" below.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              else
                ...routes.map(
                  (r) => ListTile(
                    leading: Icon(
                      r['id'] == bus.routeId
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: r['id'] == bus.routeId
                          ? AppColors.safetyBlue
                          : theme.colorScheme.outline,
                    ),
                    title: Text(
                      (r['name']?.toString() ?? 'Unnamed route'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${(r['stops'] is Map) ? (r['stops'] as Map).length : 0} stops',
                    ),
                    onTap: () => Navigator.pop(
                      sheetContext,
                      <String, dynamic>{
                        'id': r['id'],
                        'name': r['name'],
                      },
                    ),
                  ),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.add_rounded,
                  color: AppColors.safetyBlue,
                ),
                title: const Text('Create new route…'),
                onTap: () => Navigator.pop(
                  sheetContext,
                  <String, dynamic>{'create': true},
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;

    if (selected['create'] == true) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RoutePlanningScreen()),
      );
      return;
    }

    try {
      await FirebaseService.instance.assignRouteToBus(
        busId: bus.busId,
        routeId: selected['id'] as String?,
        routeName: selected['name'] as String?,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selected['id'] == null
                ? 'Route cleared for ${bus.busId.toUpperCase()}.'
                : 'Route assigned to ${bus.busId.toUpperCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update route: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (bus.status) {
      FleetStatus.onRoute => AppColors.successGreen,
      FleetStatus.delayed => AppColors.alertOrange,
      FleetStatus.maintenance => AppColors.errorRed,
      FleetStatus.idle => AppColors.outline,
    };

    final hasRoute = bus.routeId != null && bus.routeId!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 14,
          children: [
            SizedBox(
              width: 220,
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.safetyBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.busId.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          hasRoute ? bus.routeName : 'No route assigned',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontStyle: hasRoute
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _Info(label: 'Driver', value: bus.driverName),
            _Info(
              label: 'Conductor',
              value: bus.conductorName ?? 'Unassigned',
            ),
            _Info(
              label: 'Status',
              value: bus.statusLabel,
              color: statusColor,
            ),
            if (showManage)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _manageRoute(context),
                    icon: const Icon(Icons.alt_route_rounded),
                    label: Text(hasRoute ? 'Change Route' : 'Assign Route'),
                  ),
                  if (hasRoute)
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RoutePlanningScreen(routeId: bus.routeId),
                        ),
                      ),
                      icon: const Icon(
                        Icons.edit_location_alt_outlined,
                        size: 16,
                      ),
                      label: const Text('Edit Stops'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _Info({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
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
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}