// lib/screens/admin/admin_broadcast_screen.dart
//
// Laptop-only. Admin sends a broadcast notification to a group of users:
// all parents of a specific bus, all drivers, all conductors, or everyone.

import 'package:flutter/material.dart';

import '../../models/bus_fleet.dart';
import '../../services/admin_alert_service.dart';
import '../../services/device_class_guard.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

enum _Target { allParentsOfBus, allDrivers, allConductors, everyone }

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  _Target _target = _Target.allParentsOfBus;
  String? _selectedBusId;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (!isLaptopActionAllowed()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required.')),
      );
      return;
    }
    if (_target == _Target.allParentsOfBus &&
        (_selectedBusId == null || _selectedBusId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a bus first.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      int delivered;
      switch (_target) {
        case _Target.allParentsOfBus:
          delivered = await AdminAlertService.instance.broadcastToBusParents(
            busId: _selectedBusId!,
            title: title,
            message: message,
          );
          break;
        case _Target.allDrivers:
          delivered = await AdminAlertService.instance.broadcastToRole(
            role: 'Driver',
            title: title,
            message: message,
          );
          break;
        case _Target.allConductors:
          delivered = await AdminAlertService.instance.broadcastToRole(
            role: 'Conductor',
            title: title,
            message: message,
          );
          break;
        case _Target.everyone:
          delivered = await AdminAlertService.instance.broadcastToEveryone(
            title: title,
            message: message,
          );
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Broadcast delivered to $delivered user(s).'),
        ),
      );
      _titleController.clear();
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Broadcast failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text(
          'Send Broadcast',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Send an in-app notification to a group of users. Recipients see '
            'it in their notification list on next app refresh.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Send to',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RadioGroup<_Target>(
            groupValue: _target,
            onChanged: (v) {
              if (v != null) setState(() => _target = v);
            },
            child: Column(
              children: [
                _targetRadio(
                  _Target.allParentsOfBus,
                  'All parents of a specific bus',
                  'Uses the current roster to reach each parent',
                ),
                _targetRadio(
                  _Target.allDrivers,
                  'All drivers',
                  'Every user with role Driver',
                ),
                _targetRadio(
                  _Target.allConductors,
                  'All conductors',
                  'Every user with role Conductor',
                ),
                _targetRadio(
                  _Target.everyone,
                  'Everyone',
                  'Parents, drivers, conductors, and admins',
                ),
              ],
            ),
          ),
          if (_target == _Target.allParentsOfBus) ...[
            const SizedBox(height: 12),
            StreamBuilder<List<BusFleet>>(
              stream: FirebaseService.instance.streamFleet(),
              builder: (context, snapshot) {
                final buses = snapshot.data ?? const <BusFleet>[];
                return DropdownButtonFormField<String>(
                  initialValue: _selectedBusId,
                  decoration: const InputDecoration(
                    labelText: 'Bus',
                    border: OutlineInputBorder(),
                  ),
                  items: buses
                      .map(
                        (b) => DropdownMenuItem(
                          value: b.busId,
                          child: Text(
                            '${b.busId.toUpperCase()} — ${b.routeName}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBusId = v),
                );
              },
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Route 7A delayed 15 minutes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Keep it short and specific.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.campaign_rounded),
              label: Text(
                _sending ? 'Sending…' : 'Send Broadcast',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safetyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetRadio(_Target value, String title, String subtitle) {
    final selected = _target == value;
    return RadioListTile<_Target>(
      value: value,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      contentPadding: EdgeInsets.zero,
    );
  }
}