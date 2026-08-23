import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/student.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() =>
      _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  // Manual conductor check-in/check-out system
  // Replaces RFID scanner with tap-to-confirm interface
  // Each student tap logs boarding/offboarding - parents notified in real-time

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

  String _filterStatus = 'pending'; // Filter: pending, boarded, all

  void _toggleStudentStatus(Student student) {
    setState(() {
      if (student.status == StudentStatus.pending) {
        student.status = StudentStatus.boarded;
      } else if (student.status == StudentStatus.boarded) {
        student.status = StudentStatus.pending;
      }
    });
    
    final action = student.status == StudentStatus.boarded ? 'Boarded' : 'Offboarded';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${student.name} marked as $action | Parent notified'),
        backgroundColor: student.status == StudentStatus.boarded
            ? AppColors.successGreen
            : AppColors.alertOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmAllBoarded() {
    setState(() {
      for (var s in _students) {
        s.status = StudentStatus.boarded;
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
        .where((s) =>
            s.status.toString().split('.').last == _filterStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final boardedCount =
        _students.where((s) => s.status == StudentStatus.boarded).length;
    final pendingCount =
        _students.where((s) => s.status == StudentStatus.pending).length;
    final filteredStudents = _getFilteredStudents();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with stats
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stop 3: Oak St & Maple Ave',
                            style:
                                Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manual Check-in/Check-out',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: boardedCount / _students.length,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '✓ Boarded: $boardedCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '⏳ Pending: $pendingCount',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filter chips
            Row(
              spacing: 8,
              children: [
                _buildFilterChip('Pending', 'pending', pendingCount),
                _buildFilterChip('Boarded', 'boarded', boardedCount),
                _buildFilterChip('All', 'all', _students.length),
              ],
            ),
            const SizedBox(height: 16),

            // Student list with tap-to-toggle
            if (filteredStudents.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No students in this category',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return _buildStudentCard(student);
                },
              ),
            const SizedBox(height: 16),

            // Confirm all boarded button
            if (pendingCount > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _confirmAllBoarded,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle,
                      color: Colors.white, size: 20),
                  label: const Text(
                    'Mark All Boarded & Start Route',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  label: const Text(
                    '✓ All Students Boarded',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: AppColors.safetyBlue.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.safetyBlue : AppColors.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.safetyBlue : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    final isBoarded = student.status == StudentStatus.boarded;
    final boardingTime = isBoarded ? DateTime.now() : null;
    final timeStr = boardingTime != null
        ? '${boardingTime.hour}:${boardingTime.minute.toString().padLeft(2, '0')}'
        : '';

    return GestureDetector(
      onTap: () => _toggleStudentStatus(student),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isBoarded
              ? AppColors.successGreen.withValues(alpha: 0.08)
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
          children: [
            // Student avatar with status
            Stack(
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
                  child: ClipOval(
                    child: Icon(
                      Icons.person,
                      color: AppColors.outline,
                      size: 28,
                    ),
                  ),
                ),
                if (isBoarded)
                  Positioned(
                    bottom: 0,
                    right: 0,
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
            ),
            const SizedBox(width: 12),

            // Student info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${student.grade} • ${student.seat}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  if (isBoarded && timeStr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Boarded at $timeStr',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                ],
              ),
            ),

            // Tap indicator
            if (!isBoarded)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tap to Board',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tap to Unboard',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
