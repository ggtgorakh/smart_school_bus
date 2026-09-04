// lib/screens/admin/people_directory_screen.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../theme/app_theme.dart';

class _DirectoryUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? busId;
  final String? phone;

  _DirectoryUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.busId,
    this.phone,
  });

  factory _DirectoryUser.fromMap(String uid, Map<dynamic, dynamic> map) {
    return _DirectoryUser(
      uid: uid,
      name: (map['name']?.toString().trim().isNotEmpty ?? false)
          ? map['name'].toString()
          : 'Unnamed user',
      email: map['email']?.toString() ?? '---',
      role: map['role']?.toString() ?? 'Unknown',
      busId: map['busId']?.toString(),
      phone: map['phone']?.toString(),
    );
  }
}

class PeopleDirectoryScreen extends StatefulWidget {
  final String busId;

  const PeopleDirectoryScreen({super.key, this.busId = 'bus_01'});

  @override
  State<PeopleDirectoryScreen> createState() => _PeopleDirectoryScreenState();
}

class _PeopleDirectoryScreenState extends State<PeopleDirectoryScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final DatabaseReference _root = FirebaseDatabase.instance.ref();
  String _searchQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

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
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text(
          'People Directory',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.safetyBlue,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: AppColors.safetyBlue,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(text: '👨‍👩‍👦 Parents'),
            Tab(text: '🚌 Drivers'),
            Tab(text: '📋 Conductors'),
            Tab(text: '👶 Children'),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Search Bar
              _buildSearchBar(),
              // Tab Bar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _UserRoleList(
                      usersStream: _streamUsersByRole('Parent'),
                      role: 'Parent',
                      searchQuery: _searchQuery,
                    ),
                    _UserRoleList(
                      usersStream: _streamUsersByRole('Driver'),
                      role: 'Driver',
                      searchQuery: _searchQuery,
                    ),
                    _UserRoleList(
                      usersStream: _streamUsersByRole('Conductor'),
                      role: 'Conductor',
                      searchQuery: _searchQuery,
                    ),
                    _ChildrenList(
                      busId: widget.busId,
                      searchQuery: _searchQuery,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search people...',
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
    );
  }

  // ============================================================
  // STREAM USERS BY ROLE
  // ============================================================

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

// ============================================================
// USER ROLE LIST
// ============================================================

class _UserRoleList extends StatelessWidget {
  final Stream<List<_DirectoryUser>> usersStream;
  final String role;
  final String searchQuery;

  const _UserRoleList({
    required this.usersStream,
    required this.role,
    required this.searchQuery,
  });

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

  Color get _roleColor {
    switch (role) {
      case 'Driver':
        return AppColors.alertOrange;
      case 'Conductor':
        return AppColors.successGreen;
      default:
        return AppColors.safetyBlue;
    }
  }

  List<_DirectoryUser> _filterUsers(List<_DirectoryUser> users) {
    if (searchQuery.isEmpty) return users;
    final query = searchQuery.toLowerCase().trim();
    return users.where((user) =>
      user.name.toLowerCase().contains(query) ||
      user.email.toLowerCase().contains(query) ||
      user.uid.toLowerCase().contains(query) ||
      (user.busId?.toLowerCase().contains(query) ?? false)
    ).toList();
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

        final users = _filterUsers(snapshot.data!);

        if (users.isEmpty) {
          if (searchQuery.isNotEmpty) {
            return _EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matching results',
              subtitle: 'Try adjusting your search query',
            );
          }
          return _EmptyState(
            icon: _roleIcon,
            title: 'No $role accounts yet',
            subtitle: role == 'Driver'
                ? 'Provision one from Admin > Add User.'
                : 'None have been provisioned yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {},
          color: AppColors.safetyBlue,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index < users.length - 1 ? 10 : 0),
                child: _UserCard(
                  user: user,
                  role: role,
                  color: _roleColor,
                  icon: _roleIcon,
                  index: index,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ============================================================
// USER CARD
// ============================================================

class _UserCard extends StatelessWidget {
  final _DirectoryUser user;
  final String role;
  final Color color;
  final IconData icon;
  final int index;

  const _UserCard({
    required this.user,
    required this.role,
    required this.color,
    required this.icon,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (user.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.phone!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (role == 'Driver' || role == 'Conductor') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: user.busId != null
                            ? AppColors.mintSoft
                            : AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.busId != null
                                ? Icons.directions_bus_rounded
                                : Icons.warning_amber_rounded,
                            size: 12,
                            color: user.busId != null
                                ? AppColors.successGreen
                                : AppColors.errorRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.busId != null
                                ? 'Assigned: ${user.busId}'
                                : 'No bus assigned',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: user.busId != null
                                  ? AppColors.successGreen
                                  : AppColors.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // UID Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ID: ${user.uid.substring(0, 8)}...',
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
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
}

// ============================================================
// CHILDREN LIST
// ============================================================

class _ChildrenList extends StatelessWidget {
  final String busId;
  final String searchQuery;

  const _ChildrenList({
    required this.busId,
    required this.searchQuery,
  });

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

  List<Student> _filterStudents(List<Student> students) {
    if (searchQuery.isEmpty) return students;
    final query = searchQuery.toLowerCase().trim();
    return students.where((s) =>
      s.name.toLowerCase().contains(query) ||
      s.id.toLowerCase().contains(query) ||
      s.grade.toLowerCase().contains(query) ||
      s.stopName.toLowerCase().contains(query)
    ).toList();
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

        final filteredStudents = _filterStudents(students);

        if (students.isEmpty) {
          return _EmptyState(
            icon: Icons.child_care_rounded,
            title: 'No children on this route yet',
            subtitle: 'The roster for $busId is currently empty.',
          );
        }

        if (filteredStudents.isEmpty) {
          return _EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching children',
            subtitle: 'Try adjusting your search query',
          );
        }

        final unlinkedCount = students.where(
          (s) => s.parentUid == null || s.parentUid!.isEmpty
        ).length;

        return Column(
          children: [
            if (unlinkedCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: AppColors.amberSoft,
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.alertOrangeDark,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$unlinkedCount of ${students.length} children on $busId are not yet linked to a Parent account.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.alertOrangeDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {},
                color: AppColors.safetyBlue,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < filteredStudents.length - 1 ? 10 : 0),
                      child: _ChildCard(
                        student: student,
                        index: index,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// CHILD CARD
// ============================================================

class _ChildCard extends StatelessWidget {
  final Student student;
  final int index;

  const _ChildCard({
    required this.student,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linked = student.parentUid != null && student.parentUid!.isNotEmpty;
    final color = _statusColor(student.status);

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
                      Container(
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
                      ),
                      const SizedBox(width: 8),
                      // Parent Link Badge
                      Container(
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
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Student ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ID: ${student.id}',
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
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
}

// ============================================================
// EMPTY STATE
// ============================================================

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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}