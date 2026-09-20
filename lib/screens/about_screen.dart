// lib/screens/about_screen.dart
//
// About screen. Purpose, school, tech stack, version, and a link to
// the developers screen.
//
// Layout:
//   - Wide (>= 800 px): two columns. Left carries identity, purpose,
//     version, and the team button. Right carries school details and
//     the tech stack.
//   - Narrow (< 800 px): single stacked column.
//
// School details are read live from SchoolConfigController, so if the
// school's name, address, or contacts change in the Admin panel, this
// screen updates automatically.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/school_config.dart';
import '../theme/app_theme.dart';
import 'developers_screen.dart';

/// Below this width the layout stacks into a single column.
const double _wideBreakpoint = 800;

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = SchoolConfigController.instance.config;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text(
          'About this app',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isWide = width >= _wideBreakpoint;
          // On very wide monitors, cap the content so lines do not run
          // edge to edge. On typical laptops, use the full width.
          final maxContentWidth = width >= 1600 ? 1500.0 : double.infinity;

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 32 : 16,
                    24,
                    isWide ? 32 : 16,
                    40,
                  ),
                  child: isWide
                      ? _wideLayout(context, config)
                      : _narrowLayout(context, config),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // WIDE LAYOUT (two columns)
  // ============================================================

  Widget _wideLayout(BuildContext context, SchoolConfig config) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIdentity(context),
              const SizedBox(height: 20),
              _buildPurposeCard(context),
              const SizedBox(height: 16),
              _buildVersionCard(context),
              const SizedBox(height: 20),
              _buildTeamButton(context),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSchoolCard(context, config),
              const SizedBox(height: 16),
              _buildTechStackCard(context),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NARROW LAYOUT (single column)
  // ============================================================

  Widget _narrowLayout(BuildContext context, SchoolConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIdentity(context),
        const SizedBox(height: 20),
        _buildPurposeCard(context),
        const SizedBox(height: 16),
        _buildSchoolCard(context, config),
        const SizedBox(height: 16),
        _buildTechStackCard(context),
        const SizedBox(height: 16),
        _buildVersionCard(context),
        const SizedBox(height: 20),
        _buildTeamButton(context),
      ],
    );
  }

  // ============================================================
  // IDENTITY
  // ============================================================

  Widget _buildIdentity(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.safetyBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.safetyBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.safetyBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_bus_filled_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Smart School Bus',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tracking and Student Safety System',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PURPOSE
  // ============================================================

  Widget _buildPurposeCard(BuildContext context) {
    return _Section(
      icon: Icons.info_outline_rounded,
      title: 'About this project',
      child: Text(
        'This application helps schools keep track of their buses and '
        'their students in real time. Parents can see where their child\'s '
        'bus is and when the child has boarded. Conductors record '
        'attendance at the point of boarding. Drivers start and end trips '
        'from their own phones, and the phone\'s location becomes the '
        'bus\'s location. In an emergency, a Driver or Conductor can send '
        'an SOS that reaches every Admin instantly.\n\n'
        'Built with Flutter and Firebase, the system runs entirely on the '
        'driver\'s own phone — no dedicated GPS hardware, no scanners, no '
        'additional infrastructure for the school to buy or maintain.',
        style: TextStyle(
          fontSize: 13.5,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // ============================================================
  // SCHOOL
  // ============================================================

  Widget _buildSchoolCard(BuildContext context, SchoolConfig config) {
    return _Section(
      icon: Icons.school_rounded,
      title: 'Built for',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.fullName,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: config.address,
          ),
          _InfoLine(icon: Icons.phone_outlined, text: config.phone),
          _InfoLine(icon: Icons.email_outlined, text: config.email),
          const SizedBox(height: 10),
          const _WebsiteButton(),
        ],
      ),
    );
  }

  // ============================================================
  // TECH STACK
  // ============================================================

  Widget _buildTechStackCard(BuildContext context) {
    const tech = <String>[
      'Flutter',
      'Dart',
      'Firebase Auth',
      'Realtime Database',
      'Geolocator',
      'flutter_map',
      'OpenStreetMap',
      'SharedPreferences',
    ];
    return _Section(
      icon: Icons.construction_rounded,
      title: 'Technology',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tech.map((t) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.safetyBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.safetyBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              t,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.safetyBlue,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // VERSION
  // ============================================================

  Widget _buildVersionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Version 1.1',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Final year project build · September 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  // TEAM BUTTON
  // ============================================================

  Widget _buildTeamButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DevelopersScreen()),
        ),
        icon: const Icon(Icons.groups_rounded, size: 20),
        label: const Text(
          'Meet the team',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safetyBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SHARED PIECES
// ============================================================

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.safetyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.safetyBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteButton extends StatelessWidget {
  const _WebsiteButton();

  static const _url = 'https://edifyschoolamravati.com/';
  static const _label = 'edifyschoolamravati.com';

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(_url);
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the website")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.safetyBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.safetyBlue.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: const [
              Icon(
                Icons.language_rounded,
                size: 18,
                color: AppColors.safetyBlue,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  _label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.safetyBlue,
                  ),
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 15,
                color: AppColors.safetyBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}