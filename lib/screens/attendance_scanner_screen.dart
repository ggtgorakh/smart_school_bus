import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/student.dart';
import '../models/app_notification.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class AttendanceScannerScreen extends StatefulWidget {
  final String busId;

  const AttendanceScannerScreen({
    super.key,
    this.busId = 'bus_01',
  });

  @override
  State<AttendanceScannerScreen> createState() =>
      _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState
    extends State<AttendanceScannerScreen> {
  String _filterStatus = 'all';
  late final Stream<List<Student>> _studentsStream;

  @override
  void initState() {
    super.initState();
    _studentsStream = FirebaseService.instance.streamStudents(widget.busId);
  }

  Future<void> _toggleStudentStatus(Student student) async {
    final newStatus = student.status == StudentStatus.boarded
        ? StudentStatus.pending
        : StudentStatus.boarded;

    await FirebaseService.instance.updateStudentStatus(
      widget.busId,
      student.id,
      newStatus,
      stopName: student.stopName,
    );

    final action = newStatus == StudentStatus.boarded ? 'Boarded' : 'Unboarded';

    NotificationService.instance.add(
      kind: newStatus == StudentStatus.boarded
          ? NotificationKind.boarding
          : NotificationKind.info,
      title: '${student.name} $action',
      message: 'Updated at ${student.stopName}. Parent notified.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${student.name} marked as $action • Parent notified',
          ),
          backgroundColor: newStatus == StudentStatus.boarded
              ? AppColors.successGreen
              : AppColors.alertOrange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmAllBoarded(List<Student> students) async {
    await FirebaseService.instance.markAllStudentsStatus(
      widget.busId,
      StudentStatus.boarded,
    );

    NotificationService.instance.add(
      kind: NotificationKind.boarding,
      title: 'All Students Boarded',
      message: 'Bus ${widget.busId.toUpperCase()} manifest confirmed. Route departing.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ All students boarded and synced to Firebase!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _openScannerDialog(List<Student> students) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BadgeScannerModal(
        students: students,
        onStudentScanned: (student) async {
          Navigator.of(ctx).pop();
          await _toggleStudentStatus(
            student.status == StudentStatus.pending
                ? student
                : student.copyWith(status: StudentStatus.pending),
          );
        },
      ),
    );
  }

  List<Student> _getFilteredStudents(List<Student> students) {
    if (_filterStatus == 'all') {
      return students;
    }
    return students
        .where(
          (student) =>
              student.status.name == _filterStatus,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: StreamBuilder<List<Student>>(
        stream: _studentsStream,
        builder: (context, snapshot) {
          final students = snapshot.data ?? FirebaseService.defaultStudentRoster;
          final boardedCount =
              students.where((s) => s.status == StudentStatus.boarded).length;
          final pendingCount =
              students.where((s) => s.status == StudentStatus.pending).length;
          final filteredStudents = _getFilteredStudents(students);
          final progress =
              students.isEmpty ? 0.0 : boardedCount / students.length;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusHeader(
                    boardedCount,
                    pendingCount,
                    students.length,
                    progress,
                    () => _openScannerDialog(students),
                  ),
                  const SizedBox(height: 18),
                  _buildFilters(
                    boardedCount,
                    pendingCount,
                    students.length,
                  ),
                  const SizedBox(height: 16),
                  if (filteredStudents.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.checklist_rounded,
                              size: 44,
                              color: AppColors.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No students in this filter category',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _buildStudentCard(filteredStudents[index]);
                      },
                    ),
                  const SizedBox(height: 20),
                  _buildConfirmButton(
                    pendingCount,
                    () => _confirmAllBoarded(students),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(
    int boardedCount,
    int pendingCount,
    int totalCount,
    double progress,
    VoidCallback onScanTap,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stop 3: Oak St & Maple Ave',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Live Cloud Attendance Sync',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onScanTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alertOrange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text(
                  'Scan Badge',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '✓ Boarded: $boardedCount / $totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildFilters(int boardedCount, int pendingCount, int totalCount) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', totalCount),
            const SizedBox(width: 8),
            _buildFilterChip('Pending', 'pending', pendingCount),
            const SizedBox(width: 8),
            _buildFilterChip('Boarded', 'boarded', boardedCount),
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
      onSelected: (_) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.safetyBlue.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.safetyBlue : AppColors.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12.5,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.safetyBlue : AppColors.outlineVariant,
      ),
    );
  }

  Widget _buildConfirmButton(int pendingCount, VoidCallback onConfirm) {
    final hasPending = pendingCount > 0;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: hasPending ? onConfirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.successGreen,
          disabledBackgroundColor:
              AppColors.successGreen.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.check_circle_rounded, size: 20),
        label: Text(
          hasPending
              ? 'Mark All Boarded & Start Route'
              : '✓ All Students Boarded & Synced',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    final isBoarded = student.status == StudentStatus.boarded;
    final timeStr = student.boardedAt != null
        ? '${student.boardedAt!.hour.toString().padLeft(2, '0')}:${student.boardedAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBoarded
            ? AppColors.successGreen.withValues(alpha: 0.07)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBoarded ? AppColors.successGreen : AppColors.outlineVariant,
          width: isBoarded ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStudentAvatar(student, isBoarded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.grade} • ${student.seat} • ID: ${student.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
                if (isBoarded && timeStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '✓ Boarded at $timeStr',
                      style: const TextStyle(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _toggleStudentStatus(student),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isBoarded
                    ? AppColors.successGreen.withValues(alpha: 0.15)
                    : AppColors.safetyBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isBoarded
                      ? AppColors.successGreen
                      : AppColors.safetyBlue,
                ),
              ),
              child: Text(
                isBoarded ? 'Unboard' : 'Board',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isBoarded ? AppColors.successGreen : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentAvatar(Student student, bool isBoarded) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.brandGradient,
            border: Border.all(
              color: isBoarded ? AppColors.successGreen : Colors.white,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: student.photoUrl.isNotEmpty
                ? Image.network(
                    student.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        student.name.isNotEmpty ? student.name[0] : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      student.name.isNotEmpty ? student.name[0] : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
        ),
        if (isBoarded)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successGreen,
              ),
              child: const Icon(
                Icons.check,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

/// Simulated Barcode & NFC Badge Scanner Viewfinder Modal
class _BadgeScannerModal extends StatefulWidget {
  final List<Student> students;
  final Function(Student) onStudentScanned;

  const _BadgeScannerModal({
    required this.students,
    required this.onStudentScanned,
  });

  @override
  State<_BadgeScannerModal> createState() => _BadgeScannerModalState();
}

class _BadgeScannerModalState extends State<_BadgeScannerModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _idController = TextEditingController();
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _scanById(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return;

    final found = widget.students.firstWhere(
      (s) =>
          s.id.toLowerCase() == clean ||
          s.name.toLowerCase().contains(clean),
      orElse: () => widget.students.first,
    );

    widget.onStudentScanned(found);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.safetyBlue, size: 24),
              const SizedBox(width: 10),
              Text(
                'Student Badge & RFID Scanner',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Viewfinder simulation
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 110,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.safetyBlue, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    return Positioned(
                      top: 30 + (_anim.value * 90),
                      child: Container(
                        width: 170,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.alertOrange,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.alertOrange.withValues(alpha: 0.8),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Positioned(
                  bottom: 12,
                  child: Text(
                    'Align Student QR Code or RFID badge',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Quick scan tap list
          Text(
            'Quick Tap to Scan Student Badge:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.students.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.badge_outlined, size: 16),
                    label: Text('${s.name} (${s.id})'),
                    onPressed: () => widget.onStudentScanned(s),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    hintText: 'Enter Student ID (e.g. S1, S2)',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: _scanById,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _scanById(_idController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.safetyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Scan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}