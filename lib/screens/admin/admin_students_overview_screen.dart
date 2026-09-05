import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class AdminStudentsOverviewScreen extends StatefulWidget {
  const AdminStudentsOverviewScreen({super.key});

  @override
  State<AdminStudentsOverviewScreen> createState() => _AdminStudentsOverviewScreenState();
}

class _AdminStudentsOverviewScreenState extends State<AdminStudentsOverviewScreen> {
  String _query = '';
  String _status = 'All';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Student>>(
      stream: FirebaseService.instance.streamAllStudents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load students: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = _filtered(snapshot.data!);
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Students',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Search and filter the complete student roster across all buses.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Search name, ID, class, or bus',
                        ),
                      ),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'All', label: Text('All')),
                        ButtonSegment(value: 'boarded', label: Text('Boarded')),
                        ButtonSegment(value: 'pending', label: Text('Pending')),
                        ButtonSegment(value: 'alert', label: Text('Alert')),
                      ],
                      selected: {_status},
                      onSelectionChanged: (value) => setState(() => _status = value.first),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: _StudentTable(students: students)),
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

class _StudentTable extends StatelessWidget {
  final List<Student> students;

  const _StudentTable({required this.students});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(child: Text('No students match the selected filters.'));
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 32,
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
                DataCell(Text('${student.name}\n${student.rollNumber ?? student.id}')),
                DataCell(Text('${student.grade} / ${student.section ?? '-'}')),
                DataCell(Text(student.busId ?? 'Unassigned')),
                DataCell(Text(student.stopName)),
                DataCell(Text(student.statusLabel, style: TextStyle(color: color, fontWeight: FontWeight.w700))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
