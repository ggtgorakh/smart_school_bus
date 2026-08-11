import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background grid lines / map streets
    final bgPaint = Paint()
      ..color = const Color(0xFFD0D7E1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final roadPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height * 0.2)
      ..moveTo(size.width * 0.3, size.height * 0.1)
      ..lineTo(size.width * 0.3, size.height * 0.9)
      ..moveTo(size.width * 0.7, size.height * 0.1)
      ..lineTo(size.width * 0.7, size.height * 0.9)
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..lineTo(size.width * 0.9, size.height * 0.7);

    canvas.drawPath(roadPath, bgPaint);

    // Completed Route path (Solid Safety Blue)
    final completedPaint = Paint()
      ..color = AppColors.safetyBlue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final completedPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.85)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.75,
        size.width * 0.4,
        size.height * 0.6,
        size.width * 0.55,
        size.height * 0.45,
      );

    canvas.drawPath(completedPath, completedPaint);

    // Remaining Route path (Dashed Safety Orange)
    final remainingPaint = Paint()
      ..color = AppColors.alertOrange
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final remainingPath = Path()
      ..moveTo(size.width * 0.55, size.height * 0.45)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.35,
        size.width * 0.75,
        size.height * 0.25,
        size.width * 0.85,
        size.height * 0.2,
      );

    // Draw dashed effect for remaining path
    double dashWidth = 10, dashSpace = 8, distance = 0.0;
    for (PathMetric pathMetric in remainingPath.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          remainingPaint,
        );
        distance += dashWidth + dashSpace;
      }
    }

    // Draw Bus Stop Pins
    final stopPinPaintCompleted = Paint()..color = const Color(0xFFC3C6D2);
    final stopPinPaintNext = Paint()..color = AppColors.alertOrange;
    final whiteBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Stop 1 (Completed)
    Offset stop1 = Offset(size.width * 0.15, size.height * 0.85);
    canvas.drawCircle(stop1, 8, stopPinPaintCompleted);
    canvas.drawCircle(stop1, 8, whiteBorder);

    // Stop 2 (Completed)
    Offset stop2 = Offset(size.width * 0.35, size.height * 0.68);
    canvas.drawCircle(stop2, 8, stopPinPaintCompleted);
    canvas.drawCircle(stop2, 8, whiteBorder);

    // Stop 3 (Next Stop)
    Offset stop3 = Offset(size.width * 0.85, size.height * 0.2);
    canvas.drawCircle(stop3, 12, stopPinPaintNext);
    canvas.drawCircle(stop3, 12, whiteBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LiveMapCanvas extends StatefulWidget {
  final String busStatus;
  final String etaTime;
  final String busNumber;

  const LiveMapCanvas({
    super.key,
    this.busStatus = 'On Route',
    this.etaTime = '8:14 AM',
    this.busNumber = 'Bus 42',
  });

  @override
  State<LiveMapCanvas> createState() => _LiveMapCanvasState();
}

class _LiveMapCanvasState extends State<LiveMapCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation =
        Tween<double>(begin: 0.8, end: 2.2).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE0E6ED),
      child: Stack(
        children: [
          // Background custom map routes
          Positioned.fill(
            child: CustomPaint(
              painter: RouteMapPainter(),
            ),
          ),
          // Animated Pulse Bus Marker
          Positioned(
            top: 180,
            left: 200,
            child: Column(
              children: [
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.safetyBlue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.safetyBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.busStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Pulse bus circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Opacity(
                            opacity: (2.2 - _pulseAnimation.value) / 1.4,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.safetyBlue.withOpacity(0.5),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.safetyBlue, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: AppColors.safetyBlue,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Top Floating ETA Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: AppTheme.glassDecoration(borderRadius: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTIMATED ARRIVAL',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                        Text(
                          widget.etaTime,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppColors.alertOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.busNumber,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.successGreen,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'On Schedule',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
