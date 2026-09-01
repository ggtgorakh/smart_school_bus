// lib/widgets/kpi_card.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final double? progress;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final String? subtitle;
  final bool showTrend;
  final double? trendValue;
  final bool isTrendUp;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.badgeText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    this.progress,
    this.gradient,
    this.onTap,
    this.subtitle,
    this.showTrend = false,
    this.trendValue,
    this.isTrendUp = true,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = context.isMobile;

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 14 : 16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isHovered
                          ? scheme.primary.withValues(alpha: 0.3)
                          : scheme.outlineVariant.withValues(alpha: 0.3),
                      width: _isHovered ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isHovered
                            ? scheme.primary.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                        blurRadius: _isHovered ? 20 : 12,
                        offset: Offset(0, _isHovered ? 6 : 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Icon + Badge
                      _buildTopRow(scheme),
                      const SizedBox(height: 10),
                      
                      // Value Row
                      _buildValueRow(scheme),
                      const SizedBox(height: 2),
                      
                      // Title Row
                      _buildTitleRow(scheme),
                      
                      // Progress Bar
                      if (widget.progress != null) ...[
                        const SizedBox(height: 10),
                        _buildProgressBar(scheme),
                      ],
                      
                      // Subtitle
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TOP ROW
  // ============================================================

  Widget _buildTopRow(ColorScheme scheme) {
    return Row(
      children: [
        // Icon Container with Animation
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: widget.gradient ??
                LinearGradient(
                  colors: [
                    widget.iconBgColor,
                    widget.iconBgColor.withValues(alpha: 0.6),
                  ],
                ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const Spacer(),
        
        // Badge
        _buildBadge(),
      ],
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.badgeBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.badgeTextColor.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        widget.badgeText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: widget.badgeTextColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // VALUE ROW
  // ============================================================

  Widget _buildValueRow(ColorScheme scheme) {
    return Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.isMobile ? 22 : 26,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        if (widget.showTrend && widget.trendValue != null) ...[
          const SizedBox(width: 8),
          _buildTrendIndicator(),
        ],
      ],
    );
  }

  // ============================================================
  // TREND INDICATOR
  // ============================================================

  Widget _buildTrendIndicator() {
    final isUp = widget.isTrendUp;
    final color = isUp ? AppColors.successGreen : AppColors.errorRed;
    final icon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 2),
          Text(
            '${widget.trendValue!.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TITLE ROW
  // ============================================================

  Widget _buildTitleRow(ColorScheme scheme) {
    return Text(
      widget.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  // ============================================================
  // PROGRESS BAR
  // ============================================================

  Widget _buildProgressBar(ColorScheme scheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: widget.progress,
        minHeight: 6,
        backgroundColor: scheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.gradient?.colors.first ?? AppColors.safetyBlue,
        ),
      ),
    );
  }
}