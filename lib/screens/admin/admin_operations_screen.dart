// lib/screens/admin/admin_operations_screen.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../models/bus_fleet.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../services/device_class_guard.dart';
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

  bool get _laptop => isLaptopActionAllowed();

  Stream<List<_ManagedUser>> _usersStream() {
    return _users.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <_ManagedUser>[];
      final users = <_ManagedUser>[];
      value.forEach((uid, raw) {
        if (raw is Map) {
          final user = _ManagedUser.fromMap(uid.toString(), raw);
          if (user.role == 'Driver' || user.role == 'Conductor') {
            users.add(user);
          }
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
      final queryMatch = query.isEmpty ||
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
          if (_laptop)
            IconButton(
              tooltip: 'Add account',
              icon: const Icon(Icons.person_add_alt_1_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminCreateUserScreen(),
                ),
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
                        // ============================================
                        // FLEET ASSIGNMENTS CARD
                        // ============================================
                        _buildFleetAssignmentsCard(context, fleet),
                        const SizedBox(height: 28),

                        // ============================================
                        // OPERATIONS DIRECTORY
                        // ============================================
                        Text(
                          'Operations directory',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _laptop
                              ? 'Manage drivers, conductors, and their bus assignments. Parent and student records are handled in the Students section.'
                              : 'Read-only view of drivers, conductors, and their bus assignments. Edits must be made from a laptop.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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
                          _buildUserList(context, visible, fleet, isDesktop),
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

  /// A compact summary of all buses in the fleet, showing which are
  /// assigned and which are idle.
  Widget _buildFleetAssignmentsCard(
    BuildContext context,
    List<BusFleet> fleet,
  ) {
    if (fleet.isEmpty) {
      return const SizedBox.shrink();
    }

    final assignedCount =
        fleet.where((b) => b.driverName != 'Unassigned').length;
    final idleCount = fleet.length - assignedCount;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.safetyBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.safetyBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fleet Assignments',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$assignedCount assigned • $idleCount idle',
                        style: TextStyle(
                          fontSize: 12.5,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Grid: 5 columns on wide, fewer as width shrinks.
                final columns = constraints.maxWidth >= 1100
                    ? 5
                    : constraints.maxWidth >= 800
                        ? 4
                        : constraints.maxWidth >= 550
                            ? 3
                            : 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: fleet.map((bus) {
                    final width =
                        (constraints.maxWidth - (columns - 1) * 10) / columns;
                    return SizedBox(
                      width: width,
                      child: _BusTile(bus: bus),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
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
            ButtonSegment(value: 'Driver', label: Text('Driver')),
            ButtonSegment(value: 'Conductor', label: Text('Conductor')),
          ],
          selected: {_filter},
          onSelectionChanged: (value) =>
              setState(() => _filter = value.first),
          showSelectedIcon: false,
        ),
      ],
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<_ManagedUser> users,
    List<BusFleet> fleet,
    bool isDesktop,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTable = isDesktop && constraints.maxWidth >= 950;
        if (!useTable) {
          return Column(
            children: [
              for (final user in users)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _UserManagementCard(
                    user: user,
                    onEdit: _laptop
                        ? () => _editUser(context, user, fleet)
                        : null,
                  ),
                ),
            ],
          );
        }
        return _buildUserTable(context, users, fleet);
      },
    );
  }

  Widget _buildUserTable(
    BuildContext context,
    List<_ManagedUser> users,
    List<BusFleet> fleet,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 16,
                headingRowHeight: 44,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 60,
                columns: const [
                  DataColumn(label: Text('PERSON')),
                  DataColumn(label: Text('ROLE')),
                  DataColumn(label: Text('CONTACT')),
                  DataColumn(label: Text('BUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: users
                    .map(
                      (user) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataCell(_RoleBadge(role: user.role)),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    user.phone ?? 'No phone',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              user.busId?.toUpperCase() ?? 'Unassigned',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            FilledButton.tonalIcon(
                              onPressed: _laptop
                                  ? () => _editUser(context, user, fleet)
                                  : null,
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                              ),
                              label: const Text('Edit'),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editUser(
    BuildContext context,
    _ManagedUser user,
    List<BusFleet> fleet,
  ) async {
    if (!_laptop) return;
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    enabled: !saving,
                    decoration:
                        const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    enabled: !saving,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  if (user.role == 'Driver' ||
                      user.role == 'Conductor') ...[
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
                          : (value) =>
                              setDialogState(() => selectedBus = value),
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
                        if (user.role == 'Driver' ||
                            user.role == 'Conductor') {
                          await _syncBusAssignment(
                            user: user,
                            newBusId: selectedBus,
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                          );
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (error) {
                        setDialogState(() => saving = false);
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not save changes: $error',
                              ),
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

class _BusTile extends StatelessWidget {
  final BusFleet bus;

  const _BusTile({required this.bus});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAssigned = bus.driverName != 'Unassigned';
    final accent = isAssigned ? AppColors.successGreen : AppColors.outline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: isAssigned ? 0.3 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_bus_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  bus.busId.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isAssigned ? 'ACTIVE' : 'IDLE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAssigned ? bus.driverName : 'No driver assigned',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isAssigned
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
              fontStyle:
                  isAssigned ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          if (isAssigned && bus.routeName != 'No route assigned') ...[
            const SizedBox(height: 2),
            Text(
              bus.routeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
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
                            backgroundColor:
                                item.$4.withValues(alpha: 0.12),
                            foregroundColor: item.$4,
                            child: Icon(item.$3),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.$2}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                item.$1,
                                style:
                                    Theme.of(context).textTheme.bodySmall,
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
  final VoidCallback? onEdit;

  const _UserManagementCard({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _RoleBadge(role: user.role),
                  const SizedBox(width: 8),
                  if (user.busId != null && user.busId!.isNotEmpty)
                    Text(
                      user.busId!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5),
              ),
              if (user.phone != null && user.phone!.isNotEmpty)
                Text(
                  user.phone!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        trailing: onEdit == null
            ? null
            : IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            role,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
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
                ? 'No drivers or conductors found.'
                : 'No $filter accounts match this search.',
          ),
        ),
      ),
    );
  }
}