import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/student.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() =>
      _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState
    extends State<AttendanceScannerScreen> {
  final List<Student> _students = [
    Student(
      id: 'S1',
      name: 'Liam Johnson',
      grade: 'Grade 3',
      seat: 'Seat 4A',
      photoUrl: 'https://i.pravatar.cc/150?img=12',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S2',
      name: 'Maya Patel',
      grade: 'Grade 4',
      seat: 'Seat 2B',
      photoUrl: 'https://i.pravatar.cc/150?img=47',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S3',
      name: 'Ethan Williams',
      grade: 'Grade 5',
      seat: 'Seat 8C',
      photoUrl: 'https://i.pravatar.cc/150?img=33',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S4',
      name: 'Sophia Garcia',
      grade: 'Grade 2',
      seat: 'Seat 1A',
      photoUrl: 'https://i.pravatar.cc/150?img=26',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
    Student(
      id: 'S5',
      name: 'Jackson Davis',
      grade: 'Grade 3',
      seat: 'Seat 5D',
      photoUrl: 'https://i.pravatar.cc/150?img=60',
      status: StudentStatus.pending,
      stopName: 'Oak St & Maple Ave',
    ),
  ];

  String _filterStatus = 'pending';

  void _toggleStudentStatus(Student student) {
    setState(() {
      if (student.status == StudentStatus.pending) {
        student.status = StudentStatus.boarded;
      } else if (student.status == StudentStatus.boarded) {
        student.status = StudentStatus.pending;
      }
    });

    final action =
    student.status == StudentStatus.boarded ? 'Boarded' : 'Offboarded';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${student.name} marked as $action | Parent notified',
        ),
        backgroundColor: student.status == StudentStatus.boarded
            ? AppColors.successGreen
            : AppColors.alertOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmAllBoarded() {
    setState(() {
      for (final student in _students) {
        student.status = StudentStatus.boarded;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ All students boarded. Route can proceed.'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  List<Student> _getFilteredStudents() {
    if (_filterStatus == 'all') {
      return _students;
    }

    return _students
        .where(
          (student) =>
      student.status.toString().split('.').last == _filterStatus,
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final boardedCount = _students
        .where((student) => student.status == StudentStatus.boarded)
        .length;

    final pendingCount = _students
        .where((student) => student.status == StudentStatus.pending)
        .length;

    final filteredStudents = _getFilteredStudents();

    final progress = _students.isEmpty
        ? 0.0
        : boardedCount / _students.length;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(
                boardedCount,
                pendingCount,
                progress,
              ),

              const SizedBox(height: 18),

              _buildFilters(
                boardedCount,
                pendingCount,
              ),

              const SizedBox(height: 16),

              if (filteredStudents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                    ),
                    child: Text(
                      'No students in this category',
                      style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _buildStudentCard(
                      filteredStudents[index],
                    );
                  },
                ),

              const SizedBox(height: 20),

              _buildConfirmButton(pendingCount),

              // Extra space above the navigation bar.
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(
      int boardedCount,
      int pendingCount,
      double progress,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.safetyBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 360;

          final stopInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stop 3: Oak St & Maple Ave',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manual Check-in/Check-out',
                style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          );

          final countBadge = Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$boardedCount/${_students.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSmall) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: stopInfo),
                    const SizedBox(width: 8),
                    countBadge,
                  ],
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: stopInfo),
                    const SizedBox(width: 12),
                    countBadge,
                  ],
                ),

              const SizedBox(height: 14),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor:
                  Colors.white.withValues(alpha: 0.3),
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      '✓ Boarded: $boardedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '⏳ Pending: $pendingCount',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(
      int boardedCount,
      int pendingCount,
      ) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              'Pending',
              'pending',
              pendingCount,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Boarded',
              'boarded',
              boardedCount,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'All',
              'all',
              _students.length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label,
      String value,
      int count,
      ) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor:
      AppColors.safetyBlue.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.safetyBlue
            : AppColors.onSurfaceVariant,
        fontWeight:
        isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? AppColors.safetyBlue
            : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildConfirmButton(int pendingCount) {
    final hasPendingStudents = pendingCount > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
        hasPendingStudents ? _confirmAllBoarded : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasPendingStudents
              ? AppColors.successGreen
              : AppColors.successGreen.withValues(
            alpha: 0.5,
          ),
          disabledBackgroundColor:
          AppColors.successGreen.withValues(
            alpha: 0.5,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          hasPendingStudents
              ? 'Mark All Boarded & Start Route'
              : '✓ All Students Boarded',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    final isBoarded =
        student.status == StudentStatus.boarded;

    final boardingTime =
    isBoarded ? DateTime.now() : null;

    final timeStr = boardingTime != null
        ? '${boardingTime.hour}:${boardingTime.minute.toString().padLeft(2, '0')}'
        : '';

    return GestureDetector(
      onTap: () => _toggleStudentStatus(student),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isBoarded
              ? AppColors.successGreen.withValues(
            alpha: 0.08,
          )
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBoarded
                ? AppColors.successGreen
                : AppColors.outlineVariant,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildStudentAvatar(isBoarded),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    '${student.grade} • ${student.seat}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),

                  if (isBoarded && timeStr.isNotEmpty)
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 2),
                      child: Text(
                        'Boarded at $timeStr',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                          color:
                          AppColors.successGreen,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Status button is constrained so it cannot
            // force the card beyond the screen.
            Flexible(
              flex: 0,
              child: _buildStatusBadge(isBoarded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAvatar(bool isBoarded) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHigh,
            border: Border.all(
              color: isBoarded
                  ? AppColors.successGreen
                  : AppColors.outline,
              width: 2,
            ),
          ),
          child: const ClipOval(
            child: Icon(
              Icons.person,
              color: AppColors.outline,
              size: 28,
            ),
          ),
        ),

        if (isBoarded)
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successGreen,
              ),
              child: const Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isBoarded) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 88,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isBoarded
            ? AppColors.successGreen.withValues(
          alpha: 0.2,
        )
            : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isBoarded ? 'Tap to Unboard' : 'Tap to Board',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: isBoarded
              ? AppColors.successGreen
              : Colors.white,
        ),
      ),
    );
  }
}