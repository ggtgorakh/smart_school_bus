import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../models/bus_fleet.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import 'create_user_screen.dart';

class AdminOperationsScreen extends StatefulWidget {
  const AdminOperationsScreen({super.key});

  @override
  State<AdminOperationsScreen> createState() => _AdminOperationsScreenState();
}

class _AdminOperationsScreenState extends State<AdminOperationsScreen> {
  final DatabaseReference _users = FirebaseDatabase.instance.ref('users');
  String _filter = 'All';
  String _query = '';

  Stream<List<_ManagedUser>> _usersStream() {
    return _users.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <_ManagedUser>[];
      final users = <_ManagedUser>[];
      value.forEach((uid, raw) {
        if (raw is Map) {
          final user = _ManagedUser.fromMap(uid.toString(), raw);
          if (user.role != 'Admin') users.add(user);
        }
      });
      users.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return users;
    });
  }

  List<_ManagedUser> _visibleUsers(List<_ManagedUser> users) {
    final query = _query.trim().toLowerCase();
    return users.where((user) {
      final roleMatch = _filter == 'All' || user.role == _filter;
      final queryMatch =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.busId?.toLowerCase().contains(query) ?? false);
      return roleMatch && queryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('People & Assignments'),
        actions: [
          IconButton(
            tooltip: 'Add account',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminCreateUserScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<_ManagedUser>>(
        stream: _usersStream(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(
              child: Text('Could not load accounts: ${userSnapshot.error}'),
            );
          }
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = userSnapshot.data!;
          final visible = _visibleUsers(users);
          final drivers = users.where((u) => u.role == 'Driver').length;
          final conductors = users.where((u) => u.role == 'Conductor').length;
          final parents = users.where((u) => u.role == 'Parent').length;
          final unassigned = users
              .where(
                (u) =>
                    (u.role == 'Driver' || u.role == 'Conductor') &&
                    (u.busId == null || u.busId!.isEmpty),
              )
              .length;

          return StreamBuilder<List<BusFleet>>(
            stream: FirebaseService.instance.streamFleet(),
            builder: (context, fleetSnapshot) {
              final fleet = fleetSnapshot.data ?? const <BusFleet>[];
              return SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 28 : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1320),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operations directory',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage the small operational team and keep every bus assignment visible. Student rosters remain in the separate Students section.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _SummaryRow(
                          values: [
                            (
                              'Drivers',
                              drivers,
                              Icons.drive_eta_rounded,
                              AppColors.alertOrange,
                            ),
                            (
                              'Conductors',
                              conductors,
                              Icons.badge_rounded,
                              AppColors.successGreen,
                            ),
                            (
                              'Parents',
                              parents,
                              Icons.family_restroom_rounded,
                              AppColors.safetyBlue,
                            ),
                            (
                              'Unassigned staff',
                              unassigned,
                              Icons.warning_amber_rounded,
                              AppColors.errorRed,
                            ),
                            (
                              'Buses',
                              fleet.length,
                              Icons.directions_bus_rounded,
                              AppColors.safetyBlue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _buildControls(context),
                        const SizedBox(height: 14),
                        if (visible.isEmpty)
                          _EmptyOperationsState(filter: _filter)
                        else
                          _buildUserTable(context, visible, fleet, isDesktop),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search name, email, or bus',
            ),
          ),
        ),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'All', label: Text('All')),
            ButtonSegment(value: 'Driver', label: Text('Drivers')),
            ButtonSegment(value: 'Conductor', label: Text('Conductors')),
            ButtonSegment(value: 'Parent', label: Text('Parents')),
          ],
          selected: {_filter},
          onSelectionChanged: (value) => setState(() => _filter = value.first),
        ),
      ],
    );
  }

  Widget _buildUserTable(
    BuildContext context,
    List<_ManagedUser> users,
    List<BusFleet> fleet,
    bool isDesktop,
  ) {
    if (!isDesktop) {
      return Column(
        children: [
          for (final user in users)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _UserManagementCard(
                user: user,
                onEdit: () => _editUser(context, user, fleet),
              ),
            ),
        ],
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        columnSpacing: 28,
        columns: const [
          DataColumn(label: Text('PERSON')),
          DataColumn(label: Text('ROLE')),
          DataColumn(label: Text('CONTACT')),
          DataColumn(label: Text('BUS ASSIGNMENT')),
          DataColumn(label: Text('ACTION')),
        ],
        rows: users
            .map(
              (user) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(_RoleBadge(role: user.role)),
                  DataCell(Text('${user.email}\n${user.phone ?? 'No phone'}')),
                  DataCell(Text(user.busId ?? 'Unassigned')),
                  DataCell(
                    FilledButton.tonalIcon(
                      onPressed: () => _editUser(context, user, fleet),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _editUser(
    BuildContext context,
    _ManagedUser user,
    List<BusFleet> fleet,
  ) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    String? selectedBus = user.busId;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${user.role}'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                if (user.role == 'Driver' || user.role == 'Conductor') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedBus,
                    decoration: const InputDecoration(
                      labelText: 'Assigned bus',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...fleet.map(
                        (bus) => DropdownMenuItem<String?>(
                          value: bus.busId,
                          child: Text(bus.busId.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (value) => setDialogState(() => selectedBus = value),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    user.role == 'Parent'
                        ? 'Parent-child links are managed by roster import and remain unchanged here.'
                        : 'Changing the bus updates both the user profile and the bus assignment record.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        await AuthService.instance.updateManagedUser(
                          uid: user.uid,
                          name: nameController.text,
                          phone: phoneController.text,
                          busId: selectedBus,
                        );
                        if (user.role == 'Driver' || user.role == 'Conductor') {
                          await _syncBusAssignment(
                            user: user,
                            newBusId: selectedBus,
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                          );
                        }
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (error) {
                        setDialogState(() => saving = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Could not save changes: $error'),
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    phoneController.dispose();
  }

  Future<void> _syncBusAssignment({
    required _ManagedUser user,
    required String? newBusId,
    required String name,
    required String phone,
  }) async {
    if (user.busId != null && user.busId != newBusId) {
      await FirebaseService.instance.updateFleetAssignmentForRole(
        user.busId!,
        role: user.role,
        uid: null,
        name: 'Unassigned',
        phone: null,
      );
    }
    if (newBusId == null || newBusId.isEmpty) return;
    await FirebaseService.instance.updateFleetAssignmentForRole(
      newBusId,
      role: user.role,
      uid: user.uid,
      name: name,
      phone: phone,
    );
  }
}

class _ManagedUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? busId;

  const _ManagedUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.busId,
  });

  factory _ManagedUser.fromMap(String uid, Map<dynamic, dynamic> map) {
    return _ManagedUser(
      uid: uid,
      name: map['name']?.toString().trim().isNotEmpty == true
          ? map['name'].toString()
          : 'Unnamed user',
      email: map['email']?.toString() ?? '---',
      role: map['role']?.toString() ?? 'Unknown',
      phone: map['phone']?.toString(),
      busId: map['busId']?.toString(),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<(String, int, IconData, Color)> values;

  const _SummaryRow({required this.values});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 48) / 5
            : 220.0;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: values
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: item.$4.withValues(alpha: 0.12),
                            foregroundColor: item.$4,
                            child: Icon(item.$3),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.$2}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                item.$1,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _UserManagementCard extends StatelessWidget {
  final _ManagedUser user;
  final VoidCallback onEdit;

  const _UserManagementCard({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${user.role} • ${user.email}\nBus: ${user.busId ?? 'Unassigned'}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = role == 'Driver'
        ? AppColors.alertOrange
        : role == 'Conductor'
        ? AppColors.successGreen
        : AppColors.safetyBlue;
    return Chip(
      label: Text(role),
      avatar: Icon(Icons.person, size: 15, color: color),
      side: BorderSide.none,
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }
}

class _EmptyOperationsState extends StatelessWidget {
  final String filter;

  const _EmptyOperationsState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            filter == 'All'
                ? 'No operational accounts found.'
                : 'No $filter accounts match this search.',
          ),
        ),
      ),
    );
  }
}
