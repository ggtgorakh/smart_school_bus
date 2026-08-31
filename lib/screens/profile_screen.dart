import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'admin/create_user_screen.dart';

/// Read model for the current user's own /users/{uid} record.
class _ProfileData {
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? busId;

  _ProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.busId,
  });

  factory _ProfileData.fromMap(Map<dynamic, dynamic> map, {required String fallbackEmail}) {
    return _ProfileData(
      name: (map['name']?.toString().trim().isNotEmpty ?? false)
          ? map['name'].toString()
          : 'Unnamed user',
      email: (map['email']?.toString().trim().isNotEmpty ?? false)
          ? map['email'].toString()
          : fallbackEmail,
      phone: map['phone']?.toString(),
      role: map['role']?.toString() ?? 'Parent',
      busId: map['busId']?.toString(),
    );
  }
}

/// Profile screen for the signed-in user.
///
/// BUG FIX: previously this screen never read real data at all — it just
/// hardcoded a name/email per ROLE, so every Parent (or every Driver, etc.)
/// saw the exact same identity regardless of who was actually logged in.
/// It now reads /users/{current uid} live, and lets the user edit their own
/// `name` — but not `email` or `phone`, which are locked server-side (see
/// database.rules.json) and shown here as read-only.
class ProfileScreen extends StatefulWidget {
  final String activeRole;
  final VoidCallback onSignOut;

