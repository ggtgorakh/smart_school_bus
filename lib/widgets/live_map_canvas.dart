// lib/widgets/live_map_canvas.dart


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

/// A real geographic map showing a bus's live location, optional route
/// stops, and optional overlays.
///
/// Replaces the previous `CustomPaint` illustration. SRS §10.6 requires an
/// actual map — this widget uses `flutter_map` with OpenStreetMap tiles,
/// which work on every platform without an API key.
///
/// TILE PROVIDER:
/// OpenStreetMap's public tile servers are free for development and
/// non-commercial use per their tile usage policy. A production
/// deployment must switch to a commercial provider (MapTiler, Stadia,
/// Thunderforest, etc.) and supply an API key. To swap, replace
/// [TileLayer.urlTemplate] with the provider's template and add the key.
class LiveMapCanvas extends StatefulWidget {
  /// Bus's current latitude. If null, no bus marker is drawn.
  final double? lat;

  /// Bus's current longitude.
  final double? lng;

  /// Human-readable bus status (e.g. "On Route"). Shown in a small badge
  /// above the bus marker.
  final String busStatus;

  /// Human-readable ETA label (e.g. "4 mins away"). Reserved for the
  /// optional info overlay.
  final String etaTime;

  /// Bus identifier (e.g. "bus_01" or "BUS 7A"). Shown on the marker.
  final String busNumber;

  /// Legacy param: kept for source compatibility with the previous
  /// illustration widget. Ignored — the map now uses real coordinates.
  final double progress;

  /// Bus speed in km/h. Shown in the info overlay when [showInfoOverlay]
  /// is true.
  final double speedKmph;

  /// Route stops to render as markers. Each map is expected to contain
  /// `lat` (num), `lng` (num), and `name` (String). Additional keys are
  /// ignored. If empty, no stop markers are drawn.
  final List<Map<String, dynamic>> stops;

  /// Index of the "next" stop to highlight. -1 (default) highlights none.
  final int currentStopIndex;

  /// Whether to render the top info overlay (ETA + bus number + status).
  final bool showInfoOverlay;

  /// Optional banner shown above the info overlay. Preserved from the
  /// previous widget so existing callers don't break.
  final Widget? topBanner;

  /// Optional widget shown below the info overlay.
  final Widget? trailingAction;

  /// Whether to show the "recenter" FAB that animates the camera back to
  /// the bus. Useful when the user pans away.
  final bool showRecenterButton;

  /// Initial zoom level. Defaults to 15 (street level).
  final double initialZoom;

  const LiveMapCanvas({
    super.key,
    this.lat,
    this.lng,
    this.busStatus = 'On Route',
    this.etaTime = '8:14 AM',
    this.busNumber = 'Bus',
    this.progress = 0.5,
    this.speedKmph = 0.0,
    this.stops = const [],
    this.currentStopIndex = -1,
    this.showInfoOverlay = true,
    this.topBanner,
    this.trailingAction,
    this.showRecenterButton = true,
    this.initialZoom = 15,
  });

  @override
  State<LiveMapCanvas> createState() => _LiveMapCanvasState();
}

