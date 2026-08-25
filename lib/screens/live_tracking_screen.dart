import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/bus_location.dart';
import '../services/firebase_service.dart';
import '../widgets/live_map_canvas.dart';
import '../widgets/route_progress_track.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String busId;

  // TODO: replace with the real logged-in student's name/grade/seat once
  // the parent-student link is wired up (separate from this GPS pass).
  final String studentName;
  final String studentGradeAndSeat;

  const LiveTrackingScreen({
    super.key,
    this.busId = 'bus_01',
    this.studentName = 'Sarah Johnson',
    this.studentGradeAndSeat = '4th Grade • Seat 3A',
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late final Stream<BusLocation?> _locationStream;

  @override
  void initState() {
    super.initState();
    _locationStream =
        FirebaseService.instance.streamBusLocation(widget.busId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<BusLocation?>(
        stream: _locationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _TrackingStateMessage(
              icon: Icons.satellite_alt_rounded,
              title: 'Connecting to bus…',
              subtitle: 'Waiting for the first GPS reading.',
            );
          }

          if (snapshot.hasError) {
            return const _TrackingStateMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Can\'t reach live tracking',
              subtitle: 'Check your connection and try again shortly.',
            );
          }

          final location = snapshot.data;
          if (location == null) {
            return const _TrackingStateMessage(
              icon: Icons.directions_bus_filled_rounded,
              title: 'No signal from the bus yet',
              subtitle:
                  'The bus hasn\'t started its route or the tracker is offline.',
            );
          }

          return _LiveTrackingContent(
            location: location,
            studentName: widget.studentName,
            studentGradeAndSeat: widget.studentGradeAndSeat,
          );
        },
      ),
    );
  }
}

class _LiveTrackingContent extends StatelessWidget {
  final BusLocation location;
  final String studentName;
  final String studentGradeAndSeat;

  const _LiveTrackingContent({
    required this.location,
    required this.studentName,
    required this.studentGradeAndSeat,
  });

  @override
  Widget build(BuildContext context) {
    final stale = location.isStale();

    return Stack(
      children: [
        Positioned.fill(
          child: LiveMapCanvas(
            busStatus: location.statusLabel,
            etaTime: location.etaLabel,
            busNumber: location.busNumber,
          ),
        ),
        if (stale)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _StaleBanner(lastUpdated: location.lastUpdated),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.glassDecoration(borderRadius: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Next-stop headline row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.amberSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.alertOrangeDark,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coming to ${location.currentStopLabel}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stop ${location.currentStopIndex + 1} of ${location.totalStops} • ${location.etaLabel}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Signature route-progress track.
                  RouteProgressTrack(
                    totalStops: location.totalStops,
                    currentStopIndex: location.currentStopIndex,
                    currentStopLabel: 'Next: ${location.currentStopLabel}',
                    etaLabel: location.etaLabel,
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: AppColors.outlineVariant, height: 1),
                  const SizedBox(height: 14),

                  // Student info row
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.brandGradient,
                          ),
                          child: const Icon(
                            Icons.face_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                              ),
                              Text(
                                studentGradeAndSeat,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.call_rounded,
                              color: AppColors.safetyBlue,
                              size: 20,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Calling driver of ${location.busNumber}...'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaleBanner extends StatelessWidget {
  final DateTime lastUpdated;

  const _StaleBanner({required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final minutesAgo = DateTime.now().difference(lastUpdated).inMinutes;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.alertOrange.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Signal lost — last update $minutesAgo min ago',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrackingStateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
