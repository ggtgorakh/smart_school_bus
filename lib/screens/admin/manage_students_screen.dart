// lib/screens/admin/manage_students_screen.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class _ParentOption {
  final String uid;
  final String name;
  final String email;

  _ParentOption({required this.uid, required this.name, required this.email});
}

class ManageStudentsScreen extends StatefulWidget {
  final String busId;

  const ManageStudentsScreen({super.key, this.busId = 'bus_01'});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _root = FirebaseDatabase.instance.ref();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

  Stream<List<_ParentOption>> _streamParentOptions() {
    return _root.child('users').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <_ParentOption>[];

      final List<_ParentOption> result = [];
      raw.forEach((uid, value) {
        if (value is Map && value['role']?.toString() == 'Parent') {
          result.add(
            _ParentOption(
              uid: uid.toString(),
              name: (value['name']?.toString().trim().isNotEmpty ?? false)
                  ? value['name'].toString()
                  : 'Unnamed parent',
              email: value['email']?.toString() ?? '---',
            ),
          );
        }
      });
      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return result;
    });
  }

  void _openStudentForm({Student? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentFormSheet(
        busId: widget.busId,
        existing: existing,
        parentOptionsStream: _streamParentOptions(),
      ),
    );
  }

  List<Student> _filterStudents(List<Student> students) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text(
          'Manage Students',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            onPressed: () => _openStudentForm(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Student',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Search & Filter
              _buildSearchAndFilter(context),
              // Student List
              Expanded(
                child: StreamBuilder<List<Student>>(
                  stream: FirebaseService.instance.streamStudents(widget.busId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildErrorState(context);
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.safetyBlue),
                      );
                    }

                    final students = snapshot.data!;
                    final filteredStudents = _filterStudents(students);

                    if (students.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    if (filteredStudents.isEmpty) {
                      return _buildEmptyFilterState(context);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      color: AppColors.safetyBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < filteredStudents.length - 1 ? 10 : 0,
                            ),
                            child: _StudentCard(
                              student: student,
                              onEdit: () => _openStudentForm(existing: student),
                              index: index,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH & FILTER
  // ============================================================

  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Boarded', 'boarded'),
                const SizedBox(width: 8),
                _buildFilterChip('Alert', 'alert'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = value),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
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
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 12),
            Text(
              "Can't load students",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.child_care_rounded,
                size: 56,
                color: AppColors.alertOrangeDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Students Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first student.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openStudentForm(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Student'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY FILTER STATE
  // ============================================================

  Widget _buildEmptyFilterState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No matching students',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search or filters.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _searchQuery = '';
              _filterStatus = 'all';
            }),
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STUDENT CARD
// ============================================================

class _StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final int index;

  const _StudentCard({
    required this.student,
    required this.onEdit,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final linked = student.parentUid != null && student.parentUid!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              backgroundImage: student.photoUrl.isNotEmpty
                  ? NetworkImage(student.photoUrl)
                  : null,
              child: student.photoUrl.isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      color: AppColors.safetyBlue,
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.grade} · ${student.seat} · ${student.stopName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Status Badge
                      _buildStatusBadge(),
                      const SizedBox(width: 8),
                      // Parent Link Badge
                      _buildParentLinkBadge(linked),
                    ],
                  ),
                ],
              ),
            ),

            // Edit Button
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.safetyBlue,
                size: 22,
              ),
              onPressed: onEdit,
              tooltip: 'Edit Student',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
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

  Widget _buildStatusBadge() {
    final color = student.status == StudentStatus.boarded
        ? AppColors.successGreen
        : student.status == StudentStatus.alert
            ? AppColors.errorRed
            : AppColors.alertOrange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        student.status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildParentLinkBadge(bool linked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: linked
            ? AppColors.successGreen.withValues(alpha: 0.12)
            : AppColors.errorRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: linked
              ? AppColors.successGreen.withValues(alpha: 0.2)
              : AppColors.errorRed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            linked ? Icons.link_rounded : Icons.link_off_rounded,
            size: 10,
            color: linked ? AppColors.successGreen : AppColors.errorRed,
          ),
          const SizedBox(width: 3),
          Text(
            linked ? 'Linked' : 'Unlinked',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: linked ? AppColors.successGreen : AppColors.errorRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STUDENT FORM SHEET
// ============================================================

class _StudentFormSheet extends StatefulWidget {
  final String busId;
  final Student? existing;
  final Stream<List<_ParentOption>> parentOptionsStream;

  const _StudentFormSheet({
    required this.busId,
    required this.existing,
    required this.parentOptionsStream,
  });

  @override
  State<_StudentFormSheet> createState() => _StudentFormSheetState();
}

class _StudentFormSheetState extends State<_StudentFormSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _gradeController;
  late final TextEditingController _seatController;
  late final TextEditingController _stopController;
  late final TextEditingController _photoController;
  String? _selectedParentUid;
  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _nameController = TextEditingController(text: s?.name ?? '');
    _gradeController = TextEditingController(text: s?.grade ?? '');
    _seatController = TextEditingController(text: s?.seat ?? '');
    _stopController = TextEditingController(text: s?.stopName ?? '');
    _photoController = TextEditingController(text: s?.photoUrl ?? '');
    _selectedParentUid = s?.parentUid;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
    _nameController.dispose();
    _gradeController.dispose();
    _seatController.dispose();
    _stopController.dispose();
    _photoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final oldParentUid = widget.existing?.parentUid;
      final studentId = widget.existing?.id ??
          FirebaseDatabase.instance
              .ref()
              .child('studentRosters/${widget.busId}')
              .push()
              .key!;

      final student = Student(
        id: studentId,
        name: _nameController.text.trim(),
        grade: _gradeController.text.trim(),
        seat: _seatController.text.trim(),
        photoUrl: _photoController.text.trim(),
        status: widget.existing?.status ?? StudentStatus.pending,
        stopName: _stopController.text.trim(),
        boardedAt: widget.existing?.boardedAt,
        parentUid: _selectedParentUid,
      );

      // If parent link changed, remove stale index entry
      if (oldParentUid != null &&
          oldParentUid.isNotEmpty &&
          oldParentUid != _selectedParentUid) {
        await FirebaseService.instance.unlinkChildFromParent(
          parentUid: oldParentUid,
          busId: widget.busId,
          studentId: studentId,
        );
      }

      await FirebaseService.instance.upsertStudent(
        busId: widget.busId,
        student: student,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isEditing
                        ? 'Updated ${student.name} successfully'
                        : 'Added ${student.name} to ${widget.busId}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving student: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.outline, size: 20),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.outline, fontSize: 14),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.safetyBlue, width: 2),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEditing ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
                          color: AppColors.safetyBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditing ? 'Edit Student' : 'Add Student',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Name Field
                  _label('Full Name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    decoration: _decoration('e.g. Maya Patel', Icons.badge_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Grade & Seat Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Grade'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _gradeController,
                              enabled: !_isSaving,
                              decoration: _decoration('e.g. Grade 4', Icons.school_outlined),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Seat'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _seatController,
                              enabled: !_isSaving,
                              decoration: _decoration('e.g. Seat 2B', Icons.event_seat_outlined),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Stop Field
                  _label('Stop Name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _stopController,
                    enabled: !_isSaving,
                    decoration: _decoration('e.g. Oak St & Maple Ave', Icons.location_on_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Stop name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Photo URL Field
                  _label('Photo URL (optional)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _photoController,
                    enabled: !_isSaving,
                    decoration: _decoration('https://...', Icons.image_outlined),
                  ),
                  const SizedBox(height: 14),

                  // Parent Link
                  _label('Linked Parent Account'),
                  const SizedBox(height: 6),
                  StreamBuilder<List<_ParentOption>>(
                    stream: widget.parentOptionsStream,
                    builder: (context, snapshot) {
                      final parents = snapshot.data ?? [];
                      return DropdownButtonFormField<String?>(
                        value: _selectedParentUid,
                        decoration: _decoration('No parent linked', Icons.family_restroom_rounded),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'No parent linked',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ...parents.map(
                            (p) => DropdownMenuItem<String?>(
                              value: p.uid,
                              child: Text(
                                '${p.name} (${p.email})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (val) => setState(() => _selectedParentUid = val),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.safetyBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.safetyBlue.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : (_isEditing ? 'Update Student' : 'Add Student'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}