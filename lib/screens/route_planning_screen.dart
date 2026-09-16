// lib/screens/route_planning_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';
import '../widgets/live_map_canvas.dart';
import '../services/firebase_service.dart';

// ============================================================
// DATA MODEL
// ============================================================

class RouteStop {
  final String id;
  final int order;
  final String time;
  final String name;
  final double lat;
  final double lng;
  final int studentsCount;
  final bool isCompleted;
  final bool isCurrent;
  final String? eta;
  final String? statusMessage;

  const RouteStop({
    required this.id,
    required this.order,
    required this.time,
    required this.name,
    required this.lat,
    required this.lng,
    this.studentsCount = 0,
    this.isCompleted = false,
    this.isCurrent = false,
    this.eta,
    this.statusMessage,
  });

  RouteStop copyWith({
    int? order,
    String? time,
    String? name,
    double? lat,
    double? lng,
    int? studentsCount,
    bool? isCompleted,
    bool? isCurrent,
    String? eta,
    String? statusMessage,
  }) {
    return RouteStop(
      id: id,
      order: order ?? this.order,
      time: time ?? this.time,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      studentsCount: studentsCount ?? this.studentsCount,
      isCompleted: isCompleted ?? this.isCompleted,
      isCurrent: isCurrent ?? this.isCurrent,
      eta: eta ?? this.eta,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  Map<String, dynamic> toMap() => {
        'order': order,
        'time': time,
        'name': name,
        'lat': lat,
        'lng': lng,
        'studentsCount': studentsCount,
        'isCompleted': isCompleted,
        'isCurrent': isCurrent,
        if (eta != null) 'eta': eta,
        if (statusMessage != null) 'statusMessage': statusMessage,
      };

  factory RouteStop.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    return RouteStop(
      id: id ?? map['id']?.toString() ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      time: map['time']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed stop',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      studentsCount: (map['studentsCount'] as num?)?.toInt() ?? 0,
      isCompleted: map['isCompleted'] == true,
      isCurrent: map['isCurrent'] == true,
      eta: map['eta']?.toString(),
      statusMessage: map['statusMessage']?.toString(),
    );
  }
}

// ============================================================
// SCREEN
// ============================================================

class RoutePlanningScreen extends StatefulWidget {
  /// The route to edit. If null, the screen shows a route list to pick
  /// from or create a new one.
  final String? routeId;

  const RoutePlanningScreen({super.key, this.routeId});

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedView = 'timeline'; // 'timeline' | 'map'

  /// The route currently being edited. Null while on the picker.
  String? _routeId;
  String _routeName = '';

  StreamSubscription<List<Map<String, dynamic>>>? _routeSubscription;
  List<RouteStop> _stops = const [];

  @override
  void initState() {
    super.initState();
    _routeId = widget.routeId;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    if (_routeId != null) {
      _loadRoute(_routeId!);
    }
  }

