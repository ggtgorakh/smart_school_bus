import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/bus_fleet.dart';
import '../widgets/kpi_card.dart';

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
    final filteredFleet = _fleetList.where((b) {
      final query = _searchQuery.toLowerCase();
      return b.busId.toLowerCase().contains(query) ||
          b.driverName.toLowerCase().contains(query) ||
          b.routeName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fleet Overview',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                    ),
                    Text(
                      'Live monitoring of 42 active vehicles',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dispatching replacement bus...'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safetyBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                ),
              ],
            ),
            const SizedBox(height: 20),

            // KPI Grid
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 500
                        ? 2
                        : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: const [
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
                      iconBgColor: AppColors.surfaceContainerHigh,
                      iconColor: AppColors.safetyBlue,
                      badgeText: 'Morning Run',
                      badgeBgColor: AppColors.surfaceContainerLow,
                      badgeTextColor: AppColors.safetyBlue,
                      progress: 0.76,
                    ),
                    KpiCard(
                      title: 'Students Boarded',
                      value: '1,240',
                      icon: Icons.group,
                      iconBgColor: AppColors.surfaceContainerLow,
                      iconColor: AppColors.textMain,
                      badgeText: '+12 today',
                      badgeBgColor: Color(0x1F2D8A29),
                      badgeTextColor: AppColors.successGreen,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Detailed Fleet Telemetry Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerHighest),
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
                  // Search and Header section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Live Telemetry & Status',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search Bus ID or Driver...',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 18,
                                color: AppColors.outline,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: AppColors.surfaceContainerLow,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.surfaceContainerHighest, height: 1),

                  // Fleet List Items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredFleet.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.surfaceContainerHighest, height: 1),
                    itemBuilder: (context, index) {
                      final bus = filteredFleet[index];
                      return _buildFleetRow(bus);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetRow(BusFleet bus) {
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
      child: Row(
        children: [
          // Icon Circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bus,
              color: badgeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Bus ID & Driver
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bus.busId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  bus.driverName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Route info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bus.routeName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Est. Arrival: ${bus.estArrival}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
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
          const SizedBox(width: 16),
          // Speed & Fuel telemetry
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${bus.speedMph} mph',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textMain,
                ),
              ),
              Text(
                'Fuel: ${bus.fuelPercent}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: bus.fuelPercent < 20
                      ? AppColors.errorRed
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Message driver icon action
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline,
                size: 20, color: AppColors.safetyBlue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening chat with ${bus.driverName}...'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
