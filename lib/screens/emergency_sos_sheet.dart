// lib/screens/emergency_sos_sheet.dart
//
// Hold-to-confirm SOS bottom sheet. Deliberately requires a 2-second
// press so a Driver cannot fire an emergency by pocket-tapping.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/emergency_service.dart';
import '../theme/app_theme.dart';

class EmergencySosSheet extends StatefulWidget {
  /// Bus ID the sender is currently operating on (may be null for Admins).
  final String? busId;

  /// Active trip ID, if a trip is in progress.
  final String? tripId;

  /// 'Driver' or 'Conductor'.
  final String actorRole;

  const EmergencySosSheet({
    super.key,
    this.busId,
    this.tripId,
    required this.actorRole,
  });

  /// Convenience launcher.
  static Future<void> show(
    BuildContext context, {
    String? busId,
    String? tripId,
    required String actorRole,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => EmergencySosSheet(
        busId: busId,
        tripId: tripId,
        actorRole: actorRole,
      ),
    );
  }

  @override
  State<EmergencySosSheet> createState() => _EmergencySosSheetState();
}

class _EmergencySosSheetState extends State<EmergencySosSheet> {
  static const Duration _holdDuration = Duration(milliseconds: 2000);

  Timer? _timer;
  double _progress = 0.0;
  bool _isSending = false;
  bool _sent = false;
  EmergencySosResult? _result;
  String? _error;

  String _selectedAlert = 'General emergency';
  final _noteController = TextEditingController();

  static const _alertOptions = <String>[
    'General emergency',
    'Accident',
    'Medical emergency',
    'Breakdown',
    'Unsafe situation',
    'Student missing',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_isSending || _sent) return;
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    const interval = Duration(milliseconds: 40);
    final steps = _holdDuration.inMilliseconds / interval.inMilliseconds;
    _timer = Timer.periodic(interval, (t) {
      setState(() => _progress += 1 / steps);
      if (_progress >= 1.0) {
        t.cancel();
        _trigger();
      }
    });
  }

  void _cancelHold() {
    if (_isSending || _sent) return;
    _timer?.cancel();
    _timer = null;
    setState(() => _progress = 0.0);
  }

  Future<void> _trigger() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    HapticFeedback.heavyImpact();
    try {
      final result = await EmergencyService.instance.triggerSOS(
        actorRole: widget.actorRole,
        alertType: _selectedAlert,
        description: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        busId: widget.busId,
        tripId: widget.tripId,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sent = true;
        _result = result;
      });
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _progress = 0.0;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: mediaInsets),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.errorRed.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_sent)
                  _buildSuccess(context)
                else
                  _buildConfirm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sos_rounded,
                color: AppColors.errorRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency SOS',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.errorRed,
                        ),
                  ),
                  Text(
                    'This notifies dispatch and every Admin on duty.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Alert type
        DropdownButtonFormField<String>(
          initialValue: _selectedAlert,
          decoration: const InputDecoration(
            labelText: 'Type of emergency',
            border: OutlineInputBorder(),
          ),
          items: _alertOptions
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: _isSending
              ? null
              : (v) => setState(() => _selectedAlert = v ?? _selectedAlert),
        ),
        const SizedBox(height: 12),

        // Optional note
        TextField(
          controller: _noteController,
          enabled: !_isSending,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'Briefly describe what is happening',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Could not send SOS: $_error',
              style: const TextStyle(
                color: AppColors.errorRed,
                fontSize: 12.5,
              ),
            ),
          ),

        // Hold-to-confirm button
        _buildHoldButton(context),

        const SizedBox(height: 8),
        Center(
          child: Text(
            'Press and hold for 2 seconds to send',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildHoldButton(BuildContext context) {
    final isReady = _progress >= 1.0 || _isSending;
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: _progress > 0
              ? AppColors.dangerGradient
              : const LinearGradient(
                  colors: [Color(0xFF991B1B), Color(0xFF7F1D1D)],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.errorRed.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Progress fill
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSending)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      isReady
                          ? Icons.check_circle_rounded
                          : Icons.touch_app_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    _isSending
                        ? 'Sending…'
                        : isReady
                            ? 'Release to confirm'
                            : 'HOLD TO SEND',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final result = _result;
    final noAdminReached = result != null && !result.anyAdminReached;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.dangerGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SOS sent',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.errorRed,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          noAdminReached
              ? 'Your SOS has been recorded with your current location. '
                  'No Admin was reachable in-app — call dispatch directly.'
              : 'Dispatch and every Admin on duty have been notified with '
                  'your current location. Stay calm and stay on the line.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        if (noAdminReached) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.alertOrange.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.alertOrangeDark,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No Admin received this alert in the app. '
                    'If this is a real emergency, use your phone to call '
                    'the school transport desk or emergency services '
                    'directly.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Close'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.errorRed,
            side: const BorderSide(color: AppColors.errorRed),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}