  const ProfileScreen({
    super.key,
    required this.activeRole,
    required this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  void _openEditNameSheet(String currentName, String uid) {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Edit Profile',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can update your name. Email and phone number are '
                        'managed by your administrator.',
                        style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Full Name',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: controller,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              color: AppColors.outline, size: 20),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.safetyBlue, width: 2),
                          ),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => isSaving = true);
                                  try {
                                    await AuthService.instance
                                        .updateOwnName(uid, controller.text.trim());
                                    if (context.mounted) Navigator.of(context).pop();
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Could not save: $e'),
                                          backgroundColor: AppColors.errorRed,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.safetyBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save Changes',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<String> _authorizedScope(String role) {
    switch (role) {
      case 'Driver':
        return const ['Bus Route Navigation', 'Driver Profile'];
      case 'Conductor':
        return const [
          'Student Check-in/Check-out',
          'Bus Route Map',
          'Conductor Profile',
        ];
      case 'Admin':
        return const [
          'Fleet Overview & Telemetry',
          'Route Planning & Stop Builder',
          'Master GPS Map',
          'Student Boarding Manifest',
          'Admin Settings & Dispatch',
        ];
      default:
        return const ['Live Child Bus Tracking', 'Parent Profile & Alerts'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text('Please sign in to view your profile.')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<DatabaseEvent>(
        stream: _root.child('users/${user.uid}').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Can't load your profile.\nFirebase error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.safetyBlue),
            );
          }

          final raw = snapshot.data!.snapshot.value;
          final profile = (raw is Map)
              ? _ProfileData.fromMap(raw, fallbackEmail: user.email ?? '—')
              : _ProfileData(
                  name: 'Unnamed user',
                  email: user.email ?? '—',
                  phone: null,
                  role: widget.activeRole,
                  busId: null,
                );

          final authorizedScope = _authorizedScope(profile.role);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // Profile avatar & info card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.brandGradient,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.safetyBlue.withValues(alpha: 0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 46,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  profile.name,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        letterSpacing: -0.3,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _openEditNameSheet(profile.name, user.uid),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit_rounded,
                                      size: 18, color: AppColors.safetyBlue),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            profile.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (profile.phone != null && profile.phone!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                profile.phone!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.safetyBlue.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Signed in as ${profile.role}',
                              style: const TextStyle(
                                color: AppColors.safetyBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Divider(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                          const SizedBox(height: 14),
                          _StatsRow(role: profile.role, busId: profile.busId, uid: user.uid),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Role permissions card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.safetyBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.shield_rounded,
                                    color: AppColors.safetyBlue, size: 17),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'What you can access',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your view is tied to this login session. Sign out to switch roles.',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 14),
                          ...authorizedScope.map(
                            (scope) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.mintSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        color: AppColors.successGreen, size: 13),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      scope,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (profile.role == 'Admin') ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.safetyBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.admin_panel_settings_rounded,
                                      color: AppColors.safetyBlue, size: 17),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Admin Management',
                                    style:
                                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Material(
                              color: Colors.transparent,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.safetyBlue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person_add_rounded,
                                      color: AppColors.safetyBlue, size: 18),
                                ),
                                title: const Text(
                                  'Provision New User',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                                subtitle: Text(
                                  'Create Driver, Conductor, Parent, or Admin credentials',
                                  style:
                                      TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.outline),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AdminCreateUserScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Emergency & help contacts
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency contacts & support',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          _ContactTile(
                            icon: Icons.phone_in_talk_rounded,
                            iconBg: AppColors.amberSoft,
                            iconColor: AppColors.alertOrangeDark,
                            title: 'School Dispatch Hotline',
                            subtitle: '+1 (800) 555-0199 • Tap to call',
                            onTap: () async {
                              final Uri telUri = Uri(scheme: 'tel', path: '+18005550199');
                              try {
                                if (await canLaunchUrl(telUri)) {
                                  await launchUrl(telUri);
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Hotline: +1 (800) 555-0199'),
                                        backgroundColor: AppColors.safetyBlue,
                                      ),
                                    );
                                  }
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Hotline: +1 (800) 555-0199'),
                                      backgroundColor: AppColors.safetyBlue,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          _ContactTile(
                            icon: Icons.shield_outlined,
                            iconBg: AppColors.safetyBlue.withValues(alpha: 0.1),
                            iconColor: AppColors.safetyBlue,
                            title: 'Safety Policy & Terms',
                            subtitle: 'Tap to review standards & protocols',
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  // OVERFLOW FIX: the icon + text Row had no
                                  // Expanded/Flexible around the Text, so on
                                  // a narrow phone screen there was nowhere
                                  // for the text to go once the icon and
                                  // spacing took their width — Flutter
                                  // reported "RIGHT OVERFLOWED BY 36
                                  // PIXELS". Wrapping the Text in Expanded
                                  // lets it wrap onto a second line instead.
                                  title: Row(
                                    children: [
                                      const Icon(Icons.security_rounded,
                                          color: AppColors.safetyBlue),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Safety & Transport Standards',
                                          style: TextStyle(fontSize: 17),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: const SingleChildScrollView(
                                    child: Text(
                                      '• Real-time GPS tracking is encrypted end-to-end.\n'
                                      '• Conductor check-in is mandatory at every authorized stop.\n'
                                      '• Emergency SOS hotline is staffed 24/7 by School District Dispatch.\n'
                                      '• Speed governor alerts are triggered automatically when limit exceeds 45 mph.',
                                      style: TextStyle(fontSize: 13, height: 1.4),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: widget.onSignOut,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed,
                          side: const BorderSide(color: AppColors.errorRed, width: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Renders the 3-stat row, pulling live counts where the data already
/// exists (Conductor roster size, Parent registered-children count)
/// instead of hardcoded numbers.
class _StatsRow extends StatelessWidget {
  final String role;
  final String? busId;
  final String uid;

  const _StatsRow({required this.role, required this.busId, required this.uid});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'Driver':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ProfileStat(label: 'Assigned Bus', value: busId ?? 'Unassigned'),
            const _ProfileStat(label: 'Active Route', value: 'Route 3C'),
            const _ProfileStat(label: 'Max Capacity', value: '48 Seats'),
          ],
        );

      case 'Conductor':
        return StreamBuilder(
          stream: busId != null
              ? FirebaseService.instance.streamStudents(busId!)
              : const Stream.empty(),
          builder: (context, snapshot) {
            final rosterSize = snapshot.data?.length;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ProfileStat(label: 'Assigned Bus', value: busId ?? 'Unassigned'),
                const _ProfileStat(label: 'Active Route', value: 'Route 3C'),
                _ProfileStat(
                  label: 'Roster Size',
                  value: rosterSize != null ? '$rosterSize Students' : '—',
                ),
              ],
            );
          },
        );

      case 'Admin':
        // Fleet-wide aggregation isn't wired up yet (Fleet Overview is
        // still mock data too) — left as illustrative placeholders rather
        // than fabricating precision the backend doesn't calculate.
        return const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ProfileStat(label: 'Active Fleet', value: '42 Buses'),
            _ProfileStat(label: 'Active Drivers', value: '38 Active'),
            _ProfileStat(label: 'On-Time Rate', value: '96.4%'),
          ],
        );

      default: // Parent
        return StreamBuilder(
          stream: FirebaseService.instance.streamChildrenForParent(uid),
          builder: (context, snapshot) {
            final children = snapshot.data;
            final count = children?.length ?? 0;
            final singleChild = (children != null && children.length == 1)
                ? children.first
                : null;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ProfileStat(
                  label: count == 1 ? 'Registered Child' : 'Registered Children',
                  value: '$count',
                ),
                _ProfileStat(
                  label: 'Grade',
                  value: singleChild?.grade ?? (count > 1 ? 'Multiple' : '—'),
                ),
                _ProfileStat(
                  label: 'Morning Stop',
                  value: singleChild?.stopName ?? (count > 1 ? 'Multiple' : '—'),
                ),
              ],
            );
          },
        );
    }
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _ContactTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.outline, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.safetyBlue,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}