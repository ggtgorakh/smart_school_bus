// lib/screens/trip_workflow_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/bus_fleet.dart';
import '../models/trip.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'emergency_sos_sheet.dart';

class TripWorkflowScreen extends StatefulWidget {
  final String busId;
  final String role;

  const TripWorkflowScreen({
    super.key,
    required this.busId,
    required this.role,
  });

  @override
  State<TripWorkflowScreen> createState() => _TripWorkflowScreenState();
}

class _TripWorkflowScreenState extends State<TripWorkflowScreen> {
  bool _isSaving = false;
  bool _isTransitioning = false;
  Trip? _openTrip;

  @override
  void initState() {
    super.initState();
    _checkActiveTripTracking();
  }

  Future<void> _checkActiveTripTracking() async {
    if (widget.role != 'Driver') return;
    try {
      final trip =
          await FirebaseService.instance.streamActiveTrip(widget.busId).first;
      if (trip != null &&
          trip.status == TripStatus.active &&
          !LocationService.instance.isTracking) {
        await LocationService.instance.startTracking(trip.busId);
      }
    } catch (_) {}
  }

  Future<void> _createTrip(String routeId) async {
    final driverUid = FirebaseAuth.instance.currentUser?.uid;
    if (routeId.trim().isEmpty || driverUid == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseService.instance.createTrip(
        busId: widget.busId,
        routeId: routeId.trim(),
        driverUid: driverUid,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create trip: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _transition(Trip trip, TripStatus status) async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    try {
      await FirebaseService.instance.transitionTrip(
        busId: trip.busId,
        tripId: trip.tripId,
        nextStatus: status,
      );
      if (widget.role == 'Driver') {
        if (status == TripStatus.active) {
          await LocationService.instance.startTracking(trip.busId);
        } else if (status == TripStatus.completed ||
            status == TripStatus.cancelled) {
          await LocationService.instance.stopTracking(busId: trip.busId);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update trip: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTransitioning = false);
    }
  }

  void _openSOS() {
    EmergencySosSheet.show(
      context,
      busId: widget.busId,
      tripId: _openTrip?.tripId,
      actorRole: widget.role,
    );
  }

  Future<void> _callConductor(String number) async {
    final clean = number.trim();
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the phone app.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BusFleet?>(
      stream: FirebaseService.instance.streamFleetBus(widget.busId),
      builder: (context, fleetSnapshot) {
        final fleetBus = fleetSnapshot.data;
        final assignedRouteId = fleetBus?.routeId?.trim();
        final hasRoute =
            assignedRouteId != null && assignedRouteId.isNotEmpty;

        return StreamBuilder<List<Trip>>(
          stream: FirebaseService.instance.streamTripsForBus(widget.busId),
          builder: (context, tripSnapshot) {
            final trips = tripSnapshot.data ?? const <Trip>[];
            final openTrip = trips.where((trip) => trip.isOpen).firstOrNull;
            _openTrip = openTrip;

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                title: const Text(
                  'Trip Operations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              floatingActionButton: (widget.role == 'Driver' ||
                      widget.role == 'Conductor')
                  ? FloatingActionButton.extended(
                      heroTag: 'sos_fab_trip',
                      onPressed: _openSOS,
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.sos_rounded),
                      label: const Text('SOS'),
                    )
                  : null,
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Assigned bus: ${widget.busId.toUpperCase()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  if (hasRoute)
                    Row(
                      children: [
                        const Icon(
                          Icons.alt_route_rounded,
                          size: 16,
                          color: AppColors.safetyBlue,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Route: ${fleetBus!.routeName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.amberSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              AppColors.alertOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.alertOrangeDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No route assigned to this bus. Ask your '
                              'administrator to assign a route before '
                              'starting a trip.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ─────────────────────────────────────────────
                  // CONDUCTOR INFO (Unit 5 — new)
                  // Shown to Driver and Conductor alike, so each can
                  // reach the other by phone.
                  // ─────────────────────────────────────────────
                  if (fleetBus != null && fleetBus.conductorName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _StaffRow(
                        label: 'Conductor',
                        name: fleetBus.conductorName ?? 'Unassigned',
                        phone: fleetBus.conductorPhone,
                        icon: Icons.badge_rounded,
                        color: AppColors.successGreen,
                        onCall: (fleetBus.conductorPhone != null &&
                                fleetBus.conductorPhone!.trim().isNotEmpty)
                            ? () => _callConductor(fleetBus.conductorPhone!)
                            : null,
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (openTrip == null && widget.role == 'Driver') ...[
                    FilledButton.icon(
                      onPressed: (!hasRoute || _isSaving)
                          ? null
                          : () => _createTrip(assignedRouteId),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.playlist_add),
                      label: const Text('Schedule Trip'),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (openTrip != null)
                    _TripCard(
                      trip: openTrip,
                      routeName: fleetBus?.routeName ?? openTrip.routeId,
                      canOperate: widget.role == 'Driver',
                      isBusy: _isTransitioning,
                      onTransition: (status) => _transition(openTrip, status),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          widget.role == 'Driver'
                              ? (hasRoute
                                  ? 'No open trip. Tap "Schedule Trip" to start.'
                                  : 'No open trip. Assign a route first.')
                              : 'No open trip is currently assigned to this bus.',
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  Text(
                    'Trip history',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...trips
                      .where((trip) => !trip.isOpen)
                      .map(
                        (trip) => ListTile(
                          leading: Icon(
                            trip.status == TripStatus.completed
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: trip.status == TripStatus.completed
                                ? AppColors.successGreen
                                : AppColors.errorRed,
                          ),
                          title: Text(
                            trip.routeId == fleetBus?.routeId
                                ? (fleetBus?.routeName ?? trip.routeId)
                                : trip.routeId,
                          ),
                          subtitle:
                              Text('${trip.status.name} • ${trip.tripId}'),
                        ),
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// STAFF ROW (conductor info shown to driver)
// ============================================================

class _StaffRow extends StatelessWidget {
  final String label;
  final String name;
  final String? phone;
  final IconData icon;
  final Color color;
  final VoidCallback? onCall;

  const _StaffRow({
    required this.label,
    required this.name,
    required this.phone,
    required this.icon,
    required this.color,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hasPhone)
                  Text(
                    phone!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (onCall != null)
            IconButton(
              onPressed: onCall,
              icon: Icon(Icons.call_rounded, color: color, size: 20),
              tooltip: 'Call $label',
            ),
        ],
      ),
    );
  }
}

// ============================================================
// TRIP CARD
// ============================================================

class _TripCard extends StatelessWidget {
  final Trip trip;
  final String routeName;
  final bool canOperate;
  final bool isBusy;
  final ValueChanged<TripStatus> onTransition;

  const _TripCard({
    required this.trip,
    required this.routeName,
    required this.canOperate,
    this.isBusy = false,
    required this.onTransition,
  });

  @override
  Widget build(BuildContext context) {
    final nextStatus = switch (trip.status) {
      TripStatus.scheduled => TripStatus.preparing,
      TripStatus.preparing => TripStatus.active,
      TripStatus.active => TripStatus.paused,
      TripStatus.paused => TripStatus.active,
      TripStatus.completed || TripStatus.cancelled => null,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routeName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text('Status: ${trip.status.name}'),
            if (trip.startTime != null)
              Text('Started: ${trip.startTime!.toLocal()}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canOperate && nextStatus != null)
                  FilledButton(
                    onPressed:
                        isBusy ? null : () => onTransition(nextStatus),
                    child: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            nextStatus == TripStatus.active
                                ? 'Start trip'
                                : nextStatus == TripStatus.paused
                                    ? 'Pause trip'
                                    : 'Prepare trip',
                          ),
                  ),
                if (canOperate &&
                    (trip.status == TripStatus.active ||
                        trip.status == TripStatus.paused))
                  OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => onTransition(TripStatus.completed),
                    child: const Text('End trip'),
                  ),
                if (canOperate && trip.status != TripStatus.cancelled)
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => onTransition(TripStatus.cancelled),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}