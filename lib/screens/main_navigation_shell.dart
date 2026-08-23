import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import 'live_tracking_screen.dart';
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
  final VoidCallback onSignOut;

  const MainNavigationShell({
    super.key,
    required this.userRole,
    required this.onSignOut,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  List<AuthorizedTab> _buildAuthorizedTabs() {
    final role = widget.userRole;

    if (role == 'Driver') {
      // Driver now only sees navigation (conductor handles attendance)
      return [
        AuthorizedTab(
          title: 'Bus Route Navigation',
          screen: const LiveTrackingScreen(),
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
    } else if (role == 'Conductor') {
      // Conductor handles manual student check-in/check-out
      return [
        AuthorizedTab(
          title: 'Student Check-in/Check-out',
          screen: const AttendanceScannerScreen(),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg_outlined),
            activeIcon: Icon(Icons.how_to_reg),
            label: 'Students',
          ),
        ),
        AuthorizedTab(
          title: 'Bus Route Map',
          screen: const LiveTrackingScreen(),
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
    } else if (role == 'Admin') {
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
          screen: const LiveTrackingScreen(),
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
    } else {
      // Default: Parent Role
      return [
        AuthorizedTab(
          title: 'Child Boarding Status',
          screen: const LiveTrackingScreen(),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.info_outlined),
            activeIcon: Icon(Icons.info),
            label: 'Status',
          ),
        ),
        AuthorizedTab(
          title: 'Live Bus Tracking',
          screen: const LiveTrackingScreen(),
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
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildAuthorizedTabs();
    final safeIndex = _currentIndex >= tabs.length ? 0 : _currentIndex;

    return Scaffold(
      appBar: AppHeader(
        title: tabs[safeIndex].title,
      ),
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        decoration: const BoxDecoration(color: Colors.transparent),
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
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: AppColors.safetyBlue,
              unselectedItemColor: AppColors.outline,
              selectedLabelStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              items: tabs.map((t) => t.navItem).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

