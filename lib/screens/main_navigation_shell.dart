// lib/screens/main_navigation_shell.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../services/session_service.dart';
import 'live_tracking_screen.dart';
import 'boarding_status_screen.dart';
import 'fleet_management_screen.dart';
import 'profile_screen.dart';
import 'attendance_scanner_screen.dart';
import 'route_planning_screen.dart';

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
    this.busId = 'bus_01',
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

    // Driver Tabs
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
          icon: Icons.map_outlined,
          activeIcon: Icons.map,
        ),
        AuthorizedTab(
          title: 'Driver Profile',
          screen: ProfileScreen(activeRole: role, onSignOut: widget.onSignOut),
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

    // Conductor Tabs
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
          icon: Icons.how_to_reg_outlined,
          activeIcon: Icons.how_to_reg,
        ),
        AuthorizedTab(
          title: 'Bus Route Map',
          screen: LiveTrackingScreen(busId: widget.busId),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          icon: Icons.map_outlined,
          activeIcon: Icons.map,
        ),
        AuthorizedTab(
          title: 'Conductor Profile',
          screen: ProfileScreen(activeRole: role, onSignOut: widget.onSignOut),
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

    // Admin Tabs
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
          icon: Icons.directions_bus_outlined,
          activeIcon: Icons.directions_bus,
        ),
        AuthorizedTab(
          title: 'Master GPS Bus Tracking',
          screen: LiveTrackingScreen(busId: widget.busId),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          icon: Icons.map_outlined,
          activeIcon: Icons.map,
        ),
        AuthorizedTab(
          title: 'Route Planning',
          screen: const RoutePlanningScreen(),
          navItem: const BottomNavigationBarItem(
            icon: Icon(Icons.alt_route_outlined),
            activeIcon: Icon(Icons.alt_route),
            label: 'Routes',
          ),
          icon: Icons.alt_route_outlined,
          activeIcon: Icons.alt_route,
        ),
        AuthorizedTab(
          title: 'Admin System Profile',
          screen: ProfileScreen(activeRole: role, onSignOut: widget.onSignOut),
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

    // Parent Tabs (Default)
    return [
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
        title: 'Live Bus Tracking',
        screen: LiveTrackingScreen(busId: widget.busId),
        navItem: const BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Map',
        ),
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
      ),
      AuthorizedTab(
        title: 'Parent Profile',
        screen: ProfileScreen(activeRole: role, onSignOut: widget.onSignOut),
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

    return Scaffold(
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
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: IndexedStack(
                    index: safeIndex,
                    children: [
                      for (int i = 0; i < tabs.length; i++)
                        TickerMode(
                          // Only the visible tab's animations should keep
                          // ticking. Without this, every AnimationController
                          // that calls .repeat() (map pulse, tracking pulse,
                          // etc.) keeps running forever in the background on
                          // every hidden tab at once, since IndexedStack
                          // keeps all children mounted — that's what was
                          // flooding the render pipeline (BLASTBufferQueue
                          // "can't acquire next buffer" warnings).
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
      bottomNavigationBar: isDesktop
          ? null
          : _buildMobileBottomNav(tabs, safeIndex, scheme),
    );
  }

  // ============================================================
  // MOBILE BOTTOM NAVIGATION
  // ============================================================

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
          // Sidebar Header
          _buildSidebarHeader(scheme),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),

          // Role Badge
          _buildRoleBadge(scheme),

          // Navigation Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.tabs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
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

          // Footer
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.safetyBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Bus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                'Fleet Management',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              widget.role.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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

// ============================================================
// SIDEBAR NAVIGATION ITEM
// ============================================================

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
                // Icon Container with Animation
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
                    widget.isSelected ? widget.tab.activeIcon : widget.tab.icon,
                    size: widget.isSelected ? 20 : 22,
                    color: widget.isSelected
                        ? scheme.primary
                        : _isHovered
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                // Label
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
                // Selected Indicator
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
