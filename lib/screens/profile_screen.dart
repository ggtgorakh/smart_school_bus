import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final String activeRole;
  final VoidCallback onSignOut;

  const ProfileScreen({
    super.key,
    required this.activeRole,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    String profileName;
    String profileEmail;
    List<Widget> statsWidgets;
    List<String> authorizedScope;

    if (activeRole == 'Driver') {
      profileName = 'Mike Torres';
      profileEmail = 'driver@schoolsafe.org';
      statsWidgets = const [
        _ProfileStat(label: 'Assigned Vehicle', value: 'BUS-115'),
        _ProfileStat(label: 'Active Route', value: 'Route 3C'),
        _ProfileStat(label: 'Max Capacity', value: '48 Seats'),
      ];
      authorizedScope = [
        'Student Attendance Scanner',
        'Live Bus Navigation',
        'Driver Profile',
      ];
    } else if (activeRole == 'Admin') {
      profileName = 'Sarah Jenkins';
      profileEmail = 'admin@schoolsafe.org';
      statsWidgets = const [
        _ProfileStat(label: 'Active Fleet', value: '42 Buses'),
        _ProfileStat(label: 'Active Drivers', value: '38 Active'),
        _ProfileStat(label: 'On-Time Rate', value: '96.4%'),
      ];
      authorizedScope = [
        'Fleet Overview & Telemetry',
        'Route Planning & Stop Builder',
        'Master GPS Map',
        'Student Boarding Manifest',
        'Admin Settings & Dispatch',
      ];
    } else {
      // Parent Role
      profileName = 'Sarah Johnson';
      profileEmail = 'parent@schoolsafe.org';
      statsWidgets = const [
        _ProfileStat(label: 'Registered Children', value: '2 Students'),
        _ProfileStat(label: 'Assigned Bus', value: 'BUS-402'),
        _ProfileStat(label: 'Morning Stop', value: 'Oakridge'),
      ];
      authorizedScope = [
        'Live Child Bus Tracking',
        'Parent Profile & Alerts',
      ];
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Profile Avatar & Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceContainerHighest),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryContainer,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profileName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                      ),
                      Text(
                        profileEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.safetyBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Authenticated Role: $activeRole',
                          style: const TextStyle(
                            color: AppColors.safetyBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.surfaceContainerHighest),
                      const SizedBox(height: 12),

                      // Quick info metrics
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: statsWidgets,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Role Permissions Card (No unauthenticated role switcher)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceContainerHighest),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_outlined,
                              color: AppColors.safetyBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Role Authorized Views',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your views are restricted based on your login session. To switch roles, sign out and select a different account on the login screen.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.surfaceContainerHighest),
                      const SizedBox(height: 8),
                      ...authorizedScope.map(
                        (scope) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: AppColors.successGreen, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                scope,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency & Help Contacts
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceContainerHighest),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Contacts & Support',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.phone_in_talk,
                            color: AppColors.alertOrange),
                        title: const Text('School Dispatch Hotline'),
                        subtitle: const Text('+1 (800) 555-0199'),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.shield_outlined,
                            color: AppColors.safetyBlue),
                        title: const Text('Safety Policy & Terms'),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onSignOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.safetyBlue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

