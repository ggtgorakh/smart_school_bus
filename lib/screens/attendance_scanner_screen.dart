// lib/screens/attendance_scanner_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen>
    with SingleTickerProviderStateMixin {
  String _filterStatus = 'all';
  String _searchQuery = '';
  late final Stream<List<Student>> _studentsStream;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _studentsStream = FirebaseService.instance.streamStudents(widget.busId);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleStudentStatus(Student student) async {
    final newStatus = student.status == StudentStatus.boarded
        ? StudentStatus.pending
        : StudentStatus.boarded;

    // Get bus information for notification context
    final busSnapshot = await FirebaseDatabase.instance
        .ref('buses/${widget.busId}')
        .get();
    final busNumber = busSnapshot.value is Map
        ? (busSnapshot.value as Map)['busNumber']?.toString() ?? widget.busId
        : widget.busId;

    // Update status in Firebase
    await FirebaseService.instance.updateStudentStatus(
      widget.busId,
      student.id,
      newStatus,
      stopName: student.stopName,
    );

    // Send notification to parent (if linked)
    if (student.parentUid != null && student.parentUid!.isNotEmpty) {
      await NotificationService.instance.notifyStudentBoarding(
        studentName: student.name,
        busId: widget.busId,
        busNumber: busNumber,
        stopName: student.stopName,
        isBoarding: newStatus == StudentStatus.boarded,
        parentUid: student.parentUid,
      );
    }

    // Add notification for conductor/driver
    final action = newStatus == StudentStatus.boarded ? 'Boarded' : 'Unboarded';
    await NotificationService.instance.add(
      kind: newStatus == StudentStatus.boarded
          ? NotificationKind.boarding
          : NotificationKind.info,
      title: '${student.name} $action',
      message: 'Updated at ${student.stopName} on $busNumber',
      busId: widget.busId,
      studentId: student.id,
      metadata: {
        'action': action,
        'status': newStatus.name,
        'conductor': FirebaseAuth.instance.currentUser?.uid,
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newStatus == StudentStatus.boarded
                    ? Icons.check_circle_rounded
                    : Icons.remove_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${student.name} marked as $action • Parent notified',
                ),
              ),
            ],
          ),
          backgroundColor: newStatus == StudentStatus.boarded
              ? AppColors.successGreen
              : AppColors.alertOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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

    // Get bus number
    final busSnapshot = await FirebaseDatabase.instance
        .ref('buses/${widget.busId}')
        .get();
    final busNumber = busSnapshot.value is Map
        ? (busSnapshot.value as Map)['busNumber']?.toString() ?? widget.busId
        : widget.busId;

    await NotificationService.instance.add(
      kind: NotificationKind.departure,
      title: 'All Students Boarded - $busNumber',
      message: 'Manifest confirmed. Route departing now.',
      busId: widget.busId,
      metadata: {
        'totalStudents': students.length,
        'departureTime': DateTime.now().toIso8601String(),
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('✓ All students boarded and synced to Firebase!')),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    var filtered = students;
    
    // Apply status filter
    if (_filterStatus != 'all') {
      filtered = filtered.where((s) => s.status.name == _filterStatus).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((s) =>
        s.name.toLowerCase().contains(query) ||
        s.id.toLowerCase().contains(query) ||
        s.grade.toLowerCase().contains(query)
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: StreamBuilder<List<Student>>(
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
                child: Column(
                  children: [
                    // Header
                    _buildHeader(
                      context,
                      boardedCount,
                      pendingCount,
                      students.length,
                      progress,
                      () => _openScannerDialog(students),
                    ),
                    
                    // Search & Filter
                    _buildSearchAndFilter(
                      boardedCount,
                      pendingCount,
                      students.length,
                    ),
                    
                    // Student List
                    Expanded(
                      child: _buildStudentList(filteredStudents, students),
                    ),
                    
                    // Confirm Button
                    if (pendingCount > 0)
                      _buildConfirmButton(pendingCount, students),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    int boardedCount,
    int pendingCount,
    int totalCount,
    double progress,
    VoidCallback onScanTap,
  ) {
    final isMobile = context.isMobile;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.safetyBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.how_to_reg_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stop 3: Oak St & Maple Ave',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text(
                  'Scan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Boarded: $boardedCount / $totalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pending: $pendingCount',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH & FILTER
  // ============================================================

  Widget _buildSearchAndFilter(int boardedCount, int pendingCount, int totalCount) {
    final isMobile = context.isMobile;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.outline,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = value),
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: AppColors.safetyBlue.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.safetyBlue : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12.5,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.safetyBlue : AppColors.outlineVariant,
        width: isSelected ? 1.5 : 1,
      ),
      shape: StadiumBorder(),
    );
  }

  // ============================================================
  // STUDENT LIST
  // ============================================================

  Widget _buildStudentList(List<Student> filteredStudents, List<Student> allStudents) {
    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No students found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_searchQuery.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _searchQuery = ''),
                child: const Text('Clear search'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < filteredStudents.length - 1 ? 10 : 0),
          child: _StudentCard(
            student: filteredStudents[index],
            onToggle: () => _toggleStudentStatus(filteredStudents[index]),
            index: index,
          ),
        );
      },
    );
  }

  // ============================================================
  // CONFIRM BUTTON
  // ============================================================

  Widget _buildConfirmButton(int pendingCount, List<Student> students) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: pendingCount > 0 ? () => _confirmAllBoarded(students) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              disabledBackgroundColor: AppColors.successGreen.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: Text(
              pendingCount > 0
                  ? 'Mark All Boarded ($pendingCount remaining)'
                  : '✓ All Students Boarded',
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STUDENT CARD
// ============================================================

class _StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onToggle;
  final int index;

  const _StudentCard({
    required this.student,
    required this.onToggle,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isBoarded = student.status == StudentStatus.boarded;
    final timeStr = student.boardedAt != null
        ? '${student.boardedAt!.hour.toString().padLeft(2, '0')}:${student.boardedAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isBoarded
              ? AppColors.successGreen.withValues(alpha: 0.06)
              : Theme.of(context).colorScheme.surface,
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
            _buildAvatar(),
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: AppColors.successGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Boarded at $timeStr',
                            style: const TextStyle(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildActionButton(isBoarded),
          ],
        ),
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    final isBoarded = student.status == StudentStatus.boarded;

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
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
        ),
        if (isBoarded)
          Positioned(
            bottom: -2,
            right: -2,
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

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isBoarded) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isBoarded
              ? AppColors.errorRed.withValues(alpha: 0.12)
              : AppColors.safetyBlue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBoarded ? AppColors.errorRed : AppColors.safetyBlue,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBoarded ? Icons.remove_rounded : Icons.add_rounded,
              size: 14,
              color: isBoarded ? AppColors.errorRed : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              isBoarded ? 'Unboard' : 'Board',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isBoarded ? AppColors.errorRed : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BADGE SCANNER MODAL
// ============================================================

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
  final TextEditingController _nameController = TextEditingController();
  late final AnimationController _animController;
  late final Animation<double> _scanAnimation;
  String _scanMode = 'id'; // 'id' or 'name'

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _scanById(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return;

    Student? found;
    if (_scanMode == 'id') {
      found = widget.students.firstWhere(
        (s) => s.id.toLowerCase() == clean,
        orElse: () => widget.students.first,
      );
    } else {
      found = widget.students.firstWhere(
        (s) => s.name.toLowerCase().contains(clean),
        orElse: () => widget.students.first,
      );
    }
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.safetyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.safetyBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Scanner',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Scan by ID or Name',
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
          const SizedBox(height: 16),

          // Scanner Mode Toggle
          Row(
            children: [
              _buildModeToggle('ID', 'id'),
              const SizedBox(width: 8),
              _buildModeToggle('Name', 'name'),
            ],
          ),
          const SizedBox(height: 16),

          // Viewfinder
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
                // Scanner Frame
                Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.safetyBlue, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Scanning Line
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, _) {
                    return Positioned(
                      top: 20 + (_scanAnimation.value * 90),
                      child: Container(
                        width: 180,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.alertOrange,
                              Colors.transparent,
                            ],
                          ),
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
                Positioned(
                  bottom: 12,
                  child: Text(
                    'Align badge or ID card',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _scanMode == 'id' ? _idController : _nameController,
                  onSubmitted: _scanById,
                  decoration: InputDecoration(
                    hintText: _scanMode == 'id' ? 'Enter Student ID (e.g. S1)' : 'Enter Student Name',
                    prefixIcon: Icon(
                      _scanMode == 'id' ? Icons.badge_rounded : Icons.person_rounded,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _scanById(
                  _scanMode == 'id' ? _idController.text : _nameController.text,
                ),
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
          const SizedBox(height: 14),

          // Quick Scan List
          Text(
            'Quick Select:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final s = widget.students[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.safetyBlue.withValues(alpha: 0.1),
                      child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.safetyBlue,
                        ),
                      ),
                    ),
                    label: Text(s.name),
                    onPressed: () => widget.onStudentScanned(s),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(String label, String value) {
    final isSelected = _scanMode == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _scanMode = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.safetyBlue.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.safetyBlue : AppColors.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.safetyBlue : AppColors.outline,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}