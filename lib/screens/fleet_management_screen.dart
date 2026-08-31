import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/bus_fleet.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../widgets/kpi_card.dart';
import 'admin/create_user_screen.dart';
import 'admin/people_directory_screen.dart';
import 'admin/manage_students_screen.dart';

class FleetManagementScreen extends StatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  State<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends State<FleetManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<BusFleet> _fleetList = [
    BusFleet(
      busId: 'BUS-402',
      driverName: 'Sarah Jenkins',
      routeName: 'Route 7A - Oakridge Elementary',
      estArrival: '08:15 AM',
      status: FleetStatus.delayed,
      speedMph: 15,
      fuelPercent: 62,
    ),
    BusFleet(
      busId: 'BUS-115',
      driverName: 'Mike Torres',
      routeName: 'Route 3C - Westside High',
      estArrival: '07:50 AM',
      status: FleetStatus.onRoute,
      speedMph: 35,
      fuelPercent: 15,
    ),
    BusFleet(
      busId: 'BUS-208',
      driverName: 'David Miller',
      routeName: 'Route 12B - Pinecrest Academy',
      estArrival: '08:30 AM',
      status: FleetStatus.onRoute,
      speedMph: 28,
      fuelPercent: 88,
    ),
    BusFleet(
      busId: 'BUS-501',
      driverName: 'Robert Vance',
      routeName: 'Route 5F - Lincoln Middle',
      estArrival: 'In Shop',
      status: FleetStatus.maintenance,
      speedMph: 0,
      fuelPercent: 45,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFleet = _fleetList.where((bus) {
      final query = _searchQuery.toLowerCase().trim();

      if (query.isEmpty) return true;

      return bus.busId.toLowerCase().contains(query) ||
          bus.driverName.toLowerCase().contains(query) ||
          bus.routeName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildKpiSection(),
                  const SizedBox(height: 24),
                  _buildTelemetrySection(filteredFleet),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fleet Overview',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live monitoring of 42 active vehicles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        );

        final addUserButton = OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminCreateUserScreen()),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.safetyBlue,
            side: const BorderSide(color: AppColors.safetyBlue, width: 1.3),
            backgroundColor: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(
            Icons.person_add_rounded,
            size: 18,
            color: AppColors.safetyBlue,
          ),
          label: const Text(
            'Add User',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.safetyBlue,
            ),
          ),
        );

        final peopleButton = OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PeopleDirectoryScreen()),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.safetyBlue,
            side: const BorderSide(color: AppColors.safetyBlue, width: 1.3),
            backgroundColor: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(
            Icons.groups_rounded,
            size: 18,
            color: AppColors.safetyBlue,
          ),
          label: const Text(
            'People',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.safetyBlue,
            ),
          ),
        );

        final manageStudentsButton = OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageStudentsScreen()),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.safetyBlue,
            side: const BorderSide(color: AppColors.safetyBlue, width: 1.3),
            backgroundColor: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(
            Icons.child_care_rounded,
            size: 18,
            color: AppColors.safetyBlue,
          ),
          label: const Text(
            'Students',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.safetyBlue,
            ),
          ),
        );

        final dispatchButton = ElevatedButton.icon(
          onPressed: () => _openDispatchModal(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.safetyBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text(
            'Dispatch Bus',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );

        if (isSmallScreen) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  addUserButton,
                  peopleButton,
                  manageStudentsButton,
                  dispatchButton,
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 12),
            addUserButton,
            const SizedBox(width: 8),
            peopleButton,
            const SizedBox(width: 8),
            manageStudentsButton,
            const SizedBox(width: 8),
            dispatchButton,
          ],
        );
      },
    );
  }

  Widget _buildKpiSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 360) {
          return Column(
            children: [
              KpiCard(
                title: 'Active Buses',
                value: '38',
                icon: Icons.directions_bus,
                iconBgColor: AppColors.primaryContainer,
                iconColor: Colors.white,
                badgeText: 'On Time',
                badgeBgColor: Color(0x1F2D8A29),
                badgeTextColor: AppColors.successGreen,
              ),
              SizedBox(height: 12),
              KpiCard(
                title: 'In Maintenance',
                value: '4',
                icon: Icons.build,
                iconBgColor: AppColors.errorContainer,
                iconColor: AppColors.errorRed,
                badgeText: '2 Critical',
                badgeBgColor: Color(0x1FFF7A00),
                badgeTextColor: AppColors.alertOrange,
              ),
              SizedBox(height: 12),
              KpiCard(
                title: 'Route Completion',
                value: '76%',
                icon: Icons.route,
                iconBgColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                iconColor: AppColors.safetyBlue,
                badgeText: 'Morning Run',
                badgeBgColor: Theme.of(context).colorScheme.surfaceContainerLow,
                badgeTextColor: AppColors.safetyBlue,
                progress: 0.76,
              ),
              SizedBox(height: 12),
              KpiCard(
                title: 'Students Boarded',
                value: '1,240',
                icon: Icons.group,
                iconBgColor: Theme.of(context).colorScheme.surfaceContainerLow,
                iconColor: Theme.of(context).colorScheme.onSurface,
                badgeText: '+12 today',
                badgeBgColor: Color(0x1F2D8A29),
                badgeTextColor: AppColors.successGreen,
              ),
            ],
          );
        }

        final crossAxisCount = width >= 900 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: width >= 900 ? 1.45 : 1.6,
          children: [
            KpiCard(
              title: 'Active Buses',
              value: '38',
              icon: Icons.directions_bus,
              iconBgColor: AppColors.primaryContainer,
              iconColor: Colors.white,
              badgeText: 'On Time',
              badgeBgColor: Color(0x1F2D8A29),
              badgeTextColor: AppColors.successGreen,
            ),
            KpiCard(
              title: 'In Maintenance',
              value: '4',
              icon: Icons.build,
              iconBgColor: AppColors.errorContainer,
              iconColor: AppColors.errorRed,
              badgeText: '2 Critical',
              badgeBgColor: Color(0x1FFF7A00),
              badgeTextColor: AppColors.alertOrange,
            ),
            KpiCard(
              title: 'Route Completion',
              value: '76%',
              icon: Icons.route,
              iconBgColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              iconColor: AppColors.safetyBlue,
              badgeText: 'Morning Run',
              badgeBgColor: Theme.of(context).colorScheme.surfaceContainerLow,
              badgeTextColor: AppColors.safetyBlue,
              progress: 0.76,
            ),
            KpiCard(
              title: 'Students Boarded',
              value: '1,240',
              icon: Icons.group,
              iconBgColor: Theme.of(context).colorScheme.surfaceContainerLow,
              iconColor: Theme.of(context).colorScheme.onSurface,
              badgeText: '+12 today',
              badgeBgColor: Color(0x1F2D8A29),
              badgeTextColor: AppColors.successGreen,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTelemetrySection(List<BusFleet> filteredFleet) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.safetyBlue.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTelemetryHeader(),
          Divider(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            height: 1,
          ),
          if (filteredFleet.isEmpty)
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No buses found',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredFleet.length,
              separatorBuilder: (_, _) => Divider(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                height: 1,
              ),
              itemBuilder: (context, index) {
                return _buildFleetCard(filteredFleet[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTelemetryHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 500;

          final title = Text(
            'Live Telemetry & Status',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          );

          final searchField = TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search bus or driver...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(
                Icons.search,
                size: 19,
                color: AppColors.outline,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 12), searchField],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              SizedBox(width: 280, child: searchField),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFleetCard(BusFleet bus) {
    Color badgeColor;
    Color badgeBg;
    String statusText;

    switch (bus.status) {
      case FleetStatus.onRoute:
        badgeColor = AppColors.successGreen;
        badgeBg = const Color(0x1F2D8A29);
        statusText = 'On Route';
        break;

      case FleetStatus.delayed:
        badgeColor = AppColors.alertOrange;
        badgeBg = const Color(0x1FFF7A00);
        statusText = 'Delayed (Traffic)';
        break;

      case FleetStatus.maintenance:
        badgeColor = AppColors.errorRed;
        badgeBg = AppColors.errorContainer;
        statusText = 'In Maintenance';
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          if (isSmall) {
            return _buildMobileFleetCard(bus, badgeColor, badgeBg, statusText);
          }

          return _buildDesktopFleetCard(bus, badgeColor, badgeBg, statusText);
        },
      ),
    );
  }

  Widget _buildMobileFleetCard(
    BusFleet bus,
    Color badgeColor,
    Color badgeBg,
    String statusText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
              child: Icon(Icons.directions_bus, color: badgeColor, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus.busId,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bus.driverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: AppColors.safetyBlue,
              ),
              onPressed: () {
                _openDriverChat(bus);
              },
            ),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          bus.routeName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 15,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Est. Arrival: ${bus.estArrival}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
            _buildTelemetryValue('${bus.speedMph} mph', 'Speed'),
            _buildTelemetryValue(
              'Fuel: ${bus.fuelPercent}%',
              'Fuel',
              valueColor: bus.fuelPercent < 20
                  ? AppColors.errorRed
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopFleetCard(
    BusFleet bus,
    Color badgeColor,
    Color badgeBg,
    String statusText,
  ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
          child: Icon(Icons.directions_bus, color: badgeColor, size: 22),
        ),
        const SizedBox(width: 14),

        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bus.busId,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                bus.driverName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bus.routeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Est. Arrival: ${bus.estArrival}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${bus.speedMph} mph',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Fuel: ${bus.fuelPercent}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: bus.fuelPercent < 20
                    ? AppColors.errorRed
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        const SizedBox(width: 8),

        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: AppColors.safetyBlue,
          ),
          onPressed: () {
            _openDriverChat(bus);
          },
        ),
      ],
    );
  }

  Widget _buildTelemetryValue(String value, String label, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _openDispatchModal(BuildContext context) {
    String selectedRoute = 'Route 7A - Oakridge Elementary';
    String selectedBus = 'BUS-901 (Standby Reserve)';
    String selectedDriver = 'Mar Vance (Standby)';

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
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  children: [
                    const Icon(
                      Icons.add_road_rounded,
                      color: AppColors.safetyBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Dispatch Replacement Vehicle',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Target Route:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedRoute,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items:
                      [
                            'Route 7A - Oakridge Elementary',
                            'Route 3C - Westside High',
                            'Route 12B - Pinecrest Academy',
                            'Route 5F - Lincoln Middle',
                          ]
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRoute = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Assign Reserve Bus & Driver:',
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
                  ),
                  items:
                      ['BUS-901 (Standby Reserve)', 'BUS-804 (Standby Reserve)']
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(
                                b,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedBus = val);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final newBus = BusFleet(
                        busId: selectedBus.split(' ').first,
                        driverName: selectedDriver.split(' ').first,
                        routeName: selectedRoute,
                        estArrival: '08:05 AM',
                        status: FleetStatus.onRoute,
                        speedMph: 24,
                        fuelPercent: 95,
                      );

                      setState(() {
                        _fleetList.insert(0, newBus);
                      });

                      NotificationService.instance.add(
                        kind: NotificationKind.info,
                        title: 'Replacement Bus Dispatched',
                        message: '${newBus.busId} assigned to $selectedRoute.',
                      );

                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✓ Dispatched ${newBus.busId} to $selectedRoute',
                          ),
                          backgroundColor: AppColors.successGreen,
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
                      'Confirm & Dispatch Immediately',
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_rounded,
                  color: AppColors.safetyBlue,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispatch Dispatcher ↔ ${bus.driverName}',
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
            const Text(
              'Quick Dispatch Canned Messages:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:
                  [
                    'Hold at next stop',
                    'Traffic detour ahead',
                    'Confirm student manifest',
                    'Return to depot',
                  ].map((msg) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ActionChip(
                        label: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            msg,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          NotificationService.instance.add(
                            kind: NotificationKind.info,
                            title: 'Dispatch Msg sent to ${bus.driverName}',
                            message: '"$msg" (${bus.busId})',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sent: "$msg" to ${bus.driverName}',
                              ),
                              backgroundColor: AppColors.safetyBlue,
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 14),
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
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final txt = textController.text.trim();
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
                      ),
                    );
                  },
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
}
