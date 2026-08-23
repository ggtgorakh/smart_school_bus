import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background streets — softer, slightly varied widths for a less
    // mechanical grid feel.
    final minorRoad = Paint()
      ..color = const Color(0xFFDCE3EF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final majorRoad = Paint()
      ..color = const Color(0xFFCBD5E8)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.2),
        Offset(size.width * 0.9, size.height * 0.2), majorRoad);
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.08),
        Offset(size.width * 0.3, size.height * 0.92), minorRoad);
    canvas.drawLine(Offset(size.width * 0.7, size.height * 0.08),
        Offset(size.width * 0.7, size.height * 0.92), minorRoad);
    canvas.drawLine(Offset(size.width * 0.08, size.height * 0.7),
        Offset(size.width * 0.92, size.height * 0.7), minorRoad);

    // Completed route path.
    final completedPaint = Paint()
      ..color = AppColors.safetyBlue
      ..strokeWidth = 5.5
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

    // Remaining route path, dashed in amber.
    final remainingPaint = Paint()
      ..color = AppColors.alertOrange
      ..strokeWidth = 5.5
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

    double dashWidth = 9, dashSpace = 7, distance = 0.0;
    for (PathMetric pathMetric in remainingPath.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          remainingPaint,
        );
        distance += dashWidth + dashSpace;
      }
    }

    final stopPinPaintCompleted = Paint()..color = const Color(0xFFB9C4DC);
    final stopPinPaintNext = Paint()..color = AppColors.alertOrange;
    final whiteBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    Offset stop1 = Offset(size.width * 0.15, size.height * 0.85);
    canvas.drawCircle(stop1, 8, stopPinPaintCompleted);
    canvas.drawCircle(stop1, 8, whiteBorder);

    Offset stop2 = Offset(size.width * 0.35, size.height * 0.68);
    canvas.drawCircle(stop2, 8, stopPinPaintCompleted);
    canvas.drawCircle(stop2, 8, whiteBorder);

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

    _pulseAnimation = Tween<double>(begin: 0.8, end: 2.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7ECF6),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: RouteMapPainter()),
          ),
          // Animated pulse bus marker.
          Positioned(
            top: 180,
            left: 200,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.safetyBlue.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Opacity(
                            opacity: (2.3 - _pulseAnimation.value) / 1.5,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.safetyBlue.withValues(alpha: 0.45),
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
                        gradient: AppTheme.brandGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_bus_filled_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Floating ETA card with tabular time.
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: AppTheme.glassDecoration(borderRadius: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTIMATED ARRIVAL',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontSize: 10.5,
                                letterSpacing: 0.6,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.etaTime,
                          style: AppTheme.tabularTime(
                            fontSize: 25,
                            color: AppColors.alertOrangeDark,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.busNumber,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 13, color: AppColors.successGreen),
                              SizedBox(width: 4),
                              Text(
                                'On Schedule',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
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
