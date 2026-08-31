import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RouteMapPainter extends CustomPainter {
  final bool isDark;
  const RouteMapPainter({this.isDark = false});
  @override
  void paint(Canvas canvas, Size size) {
    // -----------------------------
    // Background roads
    // -----------------------------

    final minorRoad = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFDCE3EF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final majorRoad = Paint()
      ..color = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E8)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Major horizontal road
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.9, size.height * 0.2),
      majorRoad,
    );

    // Vertical roads
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.08),
      Offset(size.width * 0.3, size.height * 0.92),
      minorRoad,
    );

    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.08),
      Offset(size.width * 0.7, size.height * 0.92),
      minorRoad,
    );

    // Bottom horizontal road
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.7),
      Offset(size.width * 0.92, size.height * 0.7),
      minorRoad,
    );

    // -----------------------------
    // Completed route
    // -----------------------------

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

    // -----------------------------
    // Remaining route
    // -----------------------------

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

    // Dashed route
    const double dashWidth = 9;
    const double dashSpace = 7;

    for (final metric in remainingPath.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);

        canvas.drawPath(metric.extractPath(distance, end), remainingPaint);

        distance += dashWidth + dashSpace;
      }
    }

    // -----------------------------
    // Stop markers
    // -----------------------------

    final completedStopPaint = Paint()..color = isDark ? const Color(0xFF64748B) : const Color(0xFFB9C4DC);

    final nextStopPaint = Paint()..color = AppColors.alertOrange;

    final whiteBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Stop 1
    final stop1 = Offset(size.width * 0.15, size.height * 0.85);

    canvas.drawCircle(stop1, 8, completedStopPaint);

    canvas.drawCircle(stop1, 8, whiteBorder);

    // Stop 2
    final stop2 = Offset(size.width * 0.35, size.height * 0.68);

    canvas.drawCircle(stop2, 8, completedStopPaint);

    canvas.drawCircle(stop2, 8, whiteBorder);

    // Next stop
    final stop3 = Offset(size.width * 0.85, size.height * 0.2);

    canvas.drawCircle(stop3, 12, nextStopPaint);

    canvas.drawCircle(stop3, 12, whiteBorder);
  }

  @override
  bool shouldRepaint(covariant RouteMapPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

// ============================================================
// LIVE MAP CANVAS
// ============================================================

class LiveMapCanvas extends StatefulWidget {
  final String busStatus;
  final String etaTime;
  final String busNumber;
  final double progress; // 0.0 to 1.0
  final double speedKmph;

  const LiveMapCanvas({
    super.key,
    this.busStatus = 'On Route',
    this.etaTime = '8:14 AM',
    this.busNumber = 'Bus 42',
    this.progress = 0.5,
    this.speedKmph = 35.0,
  });

  @override
  State<LiveMapCanvas> createState() => _LiveMapCanvasState();
}

class _LiveMapCanvasState extends State<LiveMapCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Calculate approximate bus marker position based on progress along the route
        final p = widget.progress.clamp(0.0, 1.0);
        final startX = width * 0.15;
        final startY = height * 0.85;
        final midX = width * 0.55;
        final midY = height * 0.45;
        final endX = width * 0.85;
        final endY = height * 0.20;
        final topMin = 70.0;
        final topMax = (height - 220.0) < topMin ? topMin : (height - 220.0);
        final leftMin = 10.0;
        final leftMax = (width - 110.0) < leftMin ? leftMin : (width - 110.0);

        double busX;
        double busY;
        if (p < 0.5) {
          final t = p / 0.5;
          busX = startX + (midX - startX) * t;
          busY = startY + (midY - startY) * t;
        } else {
          final t = (p - 0.5) / 0.5;
          busX = midX + (endX - midX) * t;
          busY = midY + (endY - midY) * t;
        }

        return Container(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F1928) : const Color(0xFFE7ECF6),
          child: Stack(
            children: [
              // MAP BACKGROUND
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: RouteMapPainter(isDark: Theme.of(context).brightness == Brightness.dark)),
                ),
              ),

              // ETA CARD
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: AppTheme.panelDecoration(context, borderRadius: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ETA
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESTIMATED ARRIVAL',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontSize: 10.5,
                                    letterSpacing: 0.6,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.etaTime,
                              style: AppTheme.tabularTime(
                                fontSize: 24,
                                color: AppColors.alertOrangeDark,
                              ),
                            ),
                          ],
                        ),

                        // Bus information
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${widget.busNumber} • ${widget.speedKmph.toStringAsFixed(0)} km/h',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                    widget.busStatus,
                                    style: const TextStyle(
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

              // DYNAMIC BUS MARKER
              Positioned(
                left: (busX - 50).clamp(leftMin, leftMax),
                top: (busY - 70).clamp(topMin, topMax),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final pulseScale = 1.0 + (_pulseController.value * 0.15);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.brandGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.safetyBlue.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.busStatus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Pulsing Bus Icon
                        Transform.scale(
                          scale: pulseScale,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.safetyBlue.withOpacity(0.20),
                            ),
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.brandGradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_bus_filled_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
