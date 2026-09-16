// lib/screens/admin_fleet_tracking_screen.dart

import 'package:flutter/material.dart';
import '../../models/bus_location.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/live_map_canvas.dart';

class AdminFleetTrackingScreen extends StatefulWidget {
  const AdminFleetTrackingScreen({super.key});

  @override
  State<AdminFleetTrackingScreen> createState() =>
      _AdminFleetTrackingScreenState();
}

class _AdminFleetTrackingScreenState extends State<AdminFleetTrackingScreen> {
  String? _selectedBusId;
  List<Map<String, dynamic>> _selectedBusStops = const [];
  String? _loadedRouteForBusId;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<Map<String, BusLocation>>(
        // Only buses assigned to a driver appear here. Buses registered
        // in /busesFleet with driverUid == null are hidden.
        stream: FirebaseService.instance.streamActiveFleetLocations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load fleet telemetry: ${snapshot.error}',
              ),
            );
          }

          final locations = snapshot.data ?? const <String, BusLocation>{};
          final entries = locations.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          final selectedId =
              _selectedBusId != null && locations.containsKey(_selectedBusId)
                  ? _selectedBusId
                  : entries.isNotEmpty
                      ? entries.first.key
                      : null;
          final selected = selectedId == null ? null : locations[selectedId];

          if (selectedId != null && selectedId != _loadedRouteForBusId) {
            _loadedRouteForBusId = selectedId;
            _loadStopsForBus(selectedId);
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, entries.length),
                  const SizedBox(height: 12),
                  Expanded(
                    child: entries.isEmpty
                        ? _buildEmptyState(context)
                        : isMobile
                            ? Column(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: _buildMap(
                                      context,
                                      selected,
                                      _selectedBusStops,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMobileSummary(
                                    context,
                                    entries,
                                    selectedId,
                                    selected,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _buildMap(
                                      context,
                                      selected,
                                      _selectedBusStops,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 330,
                                    child: _buildFleetPanel(
                                      context,
                                      entries,
                                      selectedId,
                                      selected,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              size: 48,
              color: AppColors.alertOrangeDark,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No buses are assigned',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Assign a driver to a bus from Bus Operations to see live '
              'tracking here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadStopsForBus(String busId) async {
    try {
      final bus = await FirebaseService.instance.fetchFleetBusOnce(busId);
      final routeId = bus?.routeId;
      if (routeId == null || routeId.isEmpty) {
        if (mounted) setState(() => _selectedBusStops = const []);
        return;
      }
      final stops =
          await FirebaseService.instance.streamRouteStops(routeId).first;
      if (mounted && busId == _loadedRouteForBusId) {
        setState(() => _selectedBusStops = stops);
      }
    } catch (e) {
      debugPrint('AdminFleetTrackingScreen: failed to load stops: $e');
      if (mounted) setState(() => _selectedBusStops = const []);
    }
  }

  void _selectBus(String busId) {
    setState(() {
      _selectedBusId = busId;
      _selectedBusStops = const [];
      _loadedRouteForBusId = null;
    });
  }

  Widget _buildMap(
    BuildContext context,
    BusLocation? selected,
    List<Map<String, dynamic>> stops,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: LiveMapCanvas(
        lat: selected?.lat,
        lng: selected?.lng,
        busStatus: selected?.statusLabel ?? 'No bus selected',
        etaTime: selected?.etaLabel ?? '--',
        busNumber: _selectedBusId?.toUpperCase() ?? '--',
        speedKmph: selected?.speedKmph ?? 0,
        stops: stops,
        currentStopIndex: selected?.currentStopIndex ?? -1,
        showInfoOverlay: false,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Row(
      children: [
        const Icon(Icons.public_rounded, color: AppColors.safetyBlue, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fleet Live Map',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                count == 0
                    ? 'No buses assigned yet'
                    : '$count bus${count == 1 ? '' : 'es'} reporting live telemetry',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSummary(
    BuildContext context,
    List<MapEntry<String, BusLocation>> entries,
    String? selectedId,
    BusLocation? selected,
  ) {
    return SizedBox(
      height: 150,
      child: _buildFleetPanel(context, entries, selectedId, selected),
    );
  }

  Widget _buildFleetPanel(
    BuildContext context,
    List<MapEntry<String, BusLocation>> entries,
    String? selectedId,
    BusLocation? selected,
  ) {
    final headerLabel = selectedId?.toUpperCase() ?? '—';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_bus_rounded,
                    color: _statusColor(selected),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      headerLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    selected.statusLabel,
                    style: TextStyle(
                      color: _statusColor(selected),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('Waiting for bus telemetry...'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final location = entry.value;
                      final isSelected = entry.key == selectedId;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: AppColors.safetyBlue
                            .withValues(alpha: 0.08),
                        leading: Icon(
                          Icons.circle,
                          size: 12,
                          color: _statusColor(location),
                        ),
                        title: Text(
                          entry.key.toUpperCase(),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${location.statusLabel} • ${location.etaLabel}',
                        ),
                        trailing: Text(
                          '${location.speedKmph.toStringAsFixed(0)} km/h',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        onTap: () => _selectBus(entry.key),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BusLocation location) {
    if (location.isStale()) return AppColors.alertOrange;
    switch (location.status) {
      case BusRunStatus.onRoute:
        return AppColors.successGreen;
      case BusRunStatus.delayed:
        return AppColors.alertOrange;
      case BusRunStatus.arrived:
        return AppColors.safetyBlue;
      case BusRunStatus.idle:
        return AppColors.outline;
    }
  }
}