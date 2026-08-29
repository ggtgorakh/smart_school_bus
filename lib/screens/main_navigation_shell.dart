import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../services/session_service.dart';
import 'live_tracking_screen.dart';
import 'boarding_status_screen.dart';
import 'attendance_scanner_screen.dart';
import 'fleet_management_screen.dart';
import 'route_planning_screen.dart';
import 'profile_screen.dart';

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
  // Bug #4 fix: the bus this session is scoped to. For a Driver this is
  // their assigned bus (from /users/{uid}/busId); other roles default to
  // 'bus_01' to preserve current single-bus behavior.
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
    // _buildAuthorizedTabs() below clamps out-of-range indexes too, but
    // guard here as well in case the saved index came from a role with
    // more tabs than the current one.
    setState(() {
      _currentIndex = saved;
    });
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
          title: 'Student Check-in/Check-out',
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

    // Default: Parent
    return [
      AuthorizedTab(
        title: 'Child Boarding Status',
        screen: BoardingStatusScreen(),
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

  @override
  Widget build(BuildContext context) {
    final tabs = _buildAuthorizedTabs();

    final safeIndex =
    _currentIndex >= tabs.length ? 0 : _currentIndex;

    return Scaffold(
      appBar: AppHeader(
        title: tabs[safeIndex].title,
      ),

      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((tab) => tab.screen).toList(),
      ),

      // SafeArea prevents the bottom navigation from colliding
      // with Android's gesture/navigation area.
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        minimum: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 8,
        ),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BottomNavigationBar(
              currentIndex: safeIndex,

              onTap: (index) {
                if (index == safeIndex) return;

                setState(() {
                  _currentIndex = index;
                });
                SessionService.instance.saveTabIndex(index);
              },

              type: BottomNavigationBarType.fixed,

              backgroundColor: Colors.white,

              elevation: 0,

              selectedItemColor: AppColors.safetyBlue,

              unselectedItemColor: AppColors.outline,

              selectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),

              unselectedLabelStyle: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),

              items: tabs.map((tab) => tab.navItem).toList(),
            ),
          ),
        ),
      ),
    );
  }
}