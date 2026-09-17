// lib/screens/parent_people_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/bus_fleet.dart';
import '../models/bus_location.dart';
import '../models/student.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class ParentPeopleScreen extends StatefulWidget {
  const ParentPeopleScreen({super.key});

  @override
  State<ParentPeopleScreen> createState() => _ParentPeopleScreenState();
}

class _ParentPeopleScreenState extends State<ParentPeopleScreen> {
  String? _selectedChildId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.instance.currentUserUid;
    if (uid == null) {
      return const Center(
        child: Text('Please sign in to view linked children.'),
      );
    }

    return StreamBuilder<List<Student>>(
      stream: FirebaseService.instance.streamChildrenForParent(uid),
      builder: (context, childSnapshot) {
        if (childSnapshot.hasError) {
          return Center(
            child: Text('Unable to load children: ${childSnapshot.error}'),
          );
        }

        if (!childSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final children = childSnapshot.data!;
        if (children.isEmpty) {
          return _buildEmptyState(context);
        }

        final selectedChild = children.firstWhere(
          (child) => child.id == _selectedChildId,
          orElse: () => children.first,
        );
        if (_selectedChildId != selectedChild.id) {
          _selectedChildId = selectedChild.id;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Mobile-first: single column with dropdown selector on narrow
            // screens. On wider screens, keep the two-pane layout.
            final isWide = constraints.maxWidth >= 900;

            if (!isWide) {
              return Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (children.length > 1) ...[
                      _MobileChildSelector(
                        children: children,
                        selectedId: selectedChild.id,
                        onSelect: (id) =>
                            setState(() => _selectedChildId = id),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: _ChildDetailPanel(child: selectedChild),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 340,
                    child: _ChildListPanel(
                      children: children,
                      selectedId: selectedChild.id,
                      onSelect: (id) =>
                          setState(() => _selectedChildId = id),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _ChildDetailPanel(child: selectedChild),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.family_restroom_outlined,
                  size: 48,
                  color: AppColors.safetyBlue,
                ),
                const SizedBox(height: 12),
                Text(
                  'No children linked',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your linked children will appear here once the school '
                  'has assigned them to your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

// ============================================================
// MOBILE CHILD SELECTOR (dropdown)
// ============================================================

class _MobileChildSelector extends StatelessWidget {
  final List<Student> children;
  final String selectedId;
  final void Function(String) onSelect;

  const _MobileChildSelector({
    required this.children,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.safetyBlue,
          ),
          items: children.map((c) {
            return DropdownMenuItem(
              value: c.id,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.safetyBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.safetyBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${c.grade} • ${c.busId?.toUpperCase() ?? 'No bus'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onSelect(val);
          },
        ),
      ),
    );
  }
}

// ============================================================
// DESKTOP CHILD LIST
// ============================================================

class _ChildListPanel extends StatelessWidget {
  final List<Student> children;
  final String selectedId;
  final void Function(String) onSelect;

  const _ChildListPanel({
    required this.children,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Text(
                'My Children',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: children.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final child = children[index];
                  final isSelected = child.id == selectedId;
                  return InkWell(
                    onTap: () => onSelect(child.id),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.safetyBlue.withValues(alpha: 0.09)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.safetyBlue
                              : Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                AppColors.safetyBlue.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.child_care_rounded,
                              color: AppColors.safetyBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${child.grade} • ${child.section ?? 'Section not assigned'}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHILD DETAIL PANEL — 2 tabs (Details, Bus Staff)
// ============================================================

class _ChildDetailPanel extends StatelessWidget {
  final Student child;

  const _ChildDetailPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: DefaultTabController(
        // Two tabs now: Details and Bus Staff. This is mobile-first —
        // fewer tabs = less horizontal squeeze on narrow phones.
        length: 2,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        AppColors.safetyBlue.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.safetyBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${child.grade} • ${child.busId?.toUpperCase() ?? 'No bus'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(child.status),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      child.statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const TabBar(
              tabs: [
                Tab(text: 'Details'),
                Tab(text: 'Bus Staff'),
              ],
              labelColor: AppColors.safetyBlue,
              indicatorColor: AppColors.safetyBlue,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDetailsTab(context, child),
                  _buildStaffTab(context, child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // DETAILS TAB — merged Child Info + Bus & Route
  // ───────────────────────────────────────────────────────────

  Widget _buildDetailsTab(BuildContext context, Student child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Transport assignment (top — most important) ──
          if (child.busId != null && child.busId!.trim().isNotEmpty)
            StreamBuilder<BusFleet?>(
              stream: FirebaseService.instance.streamFleetBus(child.busId!),
              builder: (context, snapshot) {
                final bus = snapshot.data;
                return _SectionCard(
                  title: 'Transport',
                  icon: Icons.directions_bus_rounded,
                  child: Column(
                    children: [
                      _KeyValueRow(
                        label: 'Bus',
                        value: child.busId ?? 'Not assigned',
                      ),
                      _KeyValueRow(
                        label: 'Route',
                        value: bus?.routeName ?? '—',
                      ),
                      _KeyValueRow(
                        label: 'Pickup stop',
                        value: child.pickupStop ?? child.stopName,
                      ),
                      _KeyValueRow(
                        label: 'Drop-off stop',
                        value: child.dropOffStop ?? '—',
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 14),

          // ── Editable parent-managed fields ──
          _SectionCard(
            title: 'Parent-managed details',
            icon: Icons.edit_note_rounded,
            child: Column(
              children: [
                _EditableRow(
                  label: 'Home Address',
                  value: child.homeAddress ?? 'Not provided',
                  onEdit: () => _editField(context, child, 'Home Address'),
                ),
                _EditableRow(
                  label: 'Pickup Stop',
                  value: child.pickupStop ?? 'Not provided',
                  onEdit: () => _editField(context, child, 'Pickup Stop'),
                ),
                _EditableRow(
                  label: 'Drop-off Stop',
                  value: child.dropOffStop ?? 'Not provided',
                  onEdit: () => _editField(context, child, 'Drop-off Stop'),
                ),
                _EditableRow(
                  label: 'Emergency Contact',
                  value: child.emergencyContact ?? 'Not provided',
                  onEdit: () =>
                      _editField(context, child, 'Emergency Contact'),
                ),
                _EditableRow(
                  label: 'Authorized Pickup',
                  value: child.authorizedPickupPerson ?? 'Not provided',
                  onEdit: () =>
                      _editField(context, child, 'Authorized Pickup'),
                ),
                _EditableRow(
                  label: 'Transportation Instructions',
                  value: child.transportationInstructions ?? 'Not provided',
                  onEdit: () => _editField(
                    context,
                    child,
                    'Transportation Instructions',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── School-controlled read-only ──
          _SectionCard(
            title: 'School records',
            icon: Icons.school_outlined,
            child: Column(
              children: [
                _KeyValueRow(
                  label: 'Student ID',
                  value: child.rollNumber ?? child.id,
                ),
                _KeyValueRow(label: 'Class', value: child.grade),
                _KeyValueRow(
                  label: 'Section',
                  value: child.section ?? '—',
                ),
                _KeyValueRow(
                  label: 'Date of birth',
                  value: _formatDate(child.dateOfBirth),
                ),
                _KeyValueRow(
                  label: 'School',
                  value: child.schoolName ?? '—',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // BUS STAFF TAB
  // ───────────────────────────────────────────────────────────

  Widget _buildStaffTab(BuildContext context, Student child) {
    if (child.busId == null || child.busId!.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('This child is not currently assigned to a bus.'),
        ),
      );
    }

    return StreamBuilder<BusFleet?>(
      stream: FirebaseService.instance.streamFleetBus(child.busId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final bus = snapshot.data;
        if (bus == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Bus record not found.'),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StaffCard(
              roleLabel: 'Driver',
              name: bus.driverName,
              phone: bus.driverPhone,
              icon: Icons.drive_eta_rounded,
              color: AppColors.alertOrange,
              onCall: (bus.driverPhone != null &&
                      bus.driverPhone!.trim().isNotEmpty)
                  ? () => _callNumber(context, bus.driverPhone!)
                  : null,
            ),
            const SizedBox(height: 12),
            _StaffCard(
              roleLabel: 'Conductor',
              name: bus.conductorName ?? 'Unassigned',
              phone: bus.conductorPhone,
              icon: Icons.badge_rounded,
              color: AppColors.successGreen,
              onCall: (bus.conductorPhone != null &&
                      bus.conductorPhone!.trim().isNotEmpty)
                  ? () => _callNumber(context, bus.conductorPhone!)
                  : null,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.safetyBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'If a number is incorrect, contact the school office.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────────────────

  Future<void> _callNumber(BuildContext context, String number) async {
    final clean = number.trim();
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the phone app.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to call: $e')),
        );
      }
    }
  }

  Future<void> _editField(
    BuildContext context,
    Student child,
    String fieldKey,
  ) async {
    final valueMap = {
      'Home Address': 'homeAddress',
      'Pickup Stop': 'pickupStop',
      'Drop-off Stop': 'dropOffStop',
      'Emergency Contact': 'emergencyContact',
      'Authorized Pickup': 'authorizedPickupPerson',
      'Transportation Instructions': 'transportationInstructions',
    };

    final key = valueMap[fieldKey];
    if (key == null || child.busId == null || child.busId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This child is not assigned to a bus yet.'),
        ),
      );
      return;
    }

    final controller = TextEditingController(
      text: _fieldValueFor(child, key),
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldKey'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter $fieldKey',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final updatedValue = controller.text.trim();
    final updates = <String, dynamic>{
      key: updatedValue.isEmpty ? null : updatedValue,
    };

    try {
      await FirebaseService.instance.updateStudentParentDetails(
        child.busId!,
        child.id,
        updates,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $error')),
        );
      }
    }
  }

  String _fieldValueFor(Student child, String key) {
    switch (key) {
      case 'homeAddress':
        return child.homeAddress ?? '';
      case 'pickupStop':
        return child.pickupStop ?? '';
      case 'dropOffStop':
        return child.dropOffStop ?? '';
      case 'emergencyContact':
        return child.emergencyContact ?? '';
      case 'authorizedPickupPerson':
        return child.authorizedPickupPerson ?? '';
      case 'transportationInstructions':
        return child.transportationInstructions ?? '';
      default:
        return '';
    }
  }

  Color _statusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.boarded:
        return AppColors.successGreen;
      case StudentStatus.pending:
        return AppColors.alertOrange;
      case StudentStatus.alert:
        return AppColors.errorRed;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

// ============================================================
// STAFF CARD — mobile-first, full-width call button
// ============================================================

class _StaffCard extends StatelessWidget {
  final String roleLabel;
  final String name;
  final String? phone;
  final IconData icon;
  final Color color;
  final VoidCallback? onCall;

  const _StaffCard({
    required this.roleLabel,
    required this.name,
    required this.phone,
    required this.icon,
    required this.color,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasPhone ? phone! : 'Number not provided',
                      style: TextStyle(
                        fontSize: 12.5,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle:
                            hasPhone ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onCall != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.call_rounded, size: 18),
                label: Text('Call $roleLabel'),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// SUPPORTING WIDGETS
// ============================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.safetyBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _EditableRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}