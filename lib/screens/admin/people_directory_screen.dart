import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../theme/app_theme.dart';

/// A lightweight read model for a row in /users. Kept local to this screen
/// since the rest of the app only ever needs role/busId individually
/// (via AuthService), not a full listable user record.
class _DirectoryUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? busId;

  _DirectoryUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.busId,
  });

  factory _DirectoryUser.fromMap(String uid, Map<dynamic, dynamic> map) {
    return _DirectoryUser(
      uid: uid,
      name: (map['name']?.toString().trim().isNotEmpty ?? false)
          ? map['name'].toString()
          : 'Unnamed user',
      email: map['email']?.toString() ?? '—',
      role: map['role']?.toString() ?? 'Unknown',
      busId: map['busId']?.toString(),
    );
  }
}

/// Admin-only screen listing everyone in the system, grouped by role, plus
/// the student roster for the fleet's bus.
///
/// Data sources (both real Firebase reads, no mock data):
/// - /users -> Parents, Drivers, Conductors, Admins
/// - /studentRosters/{busId} -> Children (moved out of /buses/{busId} —
///   see database.rules.json for why: RTDB read grants cascade downward,
///   so nesting the roster under /buses made it impossible to scope
///   roster access separately from bus telemetry)
///
/// Each child record may now carry a `parentUid` linking it to a Parent
/// account (see Student model + FirebaseService.upsertStudent). This
/// screen shows that link where present, and flags children that are
/// still unlinked.
class PeopleDirectoryScreen extends StatefulWidget {
  final String busId;

  const PeopleDirectoryScreen({super.key, this.busId = 'bus_01'});

  @override
  State<PeopleDirectoryScreen> createState() => _PeopleDirectoryScreenState();
}

class _PeopleDirectoryScreenState extends State<PeopleDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        foregroundColor: AppColors.textMain,
        title: const Text(
          'People Directory',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.safetyBlue,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.safetyBlue,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Parents'),
            Tab(text: 'Drivers'),
            Tab(text: 'Conductors'),
            Tab(text: 'Children'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UserRoleList(usersStream: _streamUsersByRole('Parent'), role: 'Parent'),
          _UserRoleList(usersStream: _streamUsersByRole('Driver'), role: 'Driver'),
          _UserRoleList(usersStream: _streamUsersByRole('Conductor'), role: 'Conductor'),
          _ChildrenList(busId: widget.busId),
        ],
      ),
    );
  }

  /// Streams all /users records and filters client-side by [role].
  /// (The dataset is small — a school's worth of parents/staff — so a
  /// single full-collection listener plus client-side filtering is simpler
  /// and cheaper than maintaining per-role indexes in RTDB.)
  Stream<List<_DirectoryUser>> _streamUsersByRole(String role) {
    return _root.child('users').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <_DirectoryUser>[];

      final List<_DirectoryUser> result = [];
      raw.forEach((uid, value) {
        if (value is Map) {
          final user = _DirectoryUser.fromMap(uid.toString(), value);
          if (user.role == role) result.add(user);
        }
      });
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return result;
    });
  }
}

class _UserRoleList extends StatelessWidget {
  final Stream<List<_DirectoryUser>> usersStream;
  final String role;

  const _UserRoleList({required this.usersStream, required this.role});

  IconData get _roleIcon {
    switch (role) {
      case 'Driver':
        return Icons.airport_shuttle_rounded;
      case 'Conductor':
        return Icons.badge_rounded;
      default:
        return Icons.family_restroom_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_DirectoryUser>>(
      stream: usersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EmptyState(
            icon: Icons.wifi_off_rounded,
            title: "Can't load $role accounts",
            subtitle: 'Firebase error: ${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.safetyBlue),
          );
        }

        final users = snapshot.data!;
        if (users.isEmpty) {
          return _EmptyState(
            icon: _roleIcon,
            title: 'No $role accounts yet',
            subtitle: role == 'Driver'
                ? 'Provision one from Admin > Add User.'
                : 'None have been provisioned yet.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final user = users[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surfaceContainer,
                    child: Icon(_roleIcon, color: AppColors.safetyBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (role == 'Driver') ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: user.busId != null
                                  ? AppColors.mintSoft
                                  : AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.busId != null
                                  ? 'Assigned: ${user.busId}'
                                  : 'No bus assigned',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: user.busId != null
                                    ? const Color(0xFF0E7A4E)
                                    : AppColors.errorRed,
                              ),
                            ),
                          ),
                        ],
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
}

class _ChildrenList extends StatelessWidget {
  final String busId;

  const _ChildrenList({required this.busId});

  Color _statusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.boarded:
        return AppColors.successGreen;
      case StudentStatus.alert:
        return AppColors.errorRed;
      case StudentStatus.pending:
        return AppColors.alertOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final root = FirebaseDatabase.instance.ref();

    return StreamBuilder(
      stream: root.child('studentRosters/$busId').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.hasError) {
          return _EmptyState(
            icon: Icons.wifi_off_rounded,
            title: "Can't load children",
            subtitle: 'Firebase error: ${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.safetyBlue),
          );
        }

        final raw = snapshot.data!.snapshot.value;
        final List<Student> students = [];
        if (raw is Map) {
          raw.forEach((key, val) {
            if (val is Map) {
              students.add(Student.fromMap(val, id: key.toString()));
            }
          });
          students.sort((a, b) => a.id.compareTo(b.id));
        }

        if (students.isEmpty) {
          return const _EmptyState(
            icon: Icons.child_care_rounded,
            title: 'No children on this route yet',
            subtitle: 'The roster for this bus is currently empty.',
          );
        }

        final unlinkedCount =
            students.where((s) => s.parentUid == null || s.parentUid!.isEmpty).length;

        return Column(
          children: [
            if (unlinkedCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: AppColors.amberSoft,
                child: Text(
                  '$unlinkedCount of ${students.length} children on $busId '
                  'are not yet linked to a Parent account.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.alertOrangeDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.surfaceContainer,
                          backgroundImage: student.photoUrl.isNotEmpty
                              ? NetworkImage(student.photoUrl)
                              : null,
                          child: student.photoUrl.isEmpty
                              ? const Icon(Icons.person, color: AppColors.safetyBlue)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${student.grade} · ${student.seat} · ${student.stopName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    (student.parentUid != null &&
                                            student.parentUid!.isNotEmpty)
                                        ? Icons.link_rounded
                                        : Icons.link_off_rounded,
                                    size: 12,
                                    color: (student.parentUid != null &&
                                            student.parentUid!.isNotEmpty)
                                        ? AppColors.successGreen
                                        : AppColors.errorRed,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (student.parentUid != null &&
                                            student.parentUid!.isNotEmpty)
                                        ? 'Linked to a Parent account'
                                        : 'Not linked to a Parent',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: (student.parentUid != null &&
                                              student.parentUid!.isNotEmpty)
                                          ? AppColors.successGreen
                                          : AppColors.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(student.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            student.status.name[0].toUpperCase() +
                                student.status.name.substring(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(student.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.outline),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}