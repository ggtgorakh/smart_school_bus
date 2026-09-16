// lib/screens/parent_attendance_history_screen.dart
//
// Read-only attendance history for one child, as required by SRS §10.7.
// Parents are permitted to read /attendanceEvents/{busId}/{eventId}
// records for their own children (see RTDB rules). No write UI exists.

import 'package:flutter/material.dart';

import '../models/attendance_event.dart';
import '../models/student.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class ParentAttendanceHistoryScreen extends StatefulWidget {
  /// The child whose attendance is shown. Must have a non-null busId.
  final Student child;

  const ParentAttendanceHistoryScreen({
    super.key,
    required this.child,
  });

  @override
  State<ParentAttendanceHistoryScreen> createState() =>
      _ParentAttendanceHistoryScreenState();
}

class _ParentAttendanceHistoryScreenState
    extends State<ParentAttendanceHistoryScreen> {
  /// Filter: 'all' shows every event; otherwise filters by day offset
  /// (0 = today, 1 = yesterday, ...). Only the last 7 days are offered.
  String _range = 'all';

  @override
  Widget build(BuildContext context) {
    final busId = widget.child.busId;
    if (busId == null || busId.isEmpty) {
      return _scaffold(
        context,
        child: const _Empty(
          icon: Icons.directions_bus_outlined,
          title: 'No bus assigned',
          message:
              'Attendance history will appear once your child is assigned to a bus.',
        ),
      );
    }

    return _scaffold(
      context,
      child: StreamBuilder<List<AttendanceEvent>>(
        stream: FirebaseService.instance.streamAttendanceHistoryForParent(
          busId: busId,
          studentId: widget.child.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Empty(
              icon: Icons.wifi_off_rounded,
              title: "Can't load attendance",
              message: '${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.safetyBlue),
            );
          }

          final all = snapshot.data!;
          if (all.isEmpty) {
            return const _Empty(
              icon: Icons.history_rounded,
              title: 'No attendance events yet',
              message:
                  'Once your child boards the bus, their attendance will appear here.',
            );
          }

          final filtered = _applyRange(all);
          if (filtered.isEmpty) {
            return const _Empty(
              icon: Icons.filter_alt_off_rounded,
              title: 'No events in this range',
              message: 'Try selecting a wider time range.',
            );
          }

          final grouped = _groupByDay(filtered);
          final days = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // newest first

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: days.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSummaryHeader(context, all);
              }
              final day = days[index - 1];
              final events = grouped[day]!;
              return _buildDaySection(context, day, events);
            },
          );
        },
      ),
    );
  }

  Widget _scaffold(BuildContext context, {required Widget child}) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          '${widget.child.name} • Attendance',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          _buildRangeSelector(context),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ============================================================
  // RANGE FILTER
  // ============================================================

  Widget _buildRangeSelector(BuildContext context) {
    const options = <(String, String)>[
      ('all', 'All time'),
      ('0', 'Today'),
      ('1', 'Yesterday'),
      ('7', 'Last 7 days'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (value, label) in options)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: _range == value,
                  onSelected: (_) => setState(() => _range = value),
                  selectedColor:
                      AppColors.safetyBlue.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: _range == value
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _range == value
                        ? AppColors.safetyBlue
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  side: BorderSide(
                    color: _range == value
                        ? AppColors.safetyBlue
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY HEADER
  // ============================================================

  Widget _buildSummaryHeader(
    BuildContext context,
    List<AttendanceEvent> events,
  ) {
    // Compute a "boarded rate" over the last 30 days for a quick signal.
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = events.where((e) => e.timestamp.isAfter(cutoff)).toList();
    final boarded =
        recent.where((e) => e.status == AttendanceEventStatus.boarded).length;
    final flagged =
        recent.where((e) => e.status == AttendanceEventStatus.flagged).length;
    final total = recent.length;
    final onTimeRate = total == 0 ? 0 : (boarded / total * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.safetyBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Last 30 days',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  context,
                  label: 'Boardings',
                  value: '$boarded',
                ),
              ),
              Expanded(
                child: _summaryMetric(
                  context,
                  label: 'On-time rate',
                  value: '$onTimeRate%',
                ),
              ),
              Expanded(
                child: _summaryMetric(
                  context,
                  label: 'Flagged',
                  value: '$flagged',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
        ),
      ],
    );
  }

  // ============================================================
  // DAY SECTION
  // ============================================================

  Widget _buildDaySection(
    BuildContext context,
    DateTime day,
    List<AttendanceEvent> events,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Text(
                _dayLabel(day),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${events.length} event${events.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (final event in events) _buildEventCard(context, event),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, AttendanceEvent event) {
    final meta = _statusMeta(event.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(meta.icon, color: meta.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      meta.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: meta.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeLabel(event.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _sourceLabel(event.source),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (event.correctionReason != null &&
                    event.correctionReason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Note: ${event.correctionReason}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<AttendanceEvent> _applyRange(List<AttendanceEvent> events) {
    if (_range == 'all') return events;
    final days = int.tryParse(_range);
    if (days == null) return events;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final cutoff = startOfToday.subtract(Duration(days: days));
    final endOfRange = startOfToday.add(const Duration(days: 1));
    return events
        .where((e) =>
            e.timestamp.isAfter(cutoff) && e.timestamp.isBefore(endOfRange))
        .toList();
  }

  Map<DateTime, List<AttendanceEvent>> _groupByDay(
    List<AttendanceEvent> events,
  ) {
    final map = <DateTime, List<AttendanceEvent>>{};
    for (final e in events) {
      final day = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      map.putIfAbsent(day, () => []).add(e);
    }
    return map;
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    // Format as "Mon, 15 Apr"
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[day.weekday - 1]}, ${day.day} ${months[day.month - 1]}';
  }

  String _timeLabel(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'manual':
        return 'Recorded by conductor';
      case 'bulk-confirm':
        return 'Bulk confirmed';
      case 'scan':
        return 'Auto-recorded';
      default:
        return source;
    }
  }
  _StatusMeta _statusMeta(AttendanceEventStatus status) {
    switch (status) {
      case AttendanceEventStatus.boarded:
        return _StatusMeta(
          label: 'Boarded',
          color: AppColors.successGreen,
          icon: Icons.check_circle_rounded,
        );
      case AttendanceEventStatus.notBoarded:
        return _StatusMeta(
          label: 'Not boarded',
          color: AppColors.errorRed,
          icon: Icons.cancel_rounded,
        );
      case AttendanceEventStatus.flagged:
        return _StatusMeta(
          label: 'Flagged',
          color: AppColors.alertOrange,
          icon: Icons.flag_rounded,
        );
      case AttendanceEventStatus.pending:
        return _StatusMeta(
          label: 'Pending',
          color: AppColors.alertOrangeDark,
          icon: Icons.hourglass_top_rounded,
        );

      // ─── Unit 4A protocol states ─────────────────────────────
      // These four-plus-atStop states drive the parent-facing
      // coming → reached → picked → leaved lifecycle. Each gets its
      // own color and icon so the timeline reads at a glance.
      case AttendanceEventStatus.coming:
        return _StatusMeta(
          label: 'Bus coming',
          color: AppColors.safetyBlue,
          icon: Icons.directions_bus_rounded,
        );
      case AttendanceEventStatus.reached:
        return _StatusMeta(
          label: 'Bus arrived',
          color: AppColors.safetyBlue,
          icon: Icons.location_on_rounded,
        );
      case AttendanceEventStatus.picked:
        return _StatusMeta(
          label: 'Picked up',
          color: AppColors.successGreen,
          icon: Icons.directions_walk_rounded,
        );
      case AttendanceEventStatus.leaved:
        return _StatusMeta(
          label: 'Bus departed',
          color: AppColors.outline,
          icon: Icons.arrow_forward_rounded,
        );
      case AttendanceEventStatus.atStop:
        return _StatusMeta(
          label: 'At stop',
          color: AppColors.alertOrange,
          icon: Icons.person_pin_circle_rounded,
        );

    }
    }
  }
class _StatusMeta {
  final String label;
  final Color color;
  final IconData icon;
  _StatusMeta({
    required this.label,
    required this.color,
    required this.icon,
  });
}

// ============================================================
// EMPTY STATE
// ============================================================

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}