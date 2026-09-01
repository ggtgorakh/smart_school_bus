// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';

class DashboardScreen extends StatefulWidget {
  final String userRole;
  final String busId;

  const DashboardScreen({
    super.key,
    required this.userRole,
    this.busId = 'bus_01',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                _buildWelcomeHeader(),
                const SizedBox(height: 20),
                
                // KPI Grid
                _buildKpiGrid(),
                const SizedBox(height: 20),
                
                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 20),
                
                // Recent Activity
                _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME HEADER
  // ============================================================

  Widget _buildWelcomeHeader() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.safetyBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning!',
                      style: TextStyle(
                        fontSize: context.isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Welcome back, ${widget.userRole}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.busId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRoleMessage(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleMessage() {
    switch (widget.userRole) {
      case 'Admin':
        return 'All systems operational. 38 buses active, 1,240 students boarded today.';
      case 'Driver':
        return 'You are assigned to ${widget.busId}. Next stop: Oak St & Maple Ave.';
      case 'Conductor':
        return '12 students pending check-in. 28 students already boarded.';
      default:
        return 'Your child is on the way. Current ETA: 8:14 AM at Oak St & Maple Ave.';
    }
  }

  // ============================================================
  // KPI GRID
  // ============================================================

  Widget _buildKpiGrid() {
    final isMobile = context.isMobile;
    final role = widget.userRole;

    List<Map<String, dynamic>> kpis = [];

    if (role == 'Admin') {
      kpis = [
        {
          'title': 'Active Buses',
          'value': '38',
          'icon': Icons.directions_bus_rounded,
          'badgeText': 'On Time',
          'badgeBgColor': AppColors.successGreen.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.successGreen,
          'gradient': AppTheme.brandGradient,
          'iconBgColor': AppColors.primaryContainer,
          'iconColor': Colors.white,
          'showTrend': true,
          'trendValue': 4.2,
          'isTrendUp': true,
        },
        {
          'title': 'Students Boarded',
          'value': '1,240',
          'icon': Icons.group_rounded,
          'badgeText': '+12 Today',
          'badgeBgColor': AppColors.successGreen.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.successGreen,
          'gradient': AppTheme.successGradient,
          'iconBgColor': AppColors.mintSoft,
          'iconColor': Colors.white,
          'showTrend': true,
          'trendValue': 8.5,
          'isTrendUp': true,
        },
        {
          'title': 'Route Completion',
          'value': '76%',
          'icon': Icons.route_rounded,
          'badgeText': 'Morning Run',
          'badgeBgColor': AppColors.purpleSoft,
          'badgeTextColor': AppColors.safetyBlue,
          'gradient': AppTheme.purpleGradient,
          'iconBgColor': AppColors.purpleSoft,
          'iconColor': Colors.white,
          'progress': 0.76,
        },
        {
          'title': 'In Maintenance',
          'value': '4',
          'icon': Icons.build_rounded,
          'badgeText': '2 Critical',
          'badgeBgColor': AppColors.alertOrange.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.alertOrange,
          'gradient': AppTheme.dangerGradient,
          'iconBgColor': AppColors.errorContainer,
          'iconColor': Colors.white,
          'showTrend': true,
          'trendValue': 12.5,
          'isTrendUp': false,
        },
      ];
    } else if (role == 'Driver') {
      kpis = [
        {
          'title': 'Current Speed',
          'value': '35 mph',
          'icon': Icons.speed_rounded,
          'badgeText': 'On Route',
          'badgeBgColor': AppColors.successGreen.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.successGreen,
          'gradient': AppTheme.brandGradient,
          'iconBgColor': AppColors.primaryContainer,
          'iconColor': Colors.white,
        },
        {
          'title': 'Next Stop ETA',
          'value': '4 min',
          'icon': Icons.timer_rounded,
          'badgeText': 'Oak St & Maple',
          'badgeBgColor': AppColors.amberSoft,
          'badgeTextColor': AppColors.alertOrangeDark,
          'gradient': AppTheme.warningGradient,
          'iconBgColor': AppColors.amberSoft,
          'iconColor': Colors.white,
        },
        {
          'title': 'Students Onboard',
          'value': '28',
          'icon': Icons.people_rounded,
          'badgeText': 'Capacity: 48',
          'badgeBgColor': AppColors.successGreen.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.successGreen,
          'gradient': AppTheme.successGradient,
          'iconBgColor': AppColors.mintSoft,
          'iconColor': Colors.white,
          'progress': 0.58,
        },
        {
          'title': 'Fuel Level',
          'value': '62%',
          'icon': Icons.local_gas_station_rounded,
          'badgeText': 'Good',
          'badgeBgColor': AppColors.successGreen.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.successGreen,
          'gradient': AppTheme.successGradient,
          'iconBgColor': AppColors.mintSoft,
          'iconColor': Colors.white,
          'progress': 0.62,
        },
      ];
    } else if (role == 'Conductor') {
      kpis = [
        {
          'title': 'Students Boarded',
          'value': '28',
          'icon': Icons.check_circle_rounded,
          'badgeText': 'On Time',
          'badgeBgColor': AppColors.successGreen.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.successGreen,
          'gradient': AppTheme.successGradient,
          'iconBgColor': AppColors.mintSoft,
          'iconColor': Colors.white,
        },
        {
          'title': 'Pending Check-in',
          'value': '12',
          'icon': Icons.hourglass_top_rounded,
          'badgeText': 'Waiting',
          'badgeBgColor': AppColors.amberSoft,
          'badgeTextColor': AppColors.alertOrangeDark,
          'gradient': AppTheme.warningGradient,
          'iconBgColor': AppColors.amberSoft,
          'iconColor': Colors.white,
        },
        {
          'title': 'Total Students',
          'value': '40',
          'icon': Icons.people_rounded,
          'badgeText': 'Full Roster',
          'badgeBgColor': AppColors.safetyBlue.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.safetyBlue,
          'gradient': AppTheme.brandGradient,
          'iconBgColor': AppColors.primaryContainer,
          'iconColor': Colors.white,
        },
        {
          'title': 'Attendance Rate',
          'value': '96%',
          'icon': Icons.assessment_rounded,
          'badgeText': 'Excellent',
          'badgeBgColor': AppColors.successGreen.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.successGreen,
          'gradient': AppTheme.successGradient,
          'iconBgColor': AppColors.mintSoft,
          'iconColor': Colors.white,
          'progress': 0.96,
        },
      ];
    } else {
      // Parent
      kpis = [
        {
          'title': 'Bus Status',
          'value': 'On Route',
          'icon': Icons.directions_bus_rounded,
          'badgeText': '4 min away',
          'badgeBgColor': AppColors.successGreen.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.successGreen,
          'gradient': AppTheme.brandGradient,
          'iconBgColor': AppColors.primaryContainer,
          'iconColor': Colors.white,
        },
        {
          'title': 'Child Status',
          'value': 'Boarded',
          'icon': Icons.face_rounded,
          'badgeText': 'Safe',
          'badgeBgColor': AppColors.successGreen.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.successGreen,
          'gradient': AppTheme.successGradient,
          'iconBgColor': AppColors.mintSoft,
          'iconColor': Colors.white,
        },
        {
          'title': 'Pickup Time',
          'value': '8:14 AM',
          'icon': Icons.schedule_rounded,
          'badgeText': 'On Schedule',
          'badgeBgColor': AppColors.successGreen.withValues(alpha: 0.12),
          'badgeTextColor': AppColors.successGreen,
          'gradient': AppTheme.brandGradient,
          'iconBgColor': AppColors.primaryContainer,
          'iconColor': Colors.white,
        },
        {
          'title': 'Stop Name',
          'value': 'Oak St & Maple',
          'icon': Icons.location_on_rounded,
          'badgeText': 'Pickup',
          'badgeBgColor': AppColors.amberSoft,
          'badgeTextColor': AppColors.alertOrangeDark,
          'gradient': AppTheme.warningGradient,
          'iconBgColor': AppColors.amberSoft,
          'iconColor': Colors.white,
        },
      ];
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.1 : 1.4,
      children: kpis.map((kpi) {
        return KpiCard(
          title: kpi['title'],
          value: kpi['value'],
          icon: kpi['icon'],
          iconBgColor: kpi['iconBgColor'],
          iconColor: kpi['iconColor'],
          badgeText: kpi['badgeText'],
          badgeBgColor: kpi['badgeBgColor'],
          badgeTextColor: kpi['badgeTextColor'],
          progress: kpi['progress'],
          gradient: kpi['gradient'],
          showTrend: kpi['showTrend'] ?? false,
          trendValue: kpi['trendValue'],
          isTrendUp: kpi['isTrendUp'] ?? true,
        );
      }).toList(),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    final isMobile = context.isMobile;
    final role = widget.userRole;

    List<Map<String, dynamic>> actions = [];

    if (role == 'Admin') {
      actions = [
        {'icon': Icons.person_add_rounded, 'label': 'Add User', 'color': AppColors.safetyBlue},
        {'icon': Icons.directions_bus_rounded, 'label': 'Dispatch Bus', 'color': AppColors.alertOrange},
        {'icon': Icons.assessment_rounded, 'label': 'Reports', 'color': AppColors.successGreen},
        {'icon': Icons.settings_rounded, 'label': 'Settings', 'color': AppColors.purpleSoft},
      ];
    } else if (role == 'Driver') {
      actions = [
        {'icon': Icons.map_rounded, 'label': 'View Route', 'color': AppColors.safetyBlue},
        {'icon': Icons.chat_rounded, 'label': 'Message Dispatch', 'color': AppColors.alertOrange},
        {'icon': Icons.warning_amber_rounded, 'label': 'Report Issue', 'color': AppColors.errorRed},
      ];
    } else if (role == 'Conductor') {
      actions = [
        {'icon': Icons.qr_code_scanner_rounded, 'label': 'Scan Badge', 'color': AppColors.safetyBlue},
        {'icon': Icons.list_alt_rounded, 'label': 'View Roster', 'color': AppColors.alertOrange},
        {'icon': Icons.chat_rounded, 'label': 'Message Driver', 'color': AppColors.successGreen},
      ];
    } else {
      actions = [
        {'icon': Icons.map_rounded, 'label': 'Live Map', 'color': AppColors.safetyBlue},
        {'icon': Icons.face_rounded, 'label': 'Child Status', 'color': AppColors.successGreen},
        {'icon': Icons.chat_rounded, 'label': 'Contact Driver', 'color': AppColors.alertOrange},
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return Padding(
                padding: EdgeInsets.only(right: index < actions.length - 1 ? 12 : 0),
                child: _QuickActionCard(
                  icon: action['icon'],
                  label: action['label'],
                  color: action['color'],
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${action['label']} tapped'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================

  Widget _buildRecentActivity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.directions_bus_rounded,
                color: AppColors.successGreen,
                title: 'BUS-402 arrived at Oak St & Maple',
                time: '2 min ago',
                isDark: isDark,
              ),
              const Divider(),
              _buildActivityItem(
                icon: Icons.face_rounded,
                color: AppColors.safetyBlue,
                title: 'Sarah Johnson boarded the bus',
                time: '5 min ago',
                isDark: isDark,
              ),
              const Divider(),
              _buildActivityItem(
                icon: Icons.warning_amber_rounded,
                color: AppColors.alertOrange,
                title: 'BUS-115 delayed by 6 minutes',
                time: '12 min ago',
                isDark: isDark,
              ),
              const Divider(),
              _buildActivityItem(
                icon: Icons.check_circle_rounded,
                color: AppColors.successGreen,
                title: 'All students checked in on BUS-208',
                time: '18 min ago',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String time,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTION CARD
// ============================================================

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}