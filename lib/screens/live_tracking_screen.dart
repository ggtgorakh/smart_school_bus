import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/bus_fleet.dart';
import '../widgets/live_map_canvas.dart';
import '../widgets/route_progress_track.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stop = StopInfo(
      stopNumber: 3,
      totalStops: 8,
      stopName: 'Elm Street',
      minsAway: '4 mins away',
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: LiveMapCanvas(
              busStatus: 'On Route',
              etaTime: '8:14 AM',
              busNumber: 'Bus 42',
            ),
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
                                'Coming to ${stop.stopName}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Stop ${stop.stopNumber} of ${stop.totalStops} • ${stop.minsAway}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      totalStops: stop.totalStops,
                      currentStopIndex: stop.stopNumber - 1,
                      currentStopLabel: 'Next: ${stop.stopName}',
                      etaLabel: stop.minsAway,
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
                                  'Sarah Johnson',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '4th Grade • Seat 3A',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12),
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
                                  const SnackBar(
                                    content: Text('Calling Bus Driver (Sarah Jenkins)...'),
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
      ),
    );
  }
}
