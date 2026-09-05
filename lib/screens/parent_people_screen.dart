import 'package:flutter/material.dart';

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
      return const Center(child: Text('Please sign in to view linked children.'));
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
            final isWide = constraints.maxWidth >= 980;
            return Padding(
              padding: const EdgeInsets.all(18),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 340,
                          child: _ChildListPanel(
                            children: children,
                            selectedId: selectedChild.id,
                            onSelect: (id) => setState(() => _selectedChildId = id),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(child: _ChildDetailPanel(child: selectedChild)),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child: _ChildListPanel(
                            children: children,
                            selectedId: selectedChild.id,
                            onSelect: (id) =>
                                setState(() => _selectedChildId = id),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: _ChildDetailPanel(child: selectedChild)),
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
                const Icon(Icons.family_restroom_outlined, size: 48, color: AppColors.safetyBlue),
                const SizedBox(height: 12),
                Text(
                  'No children linked',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your linked children will appear here once the school has assigned them to your account.',
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
                            : Theme.of(context).colorScheme.surfaceContainerLow,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.safetyBlue
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.safetyBlue.withValues(alpha: 0.12),
                            child: const Icon(Icons.child_care_rounded, color: AppColors.safetyBlue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${child.grade} • ${child.section ?? 'Section not assigned'}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Student ID: ${child.rollNumber ?? child.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _ChildDetailPanel extends StatelessWidget {
  final Student child;

  const _ChildDetailPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: DefaultTabController(
      length: 2,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.safetyBlue.withValues(alpha: 0.12),
                    child: const Icon(Icons.person_rounded, color: AppColors.safetyBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${child.grade} • ${child.section ?? 'Section not assigned'} • ${child.busId ?? 'No bus'}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            TabBar(
              tabs: const [
                Tab(text: 'Child Info'),
                Tab(text: 'Bus & Route'),
              ],
              labelColor: AppColors.safetyBlue,
              indicatorColor: AppColors.safetyBlue,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildChildInfoTab(context, child),
                  _buildBusRouteTab(context, child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildInfoTab(BuildContext context, Student child) {
    final readOnlyFields = <_FieldItem>[
      _FieldItem('Full Name', child.name),
      _FieldItem('Student ID', child.rollNumber ?? child.id),
      _FieldItem('Date of Birth', _formatDate(child.dateOfBirth)),
      _FieldItem('Class', child.grade),
      _FieldItem('Section', child.section ?? 'Not assigned'),
      _FieldItem('School', child.schoolName ?? 'School not assigned'),
      _FieldItem('School ID', child.schoolId ?? 'Not assigned'),
    ];

    final editableFields = <_FieldItem>[
      _FieldItem('Home Address', child.homeAddress ?? 'Not provided'),
      _FieldItem('Pickup Stop', child.pickupStop ?? 'Not provided'),
      _FieldItem('Drop-off Stop', child.dropOffStop ?? 'Not provided'),
      _FieldItem('Emergency Contact', child.emergencyContact ?? 'Not provided'),
      _FieldItem('Authorized Pickup', child.authorizedPickupPerson ?? 'Not provided'),
      _FieldItem('Transportation Instructions', child.transportationInstructions ?? 'Not provided'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'School-controlled / Read-only',
            icon: Icons.lock_outline_rounded,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: readOnlyFields.map((value) => _ReadOnlyFieldTile(value: value)).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Parent-managed details',
            icon: Icons.edit_note_rounded,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: editableFields.map((field) {
                return _EditableFieldTile(
                  label: field.label,
                  value: field.value,
                  onEdit: () => _editField(context, child, field.label),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusRouteTab(BuildContext context, Student child) {
    if (child.busId == null || child.busId!.trim().isEmpty) {
      return const Center(
        child: Text('This child is not currently assigned to a bus.'),
      );
    }

    return StreamBuilder<BusLocation?>(
      stream: FirebaseService.instance.streamBusLocation(child.busId!),
      builder: (context, snapshot) {
        final location = snapshot.data;
        final isLoading = !snapshot.hasData && !snapshot.hasError;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<BusFleet?>(
          stream: FirebaseService.instance.streamFleetBus(child.busId!),
          builder: (context, fleetSnapshot) {
            final bus = fleetSnapshot.data;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SectionCard(
                    title: 'Current transport assignment',
                    icon: Icons.directions_bus_rounded,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ReadOnlyFieldTile(value: _FieldItem('Bus Number', child.busId ?? 'Not assigned')),
                        _ReadOnlyFieldTile(value: _FieldItem('Route', bus?.routeName ?? 'No route assigned')),
                        _ReadOnlyFieldTile(value: _FieldItem('Pickup Stop', child.pickupStop ?? 'Not provided')),
                        _ReadOnlyFieldTile(value: _FieldItem('Drop-off Stop', child.dropOffStop ?? 'Not provided')),
                        _ReadOnlyFieldTile(value: _FieldItem('Trip Status', bus?.statusLabel ?? 'Not available')),
                        _ReadOnlyFieldTile(value: _FieldItem('Driver', bus?.driverName ?? 'Unassigned')),
                        _ReadOnlyFieldTile(value: _FieldItem('Conductor', bus?.conductorName ?? 'Unassigned')),
                        _ReadOnlyFieldTile(
                          value: _FieldItem(
                            'GPS',
                            location == null ? 'No live location' : '${location.statusLabel} • ${location.etaLabel}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editField(BuildContext context, Student child, String fieldKey) async {
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
        const SnackBar(content: Text('This child is not assigned to a bus yet.')),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    final updates = <String, dynamic>{key: updatedValue.isEmpty ? null : updatedValue};

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
    if (value == null) return 'Not set';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

class _FieldItem {
  final String label;
  final String value;

  const _FieldItem(this.label, this.value);
}

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
                Icon(icon, color: AppColors.safetyBlue),
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

class _ReadOnlyFieldTile extends StatelessWidget {
  final _FieldItem value;

  const _ReadOnlyFieldTile({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableFieldTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _EditableFieldTile({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