  @override
  void dispose() {
    _routeSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute(String routeId) async {
    // Load metadata (name) once, then stream the stops.
    final meta = await FirebaseService.instance.fetchRouteOnce(routeId);
    if (!mounted) return;
    setState(() {
      _routeId = routeId;
      _routeName = (meta?['name']?.toString() ?? '').trim();
    });

    await _routeSubscription?.cancel();
    _routeSubscription =
        FirebaseService.instance.streamRouteStops(routeId).listen((items) {
      if (!mounted) return;
      setState(() {
        _stops = items
            .map((m) => RouteStop.fromMap(m, id: m['id']?.toString()))
            .toList();
      });
    });
  }

  void _clearRoute() {
    _routeSubscription?.cancel();
    _routeSubscription = null;
    setState(() {
      _routeId = null;
      _routeName = '';
      _stops = const [];
      _selectedView = 'timeline';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          _routeId == null ? 'Routes' : 'Route: $_routeName',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: _routeId == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _clearRoute,
                tooltip: 'Back to routes',
              ),
        actions: [
          if (_routeId != null)
            IconButton(
              tooltip: 'Rename route',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showRenameDialog(_routeId!, _routeName),
            ),
          if (_routeId != null)
            IconButton(
              tooltip: 'Delete route',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmDeleteRoute(_routeId!, _routeName),
            ),
        ],
      ),
      floatingActionButton: _routeId == null
          ? FloatingActionButton.extended(
              onPressed: _showCreateRouteDialog,
              backgroundColor: AppColors.safetyBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Route'),
            )
          : FloatingActionButton.extended(
              onPressed: _showAddStopDialog,
              backgroundColor: AppColors.safetyBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add Stop'),
            ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _routeId == null
            ? _buildRoutePicker(context, isMobile)
            : Column(
                children: [
                  _buildViewSelector(),
                  Expanded(
                    child: _selectedView == 'timeline'
                        ? _buildTimelineView(context)
                        : _buildMapView(context),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // ROUTE PICKER (no route selected yet)
  // ============================================================

  Widget _buildRoutePicker(BuildContext context, bool isMobile) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.instance.streamAllRoutes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load routes: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.safetyBlue),
          );
        }
        final routes = snapshot.data!;
        if (routes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alt_route_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No routes yet',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a route, add stops to it, then assign it to a bus from the "Bus Operations" tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: routes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final route = routes[index];
            final id = route['id']?.toString() ?? '';
            final name = (route['name']?.toString() ?? '').trim();
            final description =
                (route['description']?.toString() ?? '').trim();
            final stopCount = (route['stops'] is Map)
                ? (route['stops'] as Map).length
                : 0;

            return Card(
              child: ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.safetyBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.alt_route_rounded,
                    color: AppColors.safetyBlue,
                  ),
                ),
                title: Text(
                  name.isEmpty ? 'Unnamed route' : name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      description.isEmpty ? 'No description' : description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$stopCount stop${stopCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _loadRoute(id),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // VIEW SELECTOR
  // ============================================================

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _buildViewOption('Timeline', 'timeline', Icons.timeline_rounded),
            _buildViewOption('Map', 'map', Icons.map_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOption(String label, String value, IconData icon) {
    final isSelected = _selectedView == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedView = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.safetyBlue
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.safetyBlue
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TIMELINE VIEW
  // ============================================================

  Widget _buildTimelineView(BuildContext context) {
    if (_stops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.place_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No stops yet',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap "Add Stop" to place the first pickup point on the map.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProgressSummary(),
        const SizedBox(height: 12),
        for (var i = 0; i < _stops.length; i++)
          _buildStopRow(context, _stops[i], i, isFirst: i == 0, isLast: i == _stops.length - 1),
      ],
    );
  }

  Widget _buildProgressSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _routeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_stops.length} stops • ${_getTotalStudents()} students',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopRow(
    BuildContext context,
    RouteStop stop,
    int index, {
    required bool isFirst,
    required bool isLast,
  }) {
    final color = AppColors.safetyBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEditStopDialog(stop),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stop.time.isEmpty ? '--:--' : stop.time} • '
                        '${stop.lat.toStringAsFixed(5)}, '
                        '${stop.lng.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Reorder / delete actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Move up',
                          icon: const Icon(Icons.keyboard_arrow_up_rounded),
                          onPressed: isFirst ? null : () => _moveStop(index, -1),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        IconButton(
                          tooltip: 'Move down',
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          onPressed: isLast ? null : () => _moveStop(index, 1),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Delete stop',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.errorRed,
                        size: 18,
                      ),
                      onPressed: () => _confirmDeleteStop(stop),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAP VIEW
  // ============================================================

  Widget _buildMapView(BuildContext context) {
    // Convert internal RouteStop list to the shape LiveMapCanvas expects.
    final stopsForMap = _stops
        .map((s) => <String, dynamic>{
              'lat': s.lat,
              'lng': s.lng,
              'name': s.name,
            })
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LiveMapCanvas(
          lat: null,
          lng: null,
          stops: stopsForMap,
          showInfoOverlay: false,
          showRecenterButton: false,
        ),
      ),
    );
  }

  // ============================================================
  // DIALOGS — CREATE / RENAME / DELETE ROUTE
  // ============================================================

  Future<void> _showCreateRouteDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Route name',
                hintText: 'e.g. Route 7A - Morning Run',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route name is required.')),
        );
      }
      return;
    }

