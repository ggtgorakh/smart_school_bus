import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

/// Minimal read model for a Parent option in the dropdown.
class _ParentOption {
  final String uid;
  final String name;
  final String email;

  _ParentOption({required this.uid, required this.name, required this.email});
}

/// Admin-only screen for creating and editing student records, and linking
/// each one to a specific Parent account.
///
/// This is what actually closes the Confidentiality gap identified in the
/// RBAC/CIA analysis: a student with no parentUid is visible only to
/// Admin/Driver/Conductor (see database.rules.json), and a student linked
/// here becomes visible to that one Parent account via
/// FirebaseService.streamChildrenForParent.
class ManageStudentsScreen extends StatefulWidget {
  final String busId;

  const ManageStudentsScreen({super.key, this.busId = 'bus_01'});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

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
              email: value['email']?.toString() ?? '—',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text(
          'Manage Students',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openStudentForm(),
        backgroundColor: AppColors.safetyBlue,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text(
          'Add Student',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Student>>(
        stream: FirebaseService.instance.streamStudents(widget.busId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Can't load students.\nFirebase error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.safetyBlue),
            );
          }

          final students = snapshot.data!;
          if (students.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No students yet. Tap "Add Student" to create the first one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final student = students[index];
              final linked =
                  student.parentUid != null && student.parentUid!.isNotEmpty;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer,
                      backgroundImage: student.photoUrl.isNotEmpty
                          ? NetworkImage(student.photoUrl)
                          : null,
                      child: student.photoUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: AppColors.safetyBlue,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                linked
                                    ? Icons.link_rounded
                                    : Icons.link_off_rounded,
                                size: 12,
                                color: linked
                                    ? AppColors.successGreen
                                    : AppColors.errorRed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                linked ? 'Linked to a Parent' : 'Not linked',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: linked
                                      ? AppColors.successGreen
                                      : AppColors.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.safetyBlue,
                      ),
                      onPressed: () => _openStudentForm(existing: student),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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

class _StudentFormSheetState extends State<_StudentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _gradeController;
  late final TextEditingController _seatController;
  late final TextEditingController _stopController;
  late final TextEditingController _photoController;
  String? _selectedParentUid;
  bool _isSaving = false;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _seatController.dispose();
    _stopController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final oldParentUid = widget.existing?.parentUid;
      final studentId =
          widget.existing?.id ??
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

      // If the parent link changed (including being cleared), remove the
      // stale index entry first so a child never shows up under two
      // different Parent accounts at once.

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
            content: Text(
              _isEditing
                  ? 'Updated ${student.name}.'
                  : 'Added ${student.name} to $busIdLabel.',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving student: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String get busIdLabel => widget.busId;

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
      fontSize: 12.5,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 18),
                Text(
                  _isEditing ? 'Edit Student' : 'Add Student',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 18),

                _label('Full Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  decoration: _decoration(
                    'e.g. Maya Patel',
                    Icons.badge_outlined,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),

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
                            decoration: _decoration(
                              'e.g. Grade 4',
                              Icons.school_outlined,
                            ),
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
                            decoration: _decoration(
                              'e.g. Seat 2B',
                              Icons.event_seat_outlined,
                            ),
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

                _label('Stop Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _stopController,
                  enabled: !_isSaving,
                  decoration: _decoration(
                    'e.g. Oak St & Maple Ave',
                    Icons.location_on_outlined,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Stop name is required'
                      : null,
                ),
                const SizedBox(height: 14),

                _label('Photo URL (optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _photoController,
                  enabled: !_isSaving,
                  decoration: _decoration('https://...', Icons.image_outlined),
                ),
                const SizedBox(height: 14),

                _label('Linked Parent Account'),
                const SizedBox(height: 6),
                StreamBuilder<List<_ParentOption>>(
                  stream: widget.parentOptionsStream,
                  builder: (context, snapshot) {
                    final parents = snapshot.data ?? [];
                    return DropdownButtonFormField<String?>(
                      initialValue: _selectedParentUid,
                      decoration: _decoration(
                        'No parent linked',
                        Icons.family_restroom_rounded,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'No parent linked',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
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

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safetyBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.safetyBlue.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : (_isEditing ? 'Save Changes' : 'Add Student'),
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
    );
  }
}
