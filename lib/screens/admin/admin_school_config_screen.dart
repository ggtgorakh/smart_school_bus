// lib/screens/admin/admin_school_config_screen.dart
//
// Laptop-only. Admin edits the school's name, address, contacts, and
// emergency numbers. Changes are pushed to /config/school and propagate
// live to every signed-in device.

import 'package:flutter/material.dart';

import '../../config/school_config.dart';
import '../../services/device_class_guard.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class AdminSchoolConfigScreen extends StatefulWidget {
  const AdminSchoolConfigScreen({super.key});

  @override
  State<AdminSchoolConfigScreen> createState() =>
      _AdminSchoolConfigScreenState();
}

class _AdminSchoolConfigScreenState extends State<AdminSchoolConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shortName;
  late TextEditingController _fullName;
  late TextEditingController _address;
  late TextEditingController _phone;
  late TextEditingController _email;
  late TextEditingController _coordName;
  late TextEditingController _coordPhone;
  late TextEditingController _emergency;
  late TextEditingController _medical;
  late TextEditingController _year;
  late TextEditingController _tagline;

  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _shortName = TextEditingController();
    _fullName = TextEditingController();
    _address = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _coordName = TextEditingController();
    _coordPhone = TextEditingController();
    _emergency = TextEditingController();
    _medical = TextEditingController();
    _year = TextEditingController();
    _tagline = TextEditingController();

    if (!isLaptopActionAllowed()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  void dispose() {
    _shortName.dispose();
    _fullName.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _coordName.dispose();
    _coordPhone.dispose();
    _emergency.dispose();
    _medical.dispose();
    _year.dispose();
    _tagline.dispose();
    super.dispose();
  }

  void _hydrateFrom(SchoolConfig c) {
    if (_initialized) return;
    _initialized = true;
    _shortName.text = c.shortName;
    _fullName.text = c.fullName;
    _address.text = c.address;
    _phone.text = c.phone;
    _email.text = c.email;
    _coordName.text = c.transportCoordinatorName;
    _coordPhone.text = c.transportCoordinatorPhone;
    _emergency.text = c.emergencyNumber;
    _medical.text = c.medicalEmergencyNumber;
    _year.text = c.academicYear;
    _tagline.text = c.appTagline;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final current = SchoolConfigController.instance.config;
      final updated = current.copyWith(
        shortName: _shortName.text.trim(),
        fullName: _fullName.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        transportCoordinatorName: _coordName.text.trim(),
        transportCoordinatorPhone: _coordPhone.text.trim(),
        emergencyNumber: _emergency.text.trim(),
        medicalEmergencyNumber: _medical.text.trim(),
        academicYear: _year.text.trim(),
        appTagline: _tagline.text.trim(),
      );
      await FirebaseService.instance.pushSchoolConfig(updated);
      SchoolConfigController.instance.hydrate(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School configuration saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SchoolConfig>(
      stream: FirebaseService.instance.streamSchoolConfig(),
      builder: (context, snapshot) {
        final config = snapshot.data ?? SchoolConfig.defaults;
        _hydrateFrom(config);
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            title: const Text(
              'School Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'These values appear throughout the app for every role. '
                  'Changes take effect immediately on all signed-in devices.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _section('Identity'),
                _field(_shortName, 'Short name', 'Used where space is tight'),
                _field(_fullName, 'Full name', 'Used in the app bar'),
                _field(_tagline, 'Tagline', 'Shown on the login screen'),
                _section('Contact'),
                _field(_address, 'Address', null, maxLines: 2),
                _field(_phone, 'Phone', null),
                _field(_email, 'Email', null),
                _field(_coordName, 'Transport coordinator name', null),
                _field(_coordPhone, 'Transport coordinator phone', null),
                _section('Emergencies'),
                _field(
                  _emergency,
                  'Emergency number',
                  'Used in the Profile → Emergency section',
                ),
                _field(
                  _medical,
                  'Medical emergency number',
                  'Used in the Profile → Emergency section',
                ),
                _section('Academic'),
                _field(_year, 'Academic year', 'e.g. 2025–2026'),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _saving ? 'Saving…' : 'Save Configuration',
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
          ),
        );
      },
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? '$label is required' : null,
      ),
    );
  }
}