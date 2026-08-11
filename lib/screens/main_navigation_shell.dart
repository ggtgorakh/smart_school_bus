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
      return [
        AuthorizedTab(
          title: 'Student Attendance Scanner',
          screen: const AttendanceScannerScreen(),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Students',
          ),
        ),
        AuthorizedTab(
          title: 'Bus Route Navigation',
          screen: const LiveTrackingScreen(),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
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
          title: 'Student Boarding Manifest',
          screen: const AttendanceScannerScreen(),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Students',
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
          title: 'Live Child Bus Tracking',
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
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.safetyBlue,
          unselectedItemColor: AppColors.outline,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: tabs.map((t) => t.navItem).toList(),
        ),
      ),
    );
  }
}

