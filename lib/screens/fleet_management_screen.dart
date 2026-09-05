// lib/screens/fleet_management_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/bus_fleet.dart';
import '../models/app_notification.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../widgets/kpi_card.dart';
import 'admin/create_user_screen.dart';
import 'admin/manage_students_screen.dart';
import 'admin/import_roster_screen.dart';
import 'admin/admin_operations_screen.dart';
import 'admin_fleet_tracking_screen.dart';

class FleetManagementScreen extends StatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  State<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends State<FleetManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';
  bool _isGridView = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Live fleet data, streamed from Firebase (/busesFleet/{busId}) — no more
  // hardcoded demo buses. Starts empty while the first snapshot loads.
  List<BusFleet> _fleetList = [];
  bool _fleetLoading = true;
  StreamSubscription<List<BusFleet>>? _fleetSubscription;

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();

    // Make sure bus_01..bus_10 exist in Firebase (idle, no-op if already
    // present), then subscribe to live fleet updates.
    FirebaseService.instance.ensureTenBusesExist();
    _fleetSubscription = FirebaseService.instance.streamFleet().listen((buses) {
      if (!mounted) return;
      setState(() {
        _fleetList = buses;
        _fleetLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _fleetSubscription?.cancel();
    super.dispose();
  }

  List<BusFleet> get _filteredFleet {
    var filtered = _fleetList;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered = filtered
          .where(
            (bus) =>
                bus.busId.toLowerCase().contains(query) ||
                bus.driverName.toLowerCase().contains(query) ||
                bus.routeName.toLowerCase().contains(query),
          )
          .toList();
    }

    // Apply status filter
    if (_filterStatus != 'all') {
      filtered = filtered.where((bus) {
        final statusMap = {
          'onRoute': FleetStatus.onRoute,
          'delayed': FleetStatus.delayed,
          'maintenance': FleetStatus.maintenance,
        };
        return bus.status == statusMap[_filterStatus];
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final filteredFleet = _filteredFleet;

    if (_fleetLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.safetyBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: _buildHeader(context),
                  ),
                ),

                // KPI Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 20,
                    ),
                    child: _buildKpiSection(context),
                  ),
                ),

                // Fleet List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 20,
                      20,
                      isMobile ? 16 : 20,
                      12,
                    ),
                    child: _buildListHeader(context),
                  ),
                ),

                // Fleet List
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
                  sliver: _buildFleetList(filteredFleet),
                ),

                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 80 : 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final isMobile = context.isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fleet Overview',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_fleetList.length} vehicles • ${_fleetList.where((b) => b.status == FleetStatus.onRoute).length} active',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionButton(
              context,
              icon: Icons.person_add_rounded,
              label: 'Add User',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminCreateUserScreen(),
                ),
              ),
            ),
            _buildActionButton(
              context,
              icon: Icons.groups_rounded,
              label: 'People & Assignments',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminOperationsScreen(),
                ),
              ),
            ),
            _buildActionButton(
              context,
              icon: Icons.child_care_rounded,
              label: 'Students',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageStudentsScreen()),
              ),
            ),
            _buildActionButton(
              context,
              icon: Icons.upload_file_rounded,
              label: 'Import Roster',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportRosterScreen()),
              ),
            ),
            _buildActionButton(
              context,
              icon: Icons.add_rounded,
              label: 'Dispatch',
              onTap: () => _openDispatchModal(context),
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safetyBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.safetyBlue,
        side: const BorderSide(color: AppColors.safetyBlue, width: 1.3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ============================================================
  // KPI SECTION
  // ============================================================

  Widget _buildKpiSection(BuildContext context) {
    final isMobile = context.isMobile;
    final activeBuses = _fleetList
        .where((b) => b.status == FleetStatus.onRoute)
        .length;
    final delayedBuses = _fleetList
        .where((b) => b.status == FleetStatus.delayed)
        .length;
    final maintenanceBuses = _fleetList
        .where((b) => b.status == FleetStatus.maintenance)
        .length;
    final averageFuel = _fleetList.isEmpty
        ? 0
        : (_fleetList
                      .map((bus) => bus.fuelPercent)
                      .reduce((a, b) => a + b) /
                  _fleetList.length)
              .round();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.1 : 1.4,
      children: [
        KpiCard(
          title: 'Active Buses',
          value: '$activeBuses',
          icon: Icons.directions_bus_rounded,
          iconBgColor: AppColors.primaryContainer,
          iconColor: Colors.white,
          badgeText: 'On Time',
          badgeBgColor: AppColors.successGreen.withValues(alpha: 0.12),
          badgeTextColor: AppColors.successGreen,
          gradient: AppTheme.brandGradient,
          onTap: () => setState(() => _filterStatus = 'onRoute'),
        ),
        KpiCard(
          title: 'Delayed',
          value: '$delayedBuses',
          icon: Icons.warning_amber_rounded,
          iconBgColor: AppColors.amberSoft,
          iconColor: Colors.white,
          badgeText: 'Need Attention',
          badgeBgColor: AppColors.alertOrange.withValues(alpha: 0.12),
          badgeTextColor: AppColors.alertOrange,
          gradient: AppTheme.warningGradient,
          onTap: () => setState(() => _filterStatus = 'delayed'),
        ),
        KpiCard(
          title: 'In Maintenance',
          value: '$maintenanceBuses',
          icon: Icons.build_rounded,
          iconBgColor: AppColors.errorContainer,
          iconColor: Colors.white,
          badgeText: '${maintenanceBuses > 0 ? '2 Critical' : 'All Good'}',
          badgeBgColor: maintenanceBuses > 0
              ? AppColors.alertOrange.withValues(alpha: 0.12)
              : AppColors.successGreen.withValues(alpha: 0.12),
          badgeTextColor: maintenanceBuses > 0
              ? AppColors.alertOrange
              : AppColors.successGreen,
          gradient: maintenanceBuses > 0
              ? AppTheme.dangerGradient
              : AppTheme.successGradient,
          onTap: () => setState(() => _filterStatus = 'maintenance'),
        ),
        KpiCard(
          title: 'Fuel Efficiency',
          value: '$averageFuel%',
          icon: Icons.local_gas_station_rounded,
          iconBgColor: AppColors.mintSoft,
          iconColor: Colors.white,
          badgeText: _fleetList.isEmpty ? 'No data' : 'Live average',
          badgeBgColor: AppColors.successGreen.withValues(alpha: 0.12),
          badgeTextColor: AppColors.successGreen,
          gradient: AppTheme.successGradient,
          progress: averageFuel / 100,
        ),
      ],
    );
  }

  // ============================================================
  // LIST HEADER
  // ============================================================

  Widget _buildListHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Telemetry',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '${_filteredFleet.length} vehicles match your filters',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            // View toggle
            IconButton(
              onPressed: () => setState(() => _isGridView = !_isGridView),
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: AppColors.safetyBlue,
              ),
              tooltip: _isGridView ? 'List View' : 'Grid View',
            ),
            // Filter button
            PopupMenuButton<String>(
              icon: Icon(
                Icons.filter_list_rounded,
                color: _filterStatus != 'all' ? AppColors.safetyBlue : null,
              ),
              onSelected: (value) => setState(() => _filterStatus = value),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('All Vehicles')),
                const PopupMenuItem(value: 'onRoute', child: Text('On Route')),
                const PopupMenuItem(value: 'delayed', child: Text('Delayed')),
                const PopupMenuItem(
                  value: 'maintenance',
                  child: Text('Maintenance'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // FLEET LIST
  // ============================================================

  Widget _buildFleetList(List<BusFleet> filteredFleet) {
    if (filteredFleet.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'No vehicles found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _filterStatus = 'all';
                  });
                },
                child: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.only(bottom: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildGridCard(filteredFleet[index]),
            childCount: filteredFleet.length,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final bus = filteredFleet[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < filteredFleet.length - 1 ? 8 : 0,
          ),
          child: _buildFleetCard(bus),
        );
      }, childCount: filteredFleet.length),
    );
  }

  // ============================================================
  // FLEET CARD (List View)
  // ============================================================

  Widget _buildFleetCard(BusFleet bus) {
    final statusInfo = _getStatusInfo(bus.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openBusDetailSheet(bus, statusInfo),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.3),
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
              // Bus Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: statusInfo.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Bus Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bus.busId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusInfo.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: statusInfo.color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusInfo.icon,
                                  size: 12,
                                  color: statusInfo.color,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    statusInfo.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusInfo.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bus.driverName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      bus.routeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Telemetry
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${bus.speedMph} mph',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: bus.fuelPercent < 20
                          ? AppColors.errorRed.withValues(alpha: 0.12)
                          : AppColors.successGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_gas_station_rounded,
                          size: 10,
                          color: bus.fuelPercent < 20
                              ? AppColors.errorRed
                              : AppColors.successGreen,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${bus.fuelPercent}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: bus.fuelPercent < 20
                                ? AppColors.errorRed
                                : AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // Actions
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: AppColors.safetyBlue,
                ),
                onPressed: () => _openDriverChat(bus),
                tooltip: 'Message Driver',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GRID CARD
  // ============================================================

  Widget _buildGridCard(BusFleet bus) {
    final statusInfo = _getStatusInfo(bus.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openBusDetailSheet(bus, statusInfo),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusInfo.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: statusInfo.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bus.busId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: AppColors.safetyBlue,
                    ),
                    onPressed: () => _openDriverChat(bus),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Message Driver',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Driver & Route
              Text(
                bus.driverName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                bus.routeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const Spacer(),

              // Status & Telemetry
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusInfo.color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusInfo.icon,
                          size: 10,
                          color: statusInfo.color,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          statusInfo.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusInfo.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${bus.speedMph} mph',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.local_gas_station_rounded,
                        size: 12,
                        color: bus.fuelPercent < 20
                            ? AppColors.errorRed
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${bus.fuelPercent}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: bus.fuelPercent < 20
                              ? AppColors.errorRed
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS INFO HELPER
  // ============================================================

  ({Color color, IconData icon, String label}) _getStatusInfo(
    FleetStatus status,
  ) {
    switch (status) {
      case FleetStatus.onRoute:
        return (
          color: AppColors.successGreen,
          icon: Icons.play_arrow_rounded,
          label: 'On Route',
        );
      case FleetStatus.delayed:
        return (
          color: AppColors.alertOrange,
          icon: Icons.warning_amber_rounded,
          label: 'Delayed',
        );
      case FleetStatus.maintenance:
        return (
          color: AppColors.errorRed,
          icon: Icons.build_rounded,
          label: 'Maintenance',
        );
      case FleetStatus.idle:
        return (
          color: AppColors.outline,
          icon: Icons.pause_circle_outline_rounded,
          label: 'Idle',
        );
    }
  }

  // ============================================================
  // BUS DETAIL SHEET
  // ============================================================

  void _openBusDetailSheet(
    BusFleet bus,
    ({Color color, IconData icon, String label}) statusInfo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bus Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: statusInfo.color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.busId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bus.routeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusInfo.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(statusInfo.icon, size: 14, color: statusInfo.color),
                      const SizedBox(width: 4),
                      Text(
                        statusInfo.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detail Grid
            Row(
              children: [
                _buildDetailItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Driver',
                  value: bus.driverName,
                ),
                const SizedBox(width: 12),
                _buildDetailItem(
                  icon: Icons.schedule_rounded,
                  label: 'Est. Arrival',
                  value: bus.estArrival,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailItem(
                  icon: Icons.speed_rounded,
                  label: 'Speed',
                  value: '${bus.speedMph} mph',
                ),
                const SizedBox(width: 12),
                _buildDetailItem(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fuel',
                  value: '${bus.fuelPercent}%',
                  valueColor: bus.fuelPercent < 20 ? AppColors.errorRed : null,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _openDriverChat(bus);
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.safetyBlue,
                      side: const BorderSide(
                        color: AppColors.safetyBlue,
                        width: 1.3,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        bus.driverPhone == null ||
                            bus.driverPhone!.trim().isEmpty
                        ? null
                        : () => _callDriver(bus),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.successGreen,
                      side: const BorderSide(
                        color: AppColors.successGreen,
                        width: 1.3,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminFleetTrackingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text('View Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safetyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callDriver(BusFleet bus) async {
    final phone = bus.driverPhone?.trim();
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone app.')),
      );
    }
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          valueColor ?? Theme.of(context).colorScheme.onSurface,
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

  // ============================================================
  // DISPATCH MODAL
  // ============================================================

  void _openDispatchModal(BuildContext context) {
    // Only buses that are actually idle in Firebase can be dispatched as a
    // replacement — no more fake BUS-901/BUS-804 standby reserves.
    final idleBuses = _fleetList
        .where((b) => b.status == FleetStatus.idle)
        .toList();
    final activeRoutes = _fleetList
        .where(
          (b) => b.routeName.isNotEmpty && b.routeName != 'No route assigned',
        )
        .map((b) => b.routeName)
        .toSet()
        .toList();

    if (idleBuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No idle buses available to dispatch right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String selectedRoute = activeRoutes.isNotEmpty
        ? activeRoutes.first
        : 'Unassigned Route';
    String selectedBus = idleBuses.first.busId;
    final driverController = TextEditingController();
    final driverUidController = TextEditingController();
    final driverPhoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.safetyBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_road_rounded,
                        color: AppColors.safetyBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dispatch Replacement Vehicle',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Route Select
                const Text(
                  'Target Route:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: selectedRoute,
                  decoration: InputDecoration(
                    hintText: 'e.g. Route 7A - Oakridge Elementary',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLow,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (val) => selectedRoute = val,
                ),
                const SizedBox(height: 14),

                // Bus Select — only real idle buses from Firebase
                const Text(
                  'Assign Idle Bus:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedBus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLow,
                  ),
                  items: idleBuses
                      .map(
                        (b) => DropdownMenuItem(
                          value: b.busId,
                          child: Text(
                            b.busId.toUpperCase(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedBus = val);
                  },
                ),
                const SizedBox(height: 14),

                // Driver name
                const Text(
                  'Driver Name:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: driverController,
                  decoration: InputDecoration(
                    hintText: 'Driver assigned to this bus',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLow,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Driver UID (optional):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: driverUidController,
                  decoration: InputDecoration(
                    hintText: 'Firebase Auth UID for this driver',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLow,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Driver Phone (optional):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: driverPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+1 555 123 4567',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLow,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final busId = selectedBus;
                      final route = selectedRoute.trim().isEmpty
                          ? 'Unassigned Route'
                          : selectedRoute.trim();
                      final driver = driverController.text.trim().isEmpty
                          ? 'Unassigned'
                          : driverController.text.trim();

                      try {
                        await FirebaseService.instance.updateFleetStatus(
                          busId,
                          FleetStatus.onRoute,
                          driverName: driver,
                          routeName: route,
                          driverUid: driverUidController.text,
                          driverPhone: driverPhoneController.text,
                        );
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to dispatch bus. Please try again.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return;
                      }

                      // The fleet stream will reflect the change automatically;
                      // no local list mutation needed.
                      NotificationService.instance.add(
                        kind: NotificationKind.info,
                        title: 'Replacement Bus Dispatched',
                        message: '${busId.toUpperCase()} assigned to $route.',
                      );
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '✓ Dispatched ${busId.toUpperCase()} to $route',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safetyBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Confirm & Dispatch',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // DRIVER CHAT
  // ============================================================

  void _openDriverChat(BusFleet bus) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.safetyBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chat_rounded,
                    color: AppColors.safetyBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispatch ↔ ${bus.driverName}',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${bus.busId} • ${bus.routeName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Messages
            const Text(
              'Quick Dispatch Messages:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    'Hold at next stop',
                    'Traffic detour ahead',
                    'Confirm student manifest',
                    'Return to depot',
                  ].map((msg) {
                    return ActionChip(
                      label: Text(msg, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        NotificationService.instance.add(
                          kind: NotificationKind.info,
                          title: 'Dispatch Msg sent to ${bus.driverName}',
                          message: '"$msg" (${bus.busId})',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sent: "$msg" to ${bus.driverName}'),
                            backgroundColor: AppColors.safetyBlue,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                    );
                  }).toList(),
            ),
            const SizedBox(height: 14),

            // Custom Message
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Type dispatch message...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                    ),
                    onSubmitted: (_) =>
                        _sendCustomMessage(textController.text, bus, ctx),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _sendCustomMessage(textController.text, bus, ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safetyBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendCustomMessage(String text, BusFleet bus, BuildContext ctx) {
    final txt = text.trim();
    if (txt.isEmpty) return;
    Navigator.of(ctx).pop();
    NotificationService.instance.add(
      kind: NotificationKind.info,
      title: 'Dispatch Msg sent to ${bus.driverName}',
      message: '"$txt" (${bus.busId})',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent: "$txt" to ${bus.driverName}'),
        backgroundColor: AppColors.safetyBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
