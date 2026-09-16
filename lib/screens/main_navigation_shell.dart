// lib/screens/main_navigation_shell.dart

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/app_header.dart';
import '../services/session_service.dart';
import 'live_tracking_screen.dart';
import 'boarding_status_screen.dart';
import 'fleet_management_screen.dart';
import 'profile_screen.dart';
import 'manual_attendance_screen.dart';
import 'parent_tracking_screen.dart';
import 'parent_people_screen.dart';
import 'trip_workflow_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_operations_screen.dart';
import 'admin/admin_bus_operations_screen.dart';
import 'admin/admin_students_overview_screen.dart';
import 'admin/admin_alerts_screen.dart';
import 'admin_fleet_tracking_screen.dart';

class AuthorizedTab {
  final String title;
  final Widget screen;
  final BottomNavigationBarItem navItem;
  final IconData icon;
  final IconData activeIcon;

  AuthorizedTab({
    required this.title,
    required this.screen,
    required this.navItem,
    required this.icon,
    required this.activeIcon,
  });
}

class MainNavigationShell extends StatefulWidget {
  final String userRole;
  final String busId;
  final VoidCallback onSignOut;

  const MainNavigationShell({
    super.key,
    required this.userRole,
    required this.busId,
    required this.onSignOut,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _restoreTabIndex();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _restoreTabIndex() async {
    final saved = await SessionService.instance.getTabIndex();
    if (!mounted) return;
    setState(() => _currentIndex = saved);
  }

  List<AuthorizedTab> _buildAuthorizedTabs() {
    final role = widget.userRole;

    if (role == 'Driver') return _driverTabs();
    if (role == 'Conductor') return _conductorTabs();
    if (role == 'Admin') return _adminTabs();
    return _parentTabs();
  }

  // ============================================================
  // DRIVER — 4 tabs
  // Order: Route, Trip, Students, Profile
  // ============================================================
  List<AuthorizedTab> _driverTabs() {
    return [
      AuthorizedTab(
        title: 'Bus Route Navigation',
        screen: LiveTrackingScreen(busId: widget.busId, canCallDriver: false),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Route',
        ),
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
      ),
      AuthorizedTab(
        title: 'Driver Trip Operations',
        screen: TripWorkflowScreen(busId: widget.busId, role: 'Driver'),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.route_outlined),
          activeIcon: Icon(Icons.route),
          label: 'Trip',
        ),
        icon: Icons.route_outlined,
        activeIcon: Icons.route,
      ),
      AuthorizedTab(
        title: 'Driver Student Attendance',
        screen: ManualAttendanceScreen(busId: widget.busId),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.how_to_reg_outlined),
          activeIcon: Icon(Icons.how_to_reg),
          label: 'Students',
        ),
        icon: Icons.how_to_reg_outlined,
        activeIcon: Icons.how_to_reg,
      ),
      AuthorizedTab(
        title: 'Driver Profile',
        screen: ProfileScreen(
          activeRole: 'Driver',
          onSignOut: widget.onSignOut,
        ),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        icon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
    ];
  }

  // ============================================================
  // CONDUCTOR — 4 tabs
  // Order: Students, Map, Trip, Profile
  // ============================================================
  List<AuthorizedTab> _conductorTabs() {
    return [
      AuthorizedTab(
        title: 'Student Check-in / Check-out',
        screen: ManualAttendanceScreen(busId: widget.busId),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.how_to_reg_outlined),
          activeIcon: Icon(Icons.how_to_reg),
          label: 'Students',
        ),
        icon: Icons.how_to_reg_outlined,
        activeIcon: Icons.how_to_reg,
      ),
      AuthorizedTab(
        title: 'Bus Route Map',
        screen: LiveTrackingScreen(busId: widget.busId, canCallDriver: false),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Map',
        ),
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
      ),
      AuthorizedTab(
        title: 'Conductor Trip Status',
        screen: TripWorkflowScreen(busId: widget.busId, role: 'Conductor'),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.route_outlined),
          activeIcon: Icon(Icons.route),
          label: 'Trip',
        ),
        icon: Icons.route_outlined,
        activeIcon: Icons.route,
      ),
      AuthorizedTab(
        title: 'Conductor Profile',
        screen: ProfileScreen(
          activeRole: 'Conductor',
          onSignOut: widget.onSignOut,
        ),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        icon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
    ];
  }

  // ============================================================
  // ADMIN
  //
  // Laptop: 8 tabs — Dashboard, Fleet, Ops, Staff, Students,
  //         Map, Alerts, Profile
  // Mobile: 4 tabs — Dashboard, Alerts, Map, Profile
  // ============================================================
  List<AuthorizedTab> _adminTabs() {
    final laptop = isLaptopPlatform();

    final dashboard = AuthorizedTab(
      title: 'Dashboard',
      screen: const AdminDashboardScreen(),
      navItem: const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Home',
      ),
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
    );

    final alerts = AuthorizedTab(
      title: 'Alerts & Emergencies',
      screen: const AdminAlertsScreen(),
      navItem: const BottomNavigationBarItem(
        icon: Icon(Icons.notifications_active_outlined),
        activeIcon: Icon(Icons.notifications_active),
        label: 'Alerts',
      ),
      icon: Icons.notifications_active_outlined,
      activeIcon: Icons.notifications_active,
    );

    final map = AuthorizedTab(
      title: 'Fleet Map',
      screen: const AdminFleetTrackingScreen(),
      navItem: const BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map),
        label: 'Map',
      ),
      icon: Icons.map_outlined,
      activeIcon: Icons.map,
    );

    final profile = AuthorizedTab(
      title: 'Admin Profile',
      screen: ProfileScreen(
        activeRole: 'Admin',
        onSignOut: widget.onSignOut,
      ),
      navItem: const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    );

    if (!laptop) {
      // Mobile: read-only + emergency handling only.
      return [dashboard, alerts, map, profile];
    }

    // Laptop: full operational set.
    return [
      dashboard,
      AuthorizedTab(
        title: 'Fleet Operations',
        screen: const FleetManagementScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus_outlined),
          activeIcon: Icon(Icons.directions_bus),
          label: 'Fleet',
        ),
        icon: Icons.directions_bus_outlined,
        activeIcon: Icons.directions_bus,
      ),
      AuthorizedTab(
        title: 'Bus Operations & Routes',
        screen: const AdminBusOperationsScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.alt_route_outlined),
          activeIcon: Icon(Icons.alt_route),
          label: 'Ops',
        ),
        icon: Icons.alt_route_outlined,
        activeIcon: Icons.alt_route,
      ),
      AuthorizedTab(
        title: 'Drivers & Conductors',
        screen: const AdminOperationsScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          activeIcon: Icon(Icons.groups),
          label: 'Staff',
        ),
        icon: Icons.groups_outlined,
        activeIcon: Icons.groups,
      ),
      AuthorizedTab(
        title: 'All Students',
        screen: const AdminStudentsOverviewScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Students',
        ),
        icon: Icons.school_outlined,
        activeIcon: Icons.school,
      ),
      map,
      alerts,
      profile,
    ];
  }

  // ============================================================
  // PARENT — 4 tabs
  // Order: Map, Status, Children, Profile
  //
  // Previously 5 tabs (Status, Map, Children, Staff, Profile).
  // "Staff" has been folded into "Children" — both answer the same
  // question, "who is connected to my child?". Reaching 4 tabs keeps
  // the bar legible on narrow phones.
  // ============================================================
  List<AuthorizedTab> _parentTabs() {
    return [
      AuthorizedTab(
        title: 'Live Bus Tracking',
        screen: const ParentTrackingScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Map',
        ),
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
      ),
      AuthorizedTab(
        title: 'Child Boarding Status',
        screen: const BoardingStatusScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.info_outlined),
          activeIcon: Icon(Icons.info),
          label: 'Status',
        ),
        icon: Icons.info_outlined,
        activeIcon: Icons.info,
      ),
      AuthorizedTab(
        title: 'My Children',
        screen: const ParentPeopleScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.family_restroom_outlined),
          activeIcon: Icon(Icons.family_restroom),
          label: 'Children',
        ),
        icon: Icons.family_restroom_outlined,
        activeIcon: Icons.family_restroom,
      ),
      AuthorizedTab(
        title: 'Parent Profile',
        screen: ProfileScreen(
          activeRole: 'Parent',
          onSignOut: widget.onSignOut,
        ),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        icon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
    ];
  }

  void _selectTab(int index) {
    final tabs = _buildAuthorizedTabs();
    if (index < 0 || index >= tabs.length) return;
    setState(() => _currentIndex = index);
    SessionService.instance.saveTabIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildAuthorizedTabs();
    final safeIndex = _currentIndex >= tabs.length ? 0 : _currentIndex;
    final isDesktop = context.isDesktop;
    final scheme = Theme.of(context).colorScheme;

    // Keyboard-up detection: when the keyboard is on screen we hide the
    // bottom nav so the form has the full viewport. This is the standard
    // pattern (WhatsApp, Gmail, Slack all do this) and it eliminates the
    // class of bugs where the nav competes with a form for vertical
    // space. resizeToAvoidBottomInset is disabled on the outer Scaffold
    // so the shell itself doesn't try to resize — inner screens manage
    // their own insets.
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const AppHeader(title: 'Smart School Bus'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            if (isDesktop)
              _DesktopSidebar(
                tabs: tabs,
                currentIndex: safeIndex,
                role: widget.userRole,
                onSelect: _selectTab,
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: IndexedStack(
                    index: safeIndex,
                    children: [
                      for (int i = 0; i < tabs.length; i++)
                        TickerMode(
                          enabled: i == safeIndex,
                          child: tabs[i].screen,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (isDesktop || keyboardUp)
          ? null
          : _buildMobileBottomNav(tabs, safeIndex, scheme),
    );
  }

  Widget _buildMobileBottomNav(
    List<AuthorizedTab> tabs,
    int safeIndex,
    ColorScheme scheme,
  ) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(8, 3, 8, 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: _selectTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: scheme.surface,
            elevation: 0,
            selectedItemColor: scheme.primary,
            unselectedItemColor: scheme.onSurfaceVariant,
            selectedLabelStyle: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            items: tabs.map((tab) {
              final isSelected = tabs.indexOf(tab) == safeIndex;
              return BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tab.icon, size: isSelected ? 22 : 24),
                ),
                activeIcon: Icon(
                  tab.activeIcon,
                  size: 24,
                  color: scheme.primary,
                ),
                label: tab.navItem.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DESKTOP SIDEBAR
// ============================================================

class _DesktopSidebar extends StatefulWidget {
  final List<AuthorizedTab> tabs;
  final int currentIndex;
  final String role;
  final ValueChanged<int> onSelect;

  const _DesktopSidebar({
    required this.tabs,
    required this.currentIndex,
    required this.role,
    required this.onSelect,
  });

  @override
  State<_DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<_DesktopSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.tabs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final tab = widget.tabs[index];
                final isSelected = index == widget.currentIndex;
                return _SidebarNavItem(
                  tab: tab,
                  isSelected: isSelected,
                  index: index,
                  onTap: () => widget.onSelect(index),
                );
              },
            ),
          ),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successGreen,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Online',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'All systems operational',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final AuthorizedTab tab;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.tab,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: widget.isSelected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          onHover: (value) => setState(() => _isHovered = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: widget.isSelected
                  ? Border.all(color: scheme.primary.withValues(alpha: 0.2))
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(widget.isSelected ? 8 : 0),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? scheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isSelected
                        ? widget.tab.activeIcon
                        : widget.tab.icon,
                    size: widget.isSelected ? 20 : 22,
                    color: widget.isSelected
                        ? scheme.primary
                        : _isHovered
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.tab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: widget.isSelected
                          ? scheme.primary
                          : _isHovered
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
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