    try {
      final id = await FirebaseService.instance.createRoute(
        name: name,
        description: descController.text,
      );
      if (!mounted) return;
      await _loadRoute(id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create route: $error')),
        );
      }
    }
  }

  Future<void> _showRenameDialog(String routeId, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename route'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Route name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final newName = controller.text.trim();
    if (newName.isEmpty) return;
    try {
      await FirebaseService.instance.updateRouteMeta(
        routeId: routeId,
        name: newName,
      );
      if (!mounted) return;
      setState(() => _routeName = newName);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not rename route: $error')),
        );
      }
    }
  }

  Future<void> _confirmDeleteRoute(String routeId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete route?'),
        content: Text(
          'This will permanently delete "$name" and all its stops. '
          'Buses assigned to this route must be reassigned first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseService.instance.deleteRoute(routeId);
      if (!mounted) return;
      _clearRoute();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route deleted.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete route: $error')),
        );
      }
    }
  }

  // ============================================================
  // DIALOGS — STOP CRUD
  // ============================================================

  Future<void> _showAddStopDialog() async {
    final result = await Navigator.of(context).push<_StopLocationResult>(
      MaterialPageRoute(
        builder: (_) => _PickStopLocationScreen(
          initialCenter: _initialStopCenter(),
        ),
      ),
    );
    if (result == null || !mounted) return;

    // Show the metadata form with the picked location.
    final stop = await _showStopMetadataDialog(
      initialName: '',
      initialTime: '',
      initialStudents: 0,
      lat: result.lat,
      lng: result.lng,
      isEditing: false,
    );
    if (stop == null || !mounted) return;

    final routeId = _routeId;
    if (routeId == null) return;

    final stopId = 'stop_${DateTime.now().millisecondsSinceEpoch}';
    final nextOrder = _stops.isEmpty ? 0 : _stops.last.order + 1;
    final toSave = stop.copyWith(order: nextOrder);

    try {
      await FirebaseService.instance
          .saveRouteStop(routeId, stopId, toSave.toMap());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save stop: $error')),
        );
      }
    }
  }

  LatLng _initialStopCenter() {
    if (_stops.isNotEmpty) {
      final last = _stops.last;
      return LatLng(last.lat, last.lng);
    }
    return const LatLng(20.5937, 78.9629); // India centroid
  }

  Future<void> _showEditStopDialog(RouteStop stop) async {
    final updated = await _showStopMetadataDialog(
      initialName: stop.name,
      initialTime: stop.time,
      initialStudents: stop.studentsCount,
      lat: stop.lat,
      lng: stop.lng,
      isEditing: true,
    );
    if (updated == null || !mounted) return;
    final routeId = _routeId;
    if (routeId == null) return;
    try {
      await FirebaseService.instance.saveRouteStop(
        routeId,
        stop.id,
        updated.copyWith(order: stop.order).toMap(),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update stop: $error')),
        );
      }
    }
  }

  Future<RouteStop?> _showStopMetadataDialog({
    required String initialName,
    required String initialTime,
    required int initialStudents,
    required double lat,
    required double lng,
    required bool isEditing,
  }) async {
    final nameController = TextEditingController(text: initialName);
    final timeController = TextEditingController(text: initialTime);
    final studentsController =
        TextEditingController(text: initialStudents.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? 'Edit stop' : 'Add stop'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Location: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Stop name',
                  hintText: 'e.g. Oak St & Maple Ave',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Scheduled time',
                  hintText: 'e.g. 08:15 AM',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: studentsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Students at this stop (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );

    if (confirmed != true) return null;
    final name = nameController.text.trim();
    if (name.isEmpty) return null;

    return RouteStop(
      id: '',
      order: 0,
      time: timeController.text.trim(),
      name: name,
      lat: lat,
      lng: lng,
      studentsCount: int.tryParse(studentsController.text.trim()) ?? 0,
    );
  }

  Future<void> _confirmDeleteStop(RouteStop stop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete stop?'),
        content: Text('Remove "${stop.name}" from this route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final routeId = _routeId;
    if (routeId == null) return;
    try {
      await FirebaseService.instance.removeRouteStop(routeId, stop.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete stop: $error')),
        );
      }
    }
  }

  Future<void> _moveStop(int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= _stops.length) return;
    final reordered = List<RouteStop>.from(_stops);
    final item = reordered.removeAt(index);
    reordered.insert(target, item);
    final ids = reordered.map((s) => s.id).toList();
    final routeId = _routeId;
    if (routeId == null) return;
    try {
      await FirebaseService.instance.reorderRouteStops(routeId, ids);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reorder stops: $error')),
        );
      }
    }
  }

  int _getTotalStudents() {
    return _stops.fold(0, (sum, s) => sum + s.studentsCount);
  }
}

// ============================================================
// PICK STOP LOCATION SCREEN
// ============================================================

class _StopLocationResult {
  final double lat;
  final double lng;
  _StopLocationResult(this.lat, this.lng);
}

class _PickStopLocationScreen extends StatefulWidget {
  final LatLng initialCenter;
  const _PickStopLocationScreen({required this.initialCenter});

  @override
  State<_PickStopLocationScreen> createState() =>
      _PickStopLocationScreenState();
}

class _PickStopLocationScreenState extends State<_PickStopLocationScreen> {
  final MapController _mapController = MapController();
  LatLng _selected = const LatLng(0, 0);
  bool _hasSelected = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCenter;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick stop location'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                setState(() {
                  _selected = point;
                  _hasSelected = true;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.schoolbussafe.schoolbusSafe',
              ),
              if (_hasSelected)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.alertOrange,
                        size: 44,
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: AppTheme.panelDecoration(context, borderRadius: 12),
              child: Text(
                _hasSelected
                    ? 'Selected: ${_selected.latitude.toStringAsFixed(5)}, '
                        '${_selected.longitude.toStringAsFixed(5)}'
                    : 'Tap on the map to place the stop marker',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _hasSelected
            ? () => Navigator.of(context).pop(
                  _StopLocationResult(_selected.latitude, _selected.longitude),
                )
            : null,
        backgroundColor: AppColors.safetyBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Use this location'),
      ),
    );
  }
}