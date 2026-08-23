import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScannerReticle extends StatefulWidget {
  final bool isScanning;
  const ScannerReticle({super.key, this.isScanning = true});

  @override
  State<ScannerReticle> createState() => _ScannerReticleState();
}

class _ScannerReticleState extends State<ScannerReticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.safetyBlue.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Corner markers
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.safetyBlue, width: 4),
                  left: BorderSide(color: AppColors.safetyBlue, width: 4),
                ),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(14)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.safetyBlue, width: 4),
                  right: BorderSide(color: AppColors.safetyBlue, width: 4),
                ),
                borderRadius: BorderRadius.only(topRight: Radius.circular(14)),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.safetyBlue, width: 4),
                  left: BorderSide(color: AppColors.safetyBlue, width: 4),
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14)),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.safetyBlue, width: 4),
                  right: BorderSide(color: AppColors.safetyBlue, width: 4),
                ),
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(14)),
              ),
            ),
          ),
          // Animated Scanning Laser Line
          if (widget.isScanning)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 260 * _scanAnimation.value,
                  left: 12,
                  right: 12,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.alertOrange,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.alertOrange.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
