import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

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
  final _routeIdController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _routeIdController.dispose();
    super.dispose();
  }

  Future<void> _createTrip() async {
    final routeId = _routeIdController.text.trim();
    final driverUid = FirebaseAuth.instance.currentUser?.uid;
    if (routeId.isEmpty || driverUid == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseService.instance.createTrip(
        busId: widget.busId,
        routeId: routeId,
        driverUid: driverUid,
      );
      _routeIdController.clear();
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
    try {
      await FirebaseService.instance.transitionTrip(
        busId: trip.busId,
        tripId: trip.tripId,
        nextStatus: status,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update trip: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Trip>>(
      stream: FirebaseService.instance.streamTripsForBus(widget.busId),
      builder: (context, snapshot) {
        final trips = snapshot.data ?? const <Trip>[];
        final openTrip = trips.where((trip) => trip.isOpen).firstOrNull;

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Trip Operations',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Assigned bus: ${widget.busId}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (openTrip == null && widget.role == 'Driver') ...[
                TextField(
                  controller: _routeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Route ID',
                    hintText: 'Enter the configured Firebase route ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _createTrip,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Schedule Trip'),
                ),
                const SizedBox(height: 20),
              ],
              if (openTrip != null)
                _TripCard(
                  trip: openTrip,
                  canOperate: widget.role == 'Driver',
                  onTransition: (status) => _transition(openTrip, status),
                )
              else
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No open trip is currently assigned to this bus.',
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
                      title: Text(trip.routeId),
                      subtitle: Text('${trip.status.name} • ${trip.tripId}'),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final bool canOperate;
  final ValueChanged<TripStatus> onTransition;

  const _TripCard({
    required this.trip,
    required this.canOperate,
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
              'Route ${trip.routeId}',
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
                    onPressed: () => onTransition(nextStatus),
                    child: Text(
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
                    onPressed: () => onTransition(TripStatus.completed),
                    child: const Text('End trip'),
                  ),
                if (canOperate && trip.status != TripStatus.cancelled)
                  TextButton(
                    onPressed: () => onTransition(TripStatus.cancelled),
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
