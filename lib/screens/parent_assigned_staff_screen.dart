import 'package:flutter/material.dart';

import '../models/bus_fleet.dart';
import '../models/student.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class ParentAssignedStaffScreen extends StatelessWidget {
  const ParentAssignedStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.instance.currentUserUid;
    if (uid == null) {
      return const Center(child: Text('Please sign in to view assigned staff.'));
    }

    return StreamBuilder<List<Student>>(
      stream: FirebaseService.instance.streamChildrenForParent(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Unable to load assigned staff.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final children = snapshot.data!;
        if (children.isEmpty) {
          return const Center(child: Text('No linked children are available.'));
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Assigned Staff',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                'Driver and conductor information for each child’s current bus assignment.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...children.map((child) => _ChildStaffCard(child: child)),
          ],
        );
      },
    );
  }
}

class _ChildStaffCard extends StatelessWidget {
  final Student child;

  const _ChildStaffCard({required this.child});

  @override
  Widget build(BuildContext context) {
    if (child.busId == null || child.busId!.trim().isEmpty) {
      return _MessageCard(
        title: child.name,
        message: 'No bus is currently assigned to this child.',
        icon: Icons.directions_bus_outlined,
      );
    }

    return StreamBuilder<BusFleet?>(
      stream: FirebaseService.instance.streamFleetBus(child.busId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MessageCard(
            title: child.name,
            message: 'Unable to load this bus staff assignment.',
            icon: Icons.error_outline_rounded,
          );
        }
        if (!snapshot.hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Loading staff for ${child.name}...')),
                ],
              ),
            ),
          );
        }

        final bus = snapshot.data;
        if (bus == null) {
          return _MessageCard(
            title: child.name,
            message: 'No current staff assignment is available.',
            icon: Icons.groups_outlined,
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.child_care_rounded, color: AppColors.safetyBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        child.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      bus.busId.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _StaffTile(
                  title: 'Driver',
                  name: bus.driverName,
                  employeeId: bus.driverUid,
                  phone: bus.driverPhone,
                  status: bus.statusLabel,
                  icon: Icons.drive_eta_rounded,
                  color: AppColors.alertOrange,
                ),
                const SizedBox(height: 10),
                _StaffTile(
                  title: 'Conductor',
                  name: bus.conductorName ?? 'Not assigned',
                  employeeId: bus.conductorUid,
                  phone: bus.conductorPhone,
                  status: bus.statusLabel,
                  icon: Icons.badge_rounded,
                  color: AppColors.successGreen,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StaffTile extends StatelessWidget {
  final String title;
  final String name;
  final String? employeeId;
  final String? phone;
  final String status;
  final IconData icon;
  final Color color;

  const _StaffTile({
    required this.title,
    required this.name,
    required this.employeeId,
    required this.phone,
    required this.status,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        phone?.trim().isNotEmpty == true
                            ? phone!.trim()
                            : 'Mobile number not available',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Employee ID: ${employeeId?.trim().isNotEmpty == true ? employeeId : 'Not available'} • $status',
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
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _MessageCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: AppColors.safetyBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(message),
      ),
    );
  }
}
