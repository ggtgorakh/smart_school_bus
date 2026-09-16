// lib/screens/parent_absence_screen.dart
//
// Parent-facing "Child absent today" feature. Uses
// StudentAbsenceService to write or clear a day-key on
// /studentAbsences/{busId}/{studentId}/{yyyy-mm-dd}.

import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/firebase_service.dart';
import '../services/student_absence_service.dart';
import '../theme/app_theme.dart';

class ParentAbsenceScreen extends StatefulWidget {
  const ParentAbsenceScreen({super.key});

  @override
  State<ParentAbsenceScreen> createState() => _ParentAbsenceScreenState();
}

class _ParentAbsenceScreenState extends State<ParentAbsenceScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.instance.currentUserUid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in.')),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text(
          'Report Absence',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: StreamBuilder<List<Student>>(
        stream: FirebaseService.instance.streamChildrenForParent(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load children: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.safetyBlue),
            );
          }
          final children = snapshot.data!;
          if (children.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No children are linked to this account yet.'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Mark your child absent for today if they will not be taking '
                'the bus. The driver and conductor will see this before they '
                'reach the stop.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (final child in children)
                _ChildAbsenceCard(child: child),
            ],
          );
        },
      ),
    );
  }
}

class _ChildAbsenceCard extends StatelessWidget {
  final Student child;
  const _ChildAbsenceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final busId = child.busId;
    if (busId == null || busId.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(
            Icons.directions_bus_outlined,
            color: AppColors.outline,
          ),
          title: Text(child.name),
          subtitle: const Text('No bus assigned yet'),
        ),
      );
    }
    return StreamBuilder<bool>(
      stream: StudentAbsenceService.instance.streamAbsentToday(
        busId: busId,
        studentId: child.id,
      ),
      builder: (context, snap) {
        final absent = snap.data ?? false;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          AppColors.safetyBlue.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.child_care_rounded,
                        color: AppColors.safetyBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${child.grade} • Stop: ${child.stopName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: absent
                        ? AppColors.amberSoft
                        : AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: absent
                          ? AppColors.alertOrange.withValues(alpha: 0.4)
                          : AppColors.successGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        absent
                            ? Icons.event_busy_rounded
                            : Icons.check_circle_rounded,
                        color: absent
                            ? AppColors.alertOrangeDark
                            : AppColors.successGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          absent
                              ? 'Marked absent today'
                              : 'Expected on the bus today',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: absent
                                ? AppColors.alertOrangeDark
                                : AppColors.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: absent
                            ? null
                            : () => _mark(context, busId, child.id),
                        icon: const Icon(Icons.event_busy_rounded, size: 16),
                        label: const Text('Mark absent today'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.alertOrangeDark,
                          side: const BorderSide(
                            color: AppColors.alertOrangeDark,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: !absent
                            ? null
                            : () => _clear(context, busId, child.id),
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: const Text('On bus again'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.successGreen,
                          side: const BorderSide(
                            color: AppColors.successGreen,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _mark(BuildContext context, String busId, String studentId) async {
    try {
      await StudentAbsenceService.instance.markAbsent(
        busId: busId,
        studentId: studentId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked absent. Driver will skip this stop.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mark absent: $e')),
        );
      }
    }
  }

  Future<void> _clear(
    BuildContext context,
    String busId,
    String studentId,
  ) async {
    try {
      await StudentAbsenceService.instance.clearAbsence(
        busId: busId,
        studentId: studentId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child will be picked up again.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    }
  }
}