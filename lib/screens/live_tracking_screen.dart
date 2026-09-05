// lib/screens/live_tracking_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/bus_fleet.dart';
import '../models/bus_location.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../widgets/live_map_canvas.dart';
import '../widgets/route_progress_track.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String busId;
  final bool canCallDriver;
  final String studentName;
  final String studentGradeAndSeat;

  const LiveTrackingScreen({
    super.key,
    this.busId = 'bus_01',
    this.canCallDriver = true,
    this.studentName = '',
    this.studentGradeAndSeat = '',
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  late final Stream<BusLocation?> _locationStream;
  StreamSubscription<BusLocation?>? _statusSub;
  Timer? _staleTimer;
  BusRunStatus? _lastNotifiedStatus;
  bool? _lastStaleState;
  BusLocation? _lastLocation;
  Future<void> _notificationQueue = Future<void>.value();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isBottomSheetExpanded = false;
  BusFleet? _fleetBus;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _locationStream = FirebaseService.instance.streamBusLocation(widget.busId);
    FirebaseService.instance.fetchFleetBusOnce(widget.busId).then((bus) {
      if (mounted) setState(() => _fleetBus = bus);
    });
    _statusSub = _locationStream.listen(
      _handleLocationUpdate,
      onError: (error) {
        setState(() {
          _hasError = true;
          _errorMessage = error.toString();
          _isLoading = false;
        });
        debugPrint('LiveTrackingScreen location stream error: $error');
      },
    );
    _staleTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final location = _lastLocation;
      if (location != null) _processLocation(location);
    });

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _staleTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLocationUpdate(BusLocation? location) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _hasError = false;
    });

    if (location == null) return;
    _lastLocation = location;
    _processLocation(location);
  }

  void _processLocation(BusLocation location) {
    final oldStatus = _lastNotifiedStatus;
    final stale = location.isStale();
    final staleChanged = _lastStaleState != stale;
    final statusChanged = _lastNotifiedStatus != location.status;
    _lastNotifiedStatus = location.status;
    _lastStaleState = stale;
    if ((!statusChanged || oldStatus == null) && !staleChanged) return;

    _notificationQueue = _notificationQueue.then((_) async {
      try {
        if (statusChanged && oldStatus != null) {
          await NotificationService.instance.notifyBusStatusChange(
            busId: widget.busId,
            busNumber: location.busNumber,
            oldStatus: oldStatus.name,
            newStatus: location.status.name,
            stopLabel: location.currentStopLabel,
            etaMinutes: location.etaMinutes,
          );
        }
        if (staleChanged) {
          await NotificationService.instance.notifyTrackerStale(
            busId: widget.busId,
            busNumber: location.busNumber,
            isStale: stale,
            lastUpdated: location.lastUpdated,
          );
        }
      } catch (error) {
        debugPrint('Unable to save live tracking notification: $error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: widget.canCallDriver &&
              _fleetBus?.driverPhone?.trim().isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: _callDriver,
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.call_rounded),
              label: const Text('Call driver'),
            )
          : null,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<BusLocation?>(
          stream: _locationStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                _isLoading) {
              return const _LoadingState();
            }

            if (snapshot.hasError || _hasError) {
              return _ErrorState(
                errorMessage: _hasError ? _errorMessage : '${snapshot.error}',
                onRetry: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _statusSub?.cancel();
                  _statusSub = _locationStream.listen(
                    _handleLocationUpdate,
                    onError: (error) {
                      setState(() {
                        _hasError = true;
                        _errorMessage = error.toString();
                        _isLoading = false;
                      });
                    },
                  );
                },
              );
            }

            final location = snapshot.data;
            if (location == null) {
              return const _EmptyState();
            }

            return SlideTransition(
              position: _slideAnimation,
              child: _LiveTrackingContent(
                location: location,
                studentName: widget.studentName,
                studentGradeAndSeat: widget.studentGradeAndSeat,
                isExpanded: _isBottomSheetExpanded,
                onExpandToggle: () => setState(
                  () => _isBottomSheetExpanded = !_isBottomSheetExpanded,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _callDriver() async {
    final phone = _fleetBus?.driverPhone?.trim();
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone app.')),
      );
    }
  }
}

// ============================================================
// LOADING STATE
// ============================================================

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.safetyBlue.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus_filled_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.safetyBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connecting to bus...',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Waiting for the first GPS reading',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class _ErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorState({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: AppColors.errorRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Can't reach live tracking",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                size: 56,
                color: AppColors.alertOrangeDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bus data not available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The bus hasn\'t started its route or the tracker is offline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAIN CONTENT
// ============================================================

class _LiveTrackingContent extends StatelessWidget {
  final BusLocation location;
  final String studentName;
  final String studentGradeAndSeat;
  final bool isExpanded;
  final VoidCallback onExpandToggle;

  const _LiveTrackingContent({
    required this.location,
    required this.studentName,
    required this.studentGradeAndSeat,
    required this.isExpanded,
    required this.onExpandToggle,
  });

  @override
  Widget build(BuildContext context) {
    final location = this.location;
    final stale = location.isStale();
    final double progress = location.totalStops > 0
        ? (location.currentStopIndex / location.totalStops).clamp(0.0, 1.0)
        : 0.5;
    final isMobile = context.isMobile;

    return Stack(
      children: [
        // Map Background
        Positioned.fill(
          child: LiveMapCanvas(
            busStatus: location.statusLabel,
            etaTime: location.etaLabel,
            busNumber: location.busNumber,
            progress: progress,
            speedKmph: location.speedKmph,
            showInfoOverlay: false,
          ),
        ),

        // Bottom Sheet
        Positioned(
          left: isMobile ? 10 : null,
          right: isMobile ? 10 : 24,
          top: isMobile ? null : 24,
          bottom: isMobile ? 10 : 24,
          child: Align(
            alignment: isMobile
                ? Alignment.bottomCenter
                : Alignment.centerRight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 420,
                maxHeight: isMobile ? 360 : double.infinity,
              ),
              decoration: AppTheme.panelDecoration(
                context,
                borderRadius: isMobile ? 12 : 14,
                elevated: true,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onExpandToggle,
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMobile) ...[
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
                            const SizedBox(height: 12),
                          ],

                          // Next-stop headline row
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
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
                                            fontSize: isMobile ? 15 : 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Stop ${location.currentStopIndex + 1} of ${location.totalStops} • ${location.etaLabel}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontSize: isMobile ? 12 : 13,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status Badge
                              _buildStatusBadge(stale),
                            ],
                          ),

                          // Expandable Content
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 14),

                                // Route Progress Track
                                RouteProgressTrack(
                                  totalStops: location.totalStops,
                                  currentStopIndex: location.currentStopIndex,
                                  currentStopLabel:
                                      'Next: ${location.currentStopLabel}',
                                  etaLabel: location.etaLabel,
                                ),

                                const SizedBox(height: 14),
                                if (!isMobile) ...[
                                  const SizedBox(height: 14),
                                  _buildTelemetry(context, location, isMobile),
                                ],
                                const SizedBox(height: 12),

                                // Student Info Row
                                if (studentName.trim().isNotEmpty)
                                  _buildStudentInfo(context, isMobile),
                              ],
                            ),
                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),

                          if (isMobile)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  color: AppColors.outline,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool stale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: stale
            ? AppColors.alertOrange.withValues(alpha: 0.12)
            : AppColors.successGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stale
              ? AppColors.alertOrange.withValues(alpha: 0.2)
              : AppColors.successGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: stale ? AppColors.alertOrange : AppColors.successGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            stale ? 'Stale' : 'Live',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: stale ? AppColors.alertOrange : AppColors.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 40 : 46,
            height: isMobile ? 40 : 46,
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
          SizedBox(width: isMobile ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 15,
                  ),
                ),
                Text(
                  studentGradeAndSeat,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isMobile ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetry(
    BuildContext context,
    BusLocation location,
    bool isMobile,
  ) {
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: isMobile ? 11 : 12,
    );
    return Row(
      children: [
        Expanded(
          child: _telemetryValue(
            context,
            Icons.speed_rounded,
            '${location.speedKmph.toStringAsFixed(1)} km/h',
            'Speed',
            textStyle,
          ),
        ),
        Expanded(
          child: _telemetryValue(
            context,
            Icons.gps_fixed_rounded,
            location.coordinateLabel,
            'GPS position',
            textStyle,
          ),
        ),
        Expanded(
          child: _telemetryValue(
            context,
            Icons.update_rounded,
            _updatedLabel(location.lastUpdated),
            'Last update',
            textStyle,
          ),
        ),
      ],
    );
  }

  Widget _telemetryValue(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    TextStyle? labelStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.safetyBlue),
        const SizedBox(height: 4),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: labelStyle),
      ],
    );
  }

  String _updatedLabel(DateTime value) {
    final seconds = DateTime.now().difference(value).inSeconds;
    if (seconds < 10) return 'Just now';
    if (seconds < 60) return '$seconds sec ago';
    return '${seconds ~/ 60} min ago';
  }
}
