// lib/screens/live_tracking_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/bus_location.dart';
import '../models/app_notification.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../widgets/live_map_canvas.dart';
import '../widgets/route_progress_track.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String busId;
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

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  late final Stream<BusLocation?> _locationStream;
  StreamSubscription<BusLocation?>? _statusSub;
  BusRunStatus? _lastNotifiedStatus;
  String? _lastNotifiedStop;
  int? _lastNotifiedEta;
  bool _isInitialNotificationSent = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isBottomSheetExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _locationStream = FirebaseService.instance.streamBusLocation(widget.busId);
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

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleLocationUpdate(BusLocation? location) async {
    setState(() {
      _isLoading = false;
      _hasError = false;
    });

    if (location == null) return;

    // Send initial notification when first valid location is received
    if (!_isInitialNotificationSent) {
      _isInitialNotificationSent = true;
      await NotificationService.instance.add(
        kind: NotificationKind.info,
        title: '${location.busNumber} tracking started',
        message: 'Live tracking is now active. Current location: ${location.currentStopLabel}',
        busId: widget.busId,
        metadata: {
          'stopLabel': location.currentStopLabel,
          'etaMinutes': location.etaMinutes,
          'isInitial': true,
        },
      );
    }

    // Check for status change
    final statusChanged = _lastNotifiedStatus != location.status;
    if (statusChanged && _lastNotifiedStatus != null) {
      await NotificationService.instance.notifyBusStatusChange(
        busId: widget.busId,
        busNumber: location.busNumber,
        oldStatus: _lastNotifiedStatus!.name,
        newStatus: location.status.name,
        stopLabel: location.currentStopLabel,
        etaMinutes: location.etaMinutes,
      );
    }
    _lastNotifiedStatus = location.status;

    // Check for stop change
    if (_lastNotifiedStop != location.currentStopLabel) {
      await NotificationService.instance.add(
        kind: NotificationKind.info,
        title: '${location.busNumber} approaching ${location.currentStopLabel}',
        message: 'ETA: ${location.etaLabel}',
        busId: widget.busId,
        metadata: {
          'stopLabel': location.currentStopLabel,
          'etaMinutes': location.etaMinutes,
          'stopIndex': location.currentStopIndex,
          'totalStops': location.totalStops,
          'busNumber': location.busNumber,
        },
      );
      _lastNotifiedStop = location.currentStopLabel;
    }

    _lastNotifiedEta = location.etaMinutes;
  }

  Future<void> _advanceSimulation(BusLocation current) async {
    final nextIndex = (current.currentStopIndex + 1) % current.totalStops;
    final stops = [
      'Depot Departure',
      'Pine & 5th Ave',
      'Oak St & Maple Ave',
      'Sycamore Lane',
      'Elm Street',
      'Oakridge Elementary',
    ];
    final nextLabel = stops[nextIndex % stops.length];
    final nextEta = (6 - nextIndex).clamp(1, 15);

    final updated = BusLocation(
      lat: current.lat + 0.001,
      lng: current.lng + 0.001,
      speedKmph: nextIndex == 0 ? 0 : 38.0,
      status: nextIndex == current.totalStops - 1
          ? BusRunStatus.arrived
          : BusRunStatus.onRoute,
      lastUpdated: DateTime.now(),
      currentStopIndex: nextIndex,
      totalStops: current.totalStops,
      currentStopLabel: nextLabel,
      etaMinutes: nextEta,
      busNumber: current.busNumber,
    );

    await FirebaseService.instance.updateBusLocation(widget.busId, updated);

    await NotificationService.instance.add(
      kind: NotificationKind.info,
      title: '🚌 Simulation: Advanced to $nextLabel',
      message: 'Next stop: ${nextIndex + 1}/${current.totalStops}',
      busId: widget.busId,
      metadata: {
        'isSimulation': true,
        'nextStop': nextLabel,
        'nextIndex': nextIndex,
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Simulated GPS: Advanced to $nextLabel')),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.safetyBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<BusLocation?>(
          stream: _locationStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
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
                onSimulateNextStop: () => _advanceSimulation(location),
                isExpanded: _isBottomSheetExpanded,
                onExpandToggle: () => setState(() => _isBottomSheetExpanded = !_isBottomSheetExpanded),
                pulseController: _pulseController,
              ),
            );
          },
        ),
      ),
    );
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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

  const _ErrorState({
    required this.errorMessage,
    required this.onRetry,
  });

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  final VoidCallback onSimulateNextStop;
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  final AnimationController pulseController;

  const _LiveTrackingContent({
    required this.location,
    required this.studentName,
    required this.studentGradeAndSeat,
    required this.onSimulateNextStop,
    required this.isExpanded,
    required this.onExpandToggle,
    required this.pulseController,
  });

  Future<void> _handleCallDriver(BuildContext context) async {
    final Uri telUri = Uri(scheme: 'tel', path: '+18005550199');
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Calling driver of ${location.busNumber}: +1 (800) 555-0199',
              ),
              backgroundColor: AppColors.safetyBlue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver Hotline: +1 (800) 555-0199'),
            backgroundColor: AppColors.safetyBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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
            topBanner: stale ? _StaleBanner(lastUpdated: location.lastUpdated) : null,
            trailingAction: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onSimulateNextStop,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.safetyBlue,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Next Stop',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.safetyBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom Sheet
        Positioned(
          left: isMobile ? 10 : 16,
          right: isMobile ? 10 : 16,
          bottom: isMobile ? 10 : 24,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 480,
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
                          // Drag Handle
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
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
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
                                const SizedBox(height: 16),

                                // Route Progress Track
                                RouteProgressTrack(
                                  totalStops: location.totalStops,
                                  currentStopIndex: location.currentStopIndex,
                                  currentStopLabel: 'Next: ${location.currentStopLabel}',
                                  etaLabel: location.etaLabel,
                                ),

                                const SizedBox(height: 14),
                                const Divider(color: AppColors.outlineVariant, height: 1),
                                const SizedBox(height: 14),

                                // Student Info Row
                                _buildStudentInfo(context, isMobile),
                              ],
                            ),
                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),

                          // Expand/Collapse Indicator
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

        // Animated Bus Marker Overlay
        Positioned(
          top: 40,
          left: 20,
          child: AnimatedBuilder(
            animation: pulseController,
            builder: (context, _) {
              final pulseScale = 1.0 + (pulseController.value * 0.1);
              return Transform.scale(
                scale: pulseScale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: stale ? AppColors.alertOrange : AppColors.successGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (stale ? AppColors.alertOrange : AppColors.successGreen)
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stale ? 'Signal Lost' : 'Live Tracking',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 15,
                      ),
                ),
                Text(
                  studentGradeAndSeat,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        fontSize: isMobile ? 11 : 12,
                      ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: AppColors.outlineVariant,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.call_rounded,
                color: AppColors.safetyBlue,
                size: 20,
              ),
              onPressed: () => _handleCallDriver(context),
              tooltip: 'Call Driver',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STALE BANNER
// ============================================================

class _StaleBanner extends StatelessWidget {
  final DateTime lastUpdated;

  const _StaleBanner({required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final minutesAgo = DateTime.now().difference(lastUpdated).inMinutes;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppTheme.dangerGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.errorRed.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'OFFLINE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}