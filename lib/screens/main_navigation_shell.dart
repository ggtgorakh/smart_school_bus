// lib/screens/main_navigation_shell.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';  // ← ADD THIS IMPORT
import '../widgets/app_header.dart';
import '../services/session_service.dart';
import '../widgets/notification_badge.dart';
import 'live_tracking_screen.dart';
import 'boarding_status_screen.dart';
import 'fleet_management_screen.dart';
import 'route_planning_screen.dart';
import 'profile_screen.dart';
import 'attendance_scanner_screen.dart';
import 'notifications_screen.dart';

class AuthorizedTab {
  final String title;
  final Widget screen;
  final BottomNavigationBarItem navItem;

  AuthorizedTab({
    required this.title,
    required this.screen,
    required this.navItem,
  });
}

class MainNavigationShell extends StatefulWidget {
  final String userRole;
  final String busId;
  final VoidCallback onSignOut;

  const MainNavigationShell({
    super.key,
    required this.userRole,
    this.busId = 'bus_01',
    required this.onSignOut,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _restoreTabIndex();
  }

  Future<void> _restoreTabIndex() async {
    final saved = await SessionService.instance.getTabIndex();
    if (!mounted) return;
    setState(() => _currentIndex = saved);
  }

  List<AuthorizedTab> _buildAuthorizedTabs() {
    final role = widget.userRole;

    if (role == 'Driver') {
      return [
        AuthorizedTab(
          title: 'Bus Route Navigation',
          screen: LiveTrackingScreen(busId: widget.busId),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Route',
          ),
        ),
        AuthorizedTab(
          title: 'Driver Profile',
          screen: ProfileScreen(
            activeRole: role,
            onSignOut: widget.onSignOut,
          ),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ),
      ];
    }

    if (role == 'Conductor') {
      return [
        AuthorizedTab(
          title: 'Student Check-in / Check-out',
          screen: AttendanceScannerScreen(busId: widget.busId),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg_outlined),
            activeIcon: Icon(Icons.how_to_reg),
            label: 'Students',
          ),
        ),
        AuthorizedTab(
          title: 'Bus Route Map',
          screen: LiveTrackingScreen(busId: widget.busId),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ),
        AuthorizedTab(
          title: 'Conductor Profile',
          screen: ProfileScreen(
            activeRole: role,
            onSignOut: widget.onSignOut,
          ),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ),
      ];
    }

    if (role == 'Admin') {
      return [
        AuthorizedTab(
          title: 'Fleet Management Overview',
          screen: const FleetManagementScreen(),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_outlined),
            activeIcon: Icon(Icons.directions_bus),
            label: 'Fleet',
          ),
        ),
        AuthorizedTab(
          title: 'Route Planning & Dispatch',
          screen: const RoutePlanningScreen(),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.alt_route_outlined),
            activeIcon: Icon(Icons.alt_route),
            label: 'Routes',
          ),
        ),
        AuthorizedTab(
          title: 'Master GPS Bus Tracking',
          screen: LiveTrackingScreen(busId: widget.busId),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ),
        AuthorizedTab(
          title: 'Admin System Profile',
          screen: ProfileScreen(
            activeRole: role,
            onSignOut: widget.onSignOut,
          ),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ),
      ];
    }

    // Parent
    return [
      AuthorizedTab(
        title: 'Child Boarding Status',
        screen: const BoardingStatusScreen(),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.info_outlined),
          activeIcon: Icon(Icons.info),
          label: 'Status',
        ),
      ),
      AuthorizedTab(
        title: 'Live Bus Tracking',
        screen: LiveTrackingScreen(busId: widget.busId),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Map',
        ),
      ),
      AuthorizedTab(
        title: 'Parent Profile',
        screen: ProfileScreen(
          activeRole: role,
          onSignOut: widget.onSignOut,
        ),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppHeader(title: 'Smart School Bus'),
      body: Row(
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
                constraints: const BoxConstraints(maxWidth: 1280),
                child: IndexedStack(
                  index: safeIndex,
                  children: tabs.map((tab) => tab.screen).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(8, 3, 8, 5),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BottomNavigationBar(
                    currentIndex: safeIndex,
                    onTap: _selectTab,
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: scheme.surface,
                    elevation: 0,
                    selectedItemColor: scheme.primary,
                    unselectedItemColor: scheme.onSurfaceVariant,
                    selectedLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 10.5),
                    items: tabs.map((tab) => tab.navItem).toList(),
                  ),
                ),
              ),
            ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Smart Bus',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: scheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                role.toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 1.1),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: tabs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = tabs[index].navItem;
                final selected = index == currentIndex;

                return Material(
                  color: selected ? scheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => onSelect(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? (item.activeIcon as Icon).icon
                                : (item.icon as Icon).icon,
                            size: 19,
                            color: selected ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              item.label ?? tabs[index].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected ? scheme.primary : scheme.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}