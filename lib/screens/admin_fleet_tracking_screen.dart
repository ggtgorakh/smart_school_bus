import 'package:flutter/material.dart';
import '../models/bus_location.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';

class AdminFleetTrackingScreen extends StatefulWidget {
  const AdminFleetTrackingScreen({super.key});

  @override
  State<AdminFleetTrackingScreen> createState() =>
      _AdminFleetTrackingScreenState();
}

class _AdminFleetTrackingScreenState extends State<AdminFleetTrackingScreen> {
  String? _selectedBusId;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<Map<String, BusLocation>>(
        stream: FirebaseService.instance.streamAllBusLocations(),
        builder: (context, snapshot) {
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

          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load fleet telemetry: ${snapshot.error}'),
            );
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
                    child: isMobile
                        ? Column(
                            children: [
                              Expanded(
                                flex: 6,
                                child: _FleetMap(
                                  locations: locations,
                                  selectedBusId: selectedId,
                                  onSelect: _selectBus,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildMobileSummary(context, entries, selected),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 7,
                                child: _FleetMap(
                                  locations: locations,
                                  selectedBusId: selectedId,
                                  onSelect: _selectBus,
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 330,
                                child: _buildFleetPanel(
                                  context,
                                  entries,
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

  void _selectBus(String busId) {
    setState(() => _selectedBusId = busId);
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
                    ? 'No live bus telemetry available'
                    : '$count buses reporting live telemetry',
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
    BusLocation? selected,
  ) {
    return SizedBox(
      height: 150,
      child: _buildFleetPanel(context, entries, selected),
    );
  }

  Widget _buildFleetPanel(
    BuildContext context,
    List<MapEntry<String, BusLocation>> entries,
    BusLocation? selected,
  ) {
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
                      selected.busNumber,
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
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('Waiting for bus telemetry...'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final location = entry.value;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.circle,
                          size: 12,
                          color: _statusColor(location),
                        ),
                        title: Text(entry.key.toUpperCase()),
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

class _FleetMap extends StatelessWidget {
  final Map<String, BusLocation> locations;
  final String? selectedBusId;
  final ValueChanged<String> onSelect;

  const _FleetMap({
    required this.locations,
    required this.selectedBusId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _FleetMapPainter(
          locations: locations,
          selectedBusId: selectedBusId,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final entries = locations.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));
            return Stack(
              children: [
                for (var index = 0; index < entries.length; index++)
                  Positioned(
                    left: _markerOffset(
                      constraints.biggest,
                      entries,
                      entries[index].value,
                    ).dx,
                    top: _markerOffset(
                      constraints.biggest,
                      entries,
                      entries[index].value,
                    ).dy,
                    child: GestureDetector(
                      onTap: () => onSelect(entries[index].key),
                      child: _BusMarker(
                        label: entries[index].key,
                        selected: entries[index].key == selectedBusId,
                        color: _markerColor(entries[index].value),
                      ),
                    ),
                  ),
                if (locations.isEmpty)
                  const Center(
                    child: Text('No buses are reporting location data.'),
                  ),
                Positioned(left: 16, top: 16, child: _MapLegend()),
              ],
            );
          },
        ),
      ),
    );
  }

  Offset _markerOffset(
    Size size,
    List<MapEntry<String, BusLocation>> entries,
    BusLocation location,
  ) {
    final valid = entries
        .map((entry) => entry.value)
        .where((value) => value.lat.abs() > 0.001 || value.lng.abs() > 0.001)
        .toList();
    if (valid.isEmpty) {
      return Offset(
        (size.width * 0.18).clamp(12.0, size.width - 90),
        (size.height * 0.42).clamp(70.0, size.height - 90),
      );
    }
    final minLat = valid
        .map((value) => value.lat)
        .reduce((a, b) => a < b ? a : b);
    final maxLat = valid
        .map((value) => value.lat)
        .reduce((a, b) => a > b ? a : b);
    final minLng = valid
        .map((value) => value.lng)
        .reduce((a, b) => a < b ? a : b);
    final maxLng = valid
        .map((value) => value.lng)
        .reduce((a, b) => a > b ? a : b);
    final latRange = (maxLat - minLat).abs() < 0.00001 ? 0.01 : maxLat - minLat;
    final lngRange = (maxLng - minLng).abs() < 0.00001 ? 0.01 : maxLng - minLng;
    final x = 30 + ((location.lng - minLng) / lngRange) * (size.width - 100);
    final y = 70 + ((maxLat - location.lat) / latRange) * (size.height - 120);
    return Offset(
      x.clamp(12.0, size.width - 88),
      y.clamp(54.0, size.height - 90),
    );
  }

  Color _markerColor(BusLocation location) {
    if (location.isStale()) return AppColors.alertOrange;
    return switch (location.status) {
      BusRunStatus.onRoute => AppColors.successGreen,
      BusRunStatus.delayed => AppColors.alertOrange,
      BusRunStatus.arrived => AppColors.safetyBlue,
      BusRunStatus.idle => AppColors.outline,
    };
  }
}

class _FleetMapPainter extends CustomPainter {
  final Map<String, BusLocation> locations;
  final String? selectedBusId;
  final bool isDark;

  const _FleetMapPainter({
    required this.locations,
    required this.selectedBusId,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = isDark ? const Color(0xFF101B2D) : const Color(0xFFEAF0F8);
    canvas.drawRect(Offset.zero & size, background);
    final road = Paint()
      ..color = isDark ? const Color(0xFF34445D) : const Color(0xFFD0DAE9)
      ..strokeWidth = 3;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }
  }

  @override
  bool shouldRepaint(covariant _FleetMapPainter oldDelegate) {
    return oldDelegate.locations != locations ||
        oldDelegate.selectedBusId != selectedBusId ||
        oldDelegate.isDark != isDark;
  }
}

class _BusMarker extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;

  const _BusMarker({
    required this.label,
    required this.selected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(selected ? 9 : 7),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: selected ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: selected ? 16 : 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendDot(color: AppColors.successGreen, label: 'On route'),
            SizedBox(width: 10),
            _LegendDot(color: AppColors.alertOrange, label: 'Delayed/stale'),
            SizedBox(width: 10),
            _LegendDot(color: AppColors.outline, label: 'Idle'),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
