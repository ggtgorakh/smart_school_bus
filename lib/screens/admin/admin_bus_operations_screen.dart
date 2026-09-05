import 'package:flutter/material.dart';

import '../../models/bus_fleet.dart';
import '../../models/student.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class AdminBusOperationsScreen extends StatelessWidget {
  const AdminBusOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BusFleet>>(
      stream: FirebaseService.instance.streamFleet(),
      builder: (context, fleetSnapshot) {
        if (fleetSnapshot.hasError) {
          return Center(child: Text('Unable to load buses: ${fleetSnapshot.error}'));
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
            final boarded = students.where((s) => s.status == StudentStatus.boarded).length;
            final dispatched = buses.where((b) => b.status == FleetStatus.onRoute).length;
            final pending = students.where((s) => s.status == StudentStatus.pending).length;

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Bus Operations & Assignments',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
                      _Kpi(label: 'Total Buses', value: '${buses.length}', icon: Icons.directions_bus_rounded, color: AppColors.safetyBlue),
                      _Kpi(label: 'Dispatched', value: '$dispatched', icon: Icons.send_rounded, color: AppColors.successGreen),
                      _Kpi(label: 'Total Boarded', value: '$boarded', icon: Icons.how_to_reg_rounded, color: AppColors.successGreen),
                      _Kpi(label: 'Pending', value: '$pending', icon: Icons.pending_actions_rounded, color: AppColors.alertOrange),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...buses.map((bus) => _BusOperationCard(bus: bus)),
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

  const _BusOperationCard({required this.bus});

  Future<void> _editRoute(BuildContext context) async {
    final controller = TextEditingController(text: bus.routeName);
    final route = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage route for ${bus.busId.toUpperCase()}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Assigned route',
            hintText: 'Example: Route 7A - Morning Run',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (route == null || route.isEmpty || !context.mounted) return;

    try {
      await FirebaseService.instance.updateFleetStatus(
        bus.busId,
        bus.status,
        routeName: route,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route assignment updated.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update route: $error')),
        );
      }
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
              width: 210,
              child: Row(
                children: [
                  const Icon(Icons.directions_bus_rounded, color: AppColors.safetyBlue),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bus.busId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(bus.routeName, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            _Info(label: 'Driver', value: bus.driverName),
            _Info(label: 'Conductor', value: bus.conductorName ?? 'Unassigned'),
            _Info(label: 'Status', value: bus.statusLabel, color: statusColor),
            OutlinedButton.icon(
              onPressed: () => _editRoute(context),
              icon: const Icon(Icons.alt_route_rounded),
              label: const Text('Manage Route'),
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
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
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

  const _Kpi({required this.label, required this.value, required this.icon, required this.color});

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
                  Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