class _LiveMapCanvasState extends State<LiveMapCanvas>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  /// Track whether the user has manually panned/zoomed away from the bus.
  /// When true, the recenter FAB becomes prominent.
  bool _userMovedAway = false;
  bool _mapReady = false;

  LatLng? get _busLatLng {
    final lat = widget.lat;
    final lng = widget.lng;
    if (lat == null || lng == null) return null;
    if (lat == 0.0 && lng == 0.0) return null; // treat (0,0) as "no fix"
    return LatLng(lat, lng);
  }

  /// Compute a sensible initial center and zoom based on available data:
  ///   1. Bus position, if available.
  ///   2. Else, midpoint of stop positions.
  ///   3. Else, a global fallback.
  LatLng get _initialCenter {
    final bus = _busLatLng;
    if (bus != null) return bus;

    if (widget.stops.isNotEmpty) {
      double sumLat = 0, sumLng = 0;
      int count = 0;
      for (final s in widget.stops) {
        final lat = (s['lat'] as num?)?.toDouble();
        final lng = (s['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          sumLat += lat;
          sumLng += lng;
          count++;
        }
      }
      if (count > 0) {
        return LatLng(sumLat / count, sumLng / count);
      }
    }
    // Fallback: somewhere neutral. Won't be visible if the map has no
    // markers, but prevents a crash.
    return const LatLng(20.5937, 78.9629); // India centroid
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant LiveMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the bus position changed and the user hasn't panned away, keep
    // the camera centered on it. This gives the "follow me" behavior for
    // parents who don't interact with the map.
    final oldLatLng = _coordsOf(oldWidget);
    final newLatLng = _busLatLng;
    if (newLatLng != null && newLatLng != oldLatLng && !_userMovedAway && _mapReady) {
      _mapController.move(newLatLng, _mapController.camera.zoom);
    }
  }

  LatLng? _coordsOf(LiveMapCanvas w) {
    final lat = w.lat;
    final lng = w.lng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _recenterOnBus() {
    final bus = _busLatLng;
    if (bus == null) return;
    _mapController.move(bus, _mapController.camera.zoom);
    if (mounted) setState(() => _userMovedAway = false);
  }

  @override
  Widget build(BuildContext context) {
    final bus = _busLatLng;

    // Stop markers: build list from `stops`.
    final stopMarkers = <Marker>[];
    for (var i = 0; i < widget.stops.length; i++) {
      final s = widget.stops[i];
      final lat = (s['lat'] as num?)?.toDouble();
      final lng = (s['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final isCurrent = i == widget.currentStopIndex;
      stopMarkers.add(
        Marker(
          point: LatLng(lat, lng),
          width: isCurrent ? 44 : 32,
          height: isCurrent ? 44 : 32,
          alignment: Alignment.center,
          child: _StopMarker(
            label: s['name']?.toString() ?? 'Stop',
            isCurrent: isCurrent,
          ),
        ),
      );
    }

    // Bus marker (only if we have a fix).
    final busMarkers = <Marker>[];
    if (bus != null) {
      busMarkers.add(
        Marker(
          point: bus,
          width: 110,
          height: 90,
          alignment: Alignment.topCenter,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return _BusMarker(
                statusLabel: widget.busStatus,
                pulseScale: _pulseAnimation.value,
              );
            },
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: widget.initialZoom,
                    minZoom: 3,
                    maxZoom: 18,
                    interactionOptions: const InteractionOptions(
                      // Enable pan + pinch, but disable the built-in
                      // rotate gestures — they cause accidental rotation
                      // on small screens and are not needed here.
                      flags: InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.flingAnimation,
                    ),
                    onMapReady: () {
                      _mapReady = true;
                      // First fit: if we have a bus and stops, frame them.
                      _fitToMarkersIfPossible();
                    },
                    onPositionChanged: (camera, hasGesture) {
                      // Detect user-initiated pan/zoom (hasGesture == true).
                      if (hasGesture && !_userMovedAway) {
                        setState(() => _userMovedAway = true);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      // OpenStreetMap standard tiles. See class docstring
                      // for the production-provider note.
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.schoolbussafe.schoolbusSafe',
                      // Cache tiles in-memory so re-centering is snappy.
                      tileProvider: NetworkTileProvider(),
                      maxNativeZoom: 19,
                    ),
                    // Optional: draw a faint polyline through the stops in
                    // order. This gives a sense of route without needing
                    // real road-network data.
                    if (widget.stops.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints(),
                            strokeWidth: 4,
                            color: AppColors.safetyBlue.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    if (stopMarkers.isNotEmpty)
                      MarkerLayer(markers: stopMarkers),
                    if (busMarkers.isNotEmpty)
                      MarkerLayer(markers: busMarkers),
                    // Attribution is required by the OSM tile usage policy.
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Top info overlay (optional).
            if (widget.showInfoOverlay)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.topBanner != null) ...[
                      widget.topBanner!,
                      const SizedBox(height: 8),
                    ],
                    _InfoOverlay(
                      etaTime: widget.etaTime,
                      busNumber: widget.busNumber,
                      busStatus: widget.busStatus,
                      speedKmph: widget.speedKmph,
                    ),
                    if (widget.trailingAction != null) ...[
                      const SizedBox(height: 8),
                      widget.trailingAction!,
                    ],
                  ],
                ),
              ),

            // "No location" placeholder — displayed when we have no bus
            // fix, so the screen shows something meaningful rather than an
            // arbitrary map of India.
            if (bus == null && stopMarkers.isEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.03),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off_rounded,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Waiting for the first GPS fix',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Recenter button — only shown when the user has panned away
            // from the bus.
            if (widget.showRecenterButton && bus != null && _userMovedAway)
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'recenter_${widget.busNumber}',
                  tooltip: 'Recenter on bus',
                  onPressed: _recenterOnBus,
                  backgroundColor: AppColors.safetyBlue,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ),
          ],
        );
      },
    );
  }

  List<LatLng> _routePoints() {
    final points = <LatLng>[];
    for (final s in widget.stops) {
      final lat = (s['lat'] as num?)?.toDouble();
      final lng = (s['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
      }
    }
    return points;
  }

  /// On first load, zoom the map to fit both the bus and all stops (with
  /// padding). If we only have one of the two, just center on it.
  void _fitToMarkersIfPossible() {
    final points = <LatLng>[];
    final bus = _busLatLng;
    if (bus != null) points.add(bus);
    points.addAll(_routePoints());

    if (points.length >= 2) {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.fromLTRB(50, 120, 50, 180),
          maxZoom: 16,
        ),
      );
    }
  }
}

// ============================================================
// BUS MARKER
// ============================================================

class _BusMarker extends StatelessWidget {
  final String statusLabel;
  final double pulseScale;

  const _BusMarker({
    required this.statusLabel,
    required this.pulseScale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.safetyBlue.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                statusLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Pulsing bus icon
        Transform.scale(
          scale: pulseScale,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.safetyBlue.withValues(alpha: 0.18),
            ),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STOP MARKER
// ============================================================

class _StopMarker extends StatelessWidget {
  final String label;
  final bool isCurrent;

  const _StopMarker({
    required this.label,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCurrent ? AppColors.alertOrange : AppColors.outline;
    return Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: isCurrent ? 10 : 4,
            ),
          ],
        ),
        child: isCurrent
            ? const Icon(
                Icons.place_rounded,
                color: Colors.white,
                size: 18,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

// ============================================================
// INFO OVERLAY
// ============================================================

class _InfoOverlay extends StatelessWidget {
  final String etaTime;
  final String busNumber;
  final String busStatus;
  final double speedKmph;

  const _InfoOverlay({
    required this.etaTime,
    required this.busNumber,
    required this.busStatus,
    required this.speedKmph,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: AppTheme.panelDecoration(
            context,
            borderRadius: 14,
            elevated: true,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ESTIMATED ARRIVAL',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontSize: 10, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      etaTime,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.tabularTime(
                        fontSize: 22,
                        color: AppColors.alertOrangeDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$busNumber • ${speedKmph.toStringAsFixed(0)} km/h',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: AppColors.successGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            busStatus,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}