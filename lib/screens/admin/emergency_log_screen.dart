// lib/screens/admin/emergency_log_screen.dart
//
// Admin-only screen: every emergency event, newest first. Admins can
// acknowledge an active event or resolve it with a note. Reads/writes
// /emergencyEvents, which the RTDB rules permit for Admins.

import 'package:flutter/material.dart';

import '../../models/emergency_event.dart';
import '../../services/emergency_service.dart';
import '../../theme/app_theme.dart';

class EmergencyLogScreen extends StatefulWidget {
  const EmergencyLogScreen({super.key});

  @override
  State<EmergencyLogScreen> createState() => _EmergencyLogScreenState();
}

class _EmergencyLogScreenState extends State<EmergencyLogScreen> {
  String _filter = 'active'; // active | all | resolved

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text(
          'Emergency Log',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(context),
          Expanded(
            child: StreamBuilder<List<EmergencyEvent>>(
              stream: EmergencyService.instance.streamAllEvents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Unable to load emergencies: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.safetyBlue),
                  );
                }
                final all = snapshot.data!;
                final filtered = _applyFilter(all);
                if (filtered.isEmpty) {
                  return _emptyState(context, all.isEmpty);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _buildEventCard(context, filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    const options = <(String, String)>[
      ('active', 'Open'),
      ('resolved', 'Resolved'),
      ('all', 'All'),
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
      child: Row(
        children: [
          for (final (value, label) in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: _filter == value,
                onSelected: (_) => setState(() => _filter = value),
                selectedColor: AppColors.safetyBlue.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      _filter == value ? FontWeight.w700 : FontWeight.w500,
                  color: _filter == value
                      ? AppColors.safetyBlue
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                side: BorderSide(
                  color: _filter == value
                      ? AppColors.safetyBlue
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<EmergencyEvent> _applyFilter(List<EmergencyEvent> all) {
    switch (_filter) {
      case 'active':
        return all
            .where((e) =>
                e.status == EmergencyStatus.active ||
                e.status == EmergencyStatus.acknowledged)
            .toList();
      case 'resolved':
        return all
            .where((e) =>
                e.status == EmergencyStatus.resolved ||
                e.status == EmergencyStatus.cancelled)
            .toList();
      case 'all':
      default:
        return all;
    }
  }

  Widget _emptyState(BuildContext context, bool noneAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noneAtAll
                  ? Icons.verified_user_rounded
                  : Icons.filter_alt_off_rounded,
              size: 56,
              color: noneAtAll
                  ? AppColors.successGreen
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              noneAtAll ? 'All clear' : 'No emergencies match this filter',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              noneAtAll
                  ? 'No SOS events have been triggered in this deployment.'
                  : 'Try selecting a different filter.',
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

  Widget _buildEventCard(BuildContext context, EmergencyEvent e) {
    final meta = _statusMeta(e.status);
    final isOpen = e.status == EmergencyStatus.active ||
        e.status == EmergencyStatus.acknowledged;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen
              ? AppColors.errorRed.withValues(alpha: 0.4)
              : Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.4),
          width: isOpen ? 1.5 : 1,
        ),
        boxShadow: [
          if (isOpen)
            BoxShadow(
              color: AppColors.errorRed.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(meta.icon, color: meta.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.alertType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${e.actorRole} • ${_timeLabel(e.timestamp)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  meta.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: meta.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _kv(context, 'Bus', e.busId ?? '—'),
          if (e.tripId != null) _kv(context, 'Trip', e.tripId!),
          _kv(context, 'Location', e.coordinateLabel),
          if (e.description != null && e.description!.isNotEmpty)
            _kv(context, 'Note', e.description!),
          if (e.resolutionNote != null && e.resolutionNote!.isNotEmpty)
            _kv(context, 'Resolution', e.resolutionNote!),

          if (isOpen) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (e.status == EmergencyStatus.active)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _acknowledge(e),
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('Acknowledge'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.alertOrangeDark,
                        side: const BorderSide(
                          color: AppColors.alertOrangeDark,
                        ),
                      ),
                    ),
                  ),
                if (e.status == EmergencyStatus.active)
                  const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _resolve(e),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Resolve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledge(EmergencyEvent e) async {
    try {
      await EmergencyService.instance.acknowledge(eventId: e.eventId);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not acknowledge: $err')),
        );
      }
    }
  }

  Future<void> _resolve(EmergencyEvent e) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve emergency'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Resolution note',
            hintText: 'What action was taken?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await EmergencyService.instance.resolve(
        eventId: e.eventId,
        resolutionNote: controller.text,
      );
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not resolve: $err')),
        );
      }
    }
  }

  String _timeLabel(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  _StatusMeta _statusMeta(EmergencyStatus s) {
    switch (s) {
      case EmergencyStatus.active:
        return _StatusMeta(
          label: 'OPEN',
          color: AppColors.errorRed,
          icon: Icons.sos_rounded,
        );
      case EmergencyStatus.acknowledged:
        return _StatusMeta(
          label: 'ACK',
          color: AppColors.alertOrange,
          icon: Icons.visibility_rounded,
        );
      case EmergencyStatus.resolved:
        return _StatusMeta(
          label: 'RESOLVED',
          color: AppColors.successGreen,
          icon: Icons.check_circle_rounded,
        );
      case EmergencyStatus.cancelled:
        return _StatusMeta(
          label: 'CANCELLED',
          color: AppColors.outline,
          icon: Icons.cancel_rounded,
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