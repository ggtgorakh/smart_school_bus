import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'live_tracking_screen.dart';

class ParentTrackingScreen extends StatefulWidget {
  const ParentTrackingScreen({super.key});

  @override
  State<ParentTrackingScreen> createState() => _ParentTrackingScreenState();
}

class _ParentTrackingScreenState extends State<ParentTrackingScreen> {
  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.instance.currentUserUid;
    if (uid == null) {
      return const Center(child: Text('Please sign in to track a bus.'));
    }

    return StreamBuilder<List<Student>>(
      stream: FirebaseService.instance.streamChildrenForParent(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load linked children: ${snapshot.error}'),
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
            child: Text('No children are linked to this account yet.'),
          );
        }

        final selected = children.firstWhere(
          (student) => student.id == _selectedStudentId,
          orElse: () => children.first,
        );
        if (_selectedStudentId != selected.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedStudentId = selected.id);
            }
          });
        }

        return Column(
          children: [
            if (children.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: DropdownButtonFormField<String>(
                  initialValue: selected.id,
                  decoration: const InputDecoration(
                    labelText: 'Track child',
                    border: OutlineInputBorder(),
                  ),
                  items: children
                      .map(
                        (student) => DropdownMenuItem(
                          value: student.id,
                          child: Text(
                            '${student.name} • ${student.busId ?? 'Bus unavailable'}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStudentId = value);
                    }
                  },
                ),
              ),
            Expanded(
              child: selected.busId == null || selected.busId!.isEmpty
                  ? const Center(
                      child: Text('No bus is assigned to this child yet.'),
                    )
                  : LiveTrackingScreen(
                      busId: selected.busId!,
                      studentName: selected.name,
                      studentGradeAndSeat:
                          '${selected.grade} • ${selected.seat}',
                    ),
            ),
          ],
        );
      },
    );
  }
}
