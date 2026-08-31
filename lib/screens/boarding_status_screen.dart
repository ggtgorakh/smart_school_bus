import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/student.dart';
import '../services/firebase_service.dart';

/// Parent-facing "has my child boarded yet" screen.
///
/// Multi-child support: subscribes to
/// FirebaseService.streamChildrenForParent using the signed-in Parent's
/// own uid, which resolves via /parentChildIndex (see database.rules.json
/// and FirebaseService.streamChildrenForParent for why a Parent can't
/// simply query the full bus roster directly — Confidentiality). Shows a
/// child selector only when more than one child is linked, and an honest
/// empty state if none are linked yet (a Parent account starts with no
/// children until Admin links one via Manage Students).
class BoardingStatusScreen extends StatefulWidget {
  const BoardingStatusScreen({super.key});

  @override
  State<BoardingStatusScreen> createState() => _BoardingStatusScreenState();
}

class _BoardingStatusScreenState extends State<BoardingStatusScreen> {
  String? _selectedStudentId;

  Color _statusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.boarded:
        return AppColors.successGreen;
      case StudentStatus.pending:
        return AppColors.alertOrangeDark;
      case StudentStatus.alert:
        return AppColors.errorRed;
    }
  }

  IconData _statusIcon(StudentStatus status) {
    switch (status) {
      case StudentStatus.boarded:
        return Icons.check_circle_rounded;
      case StudentStatus.pending:
        return Icons.hourglass_top_rounded;
      case StudentStatus.alert:
        return Icons.error_rounded;
    }
  }

  String _statusHeadline(StudentStatus status) {
    switch (status) {
      case StudentStatus.boarded:
        return 'Boarded the bus';
      case StudentStatus.pending:
        return 'Waiting at Stop / Not Boarded';
      case StudentStatus.alert:
        return 'Needs Attention';
    }
  }

  String _statusSubtext(StudentStatus status, String stopName) {
    switch (status) {
      case StudentStatus.boarded:
        return 'Checked in by Conductor at $stopName';
      case StudentStatus.pending:
        return 'Waiting for check-in at $stopName';
      case StudentStatus.alert:
        return 'Conductor flagged an alert at $stopName';
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentUid = FirebaseAuth.instance.currentUser?.uid;

    if (parentUid == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text(
            'Please sign in to view boarding status.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<Student>>(
        stream: FirebaseService.instance.streamChildrenForParent(parentUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.outline),
                    const SizedBox(height: 14),
                    Text(
                      "Can't load your child's status",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Firebase error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.safetyBlue),
            );
          }

          final children = snapshot.data!;

          if (children.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.family_restroom_rounded, size: 48, color: AppColors.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No child linked to your account yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask your school administrator to link your child to this account, and it will appear here automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          // Keep the selection valid as the linked-children list changes
          // (e.g. Admin links a second child while this screen is open).
          if (_selectedStudentId == null ||
              !children.any((c) => c.id == _selectedStudentId)) {
            _selectedStudentId = children.first.id;
          }

          final student = children.firstWhere((c) => c.id == _selectedStudentId);
          final color = _statusColor(student.status);
          final timeLabel = student.boardedAt != null
              ? '${student.boardedAt!.hour.toString().padLeft(2, '0')}:${student.boardedAt!.minute.toString().padLeft(2, '0')}'
              : null;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Child Selector Pill — only shown when this Parent has
                  // more than one linked child.
                  if (children.length > 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStudentId,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.safetyBlue),
                          items: children.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  const Icon(Icons.face_rounded,
                                      color: AppColors.safetyBlue, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${c.name} (${c.grade})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedStudentId = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Child identity card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.brandGradient,
                          ),
                          child: ClipOval(
                            child: student.photoUrl.isNotEmpty
                                ? Image.network(
                                    student.photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                      child: Text(
                                        student.name.isNotEmpty
                                            ? student.name[0]
                                            : 'S',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      student.name.isNotEmpty
                                          ? student.name[0]
                                          : 'S',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${student.grade} • ${student.seat}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Big real-time status card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_statusIcon(student.status),
                              color: color, size: 34),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusHeadline(student.status),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _statusSubtext(student.status, student.stopName),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13.5,
                              ),
                        ),
                        if (timeLabel != null &&
                            student.status == StudentStatus.boarded) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.successGreen, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Checked in at $timeLabel',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick context row — stop + pickup point
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.safetyBlue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Designated stop: ${student.stopName}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}