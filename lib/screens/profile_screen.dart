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
        'Bus Route Navigation',
        'Driver Profile',
      ];
    } else if (activeRole == 'Conductor') {
      profileName = 'Priya Nair';
      profileEmail = 'conductor@schoolsafe.org';
      statsWidgets = const [
        _ProfileStat(label: 'Assigned Vehicle', value: 'BUS-115'),
        _ProfileStat(label: 'Active Route', value: 'Route 3C'),
        _ProfileStat(label: 'Roster Size', value: '5 Students'),
      ];
      authorizedScope = [
        'Student Check-in/Check-out',
        'Bus Route Map',
        'Conductor Profile',
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
      backgroundColor: AppColors.surfaceGray,
      body: SingleChildScrollView(
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.08),
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
                      Text(
                        profileName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                              letterSpacing: -0.3,
                            ),
                      ),
                      Text(
                        profileEmail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.safetyBlue.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Signed in as $activeRole',
                          style: const TextStyle(
                            color: AppColors.safetyBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: AppColors.surfaceContainerHighest),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: statsWidgets,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Role permissions card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.05),
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
                          Text(
                            'What you can access',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your view is tied to this login session. Sign out to switch roles.',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
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
                                decoration: const BoxDecoration(
                                  color: AppColors.mintSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: AppColors.successGreen, size: 13),
                              ),
                              const SizedBox(width: 10),
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
                const SizedBox(height: 14),

                // Emergency & help contacts
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.05),
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
                        subtitle: '+1 (800) 555-0199',
                      ),
                      _ContactTile(
                        icon: Icons.shield_outlined,
                        iconBg: AppColors.safetyBlue.withValues(alpha: 0.1),
                        iconColor: AppColors.safetyBlue,
                        title: 'Safety Policy & Terms',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: onSignOut,
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
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;

  const _ContactTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
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
