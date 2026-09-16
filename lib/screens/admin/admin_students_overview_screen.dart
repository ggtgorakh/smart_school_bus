// lib/screens/admin/admin_students_overview_screen.dart

import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class AdminStudentsOverviewScreen extends StatefulWidget {
  const AdminStudentsOverviewScreen({super.key});

  @override
  State<AdminStudentsOverviewScreen> createState() =>
      _AdminStudentsOverviewScreenState();
}

class _AdminStudentsOverviewScreenState extends State<AdminStudentsOverviewScreen> {
  String _query = '';
  String _status = 'All';

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return StreamBuilder<List<Student>>(
      stream: FirebaseService.instance.streamAllStudents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load students: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = _filtered(snapshot.data!);
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Students',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Search and filter the complete student roster across all buses.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _query = value),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Search name, ID, class, or bus',
                        ),
                      ),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'All', label: Text('All')),
                        ButtonSegment(
                          value: 'boarded',
                          label: Text('Boarded'),
                        ),
                        ButtonSegment(
                          value: 'pending',
                          label: Text('Pending'),
                        ),
                        ButtonSegment(
                          value: 'alert',
                          label: Text('Alert'),
                        ),
                      ],
                      selected: {_status},
                      onSelectionChanged: (value) =>
                          setState(() => _status = value.first),
                      showSelectedIcon: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: _StudentList(students: students)),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Student> _filtered(List<Student> students) {
    final query = _query.trim().toLowerCase();
    return students.where((student) {
      final statusMatch = _status == 'All' || student.status.name == _status;
      final queryMatch = query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.id.toLowerCase().contains(query) ||
          student.grade.toLowerCase().contains(query) ||
          (student.busId?.toLowerCase().contains(query) ?? false);
      return statusMatch && queryMatch;
    }).toList();
  }
}

/// Chooses between a table (wide) and a card list (narrow).
///
/// The previous implementation used a DataTable wrapped only in a
/// horizontal scroll view. `DataTable` computes its width from the sum
/// of its cell contents, and would still overflow its parent by a few
/// pixels when the parent's width fell short of that sum. The card list
/// avoids the entire class of problem.
class _StudentList extends StatelessWidget {
  final List<Student> students;

  const _StudentList({required this.students});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(
        child: Text('No students match the selected filters.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTable = constraints.maxWidth >= 900;
        if (!useTable) {
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: students.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _StudentCard(student: students[i]),
          );
        }
        return _StudentTable(students: students);
      },
    );
  }
}

class _StudentTable extends StatelessWidget {
  final List<Student> students;

  const _StudentTable({required this.students});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  headingRowHeight: 44,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 68,
                  columns: const [
                    DataColumn(label: Text('STUDENT')),
                    DataColumn(label: Text('CLASS / SECTION')),
                    DataColumn(label: Text('BUS')),
                    DataColumn(label: Text('STOP')),
                    DataColumn(label: Text('STATUS')),
                  ],
                  rows: students.map((student) {
                    final color = switch (student.status) {
                      StudentStatus.boarded => AppColors.successGreen,
                      StudentStatus.pending => AppColors.alertOrange,
                      StudentStatus.alert => AppColors.errorRed,
                    };
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  student.rollNumber ?? student.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                        ),
                        DataCell(
                          Text(
                            '${student.grade} / ${student.section ?? '-'}',
                          ),
                        ),
                        DataCell(
                          Text(student.busId?.toUpperCase() ?? 'Unassigned'),
                        ),
                        DataCell(
                          SizedBox(
                            width: 160,
                            child: Text(
                              student.stopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            student.statusLabel,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (student.status) {
      StudentStatus.boarded => AppColors.successGreen,
      StudentStatus.pending => AppColors.alertOrange,
      StudentStatus.alert => AppColors.errorRed,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                student.status == StudentStatus.boarded
                    ? Icons.check_circle_rounded
                    : student.status == StudentStatus.alert
                        ? Icons.error_rounded
                        : Icons.hourglass_top_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.rollNumber ?? student.id,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Pill(
                        icon: Icons.school_outlined,
                        label:
                            '${student.grade} / ${student.section ?? '-'}',
                        color: AppColors.safetyBlue,
                      ),
                      _Pill(
                        icon: Icons.directions_bus_rounded,
                        label: student.busId?.toUpperCase() ?? 'Unassigned',
                        color: AppColors.safetyBlue,
                      ),
                      _Pill(
                        icon: Icons.location_on_rounded,
                        label: student.stopName,
                        color: AppColors.alertOrangeDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                student.statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}