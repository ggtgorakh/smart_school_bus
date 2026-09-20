// lib/screens/developers_screen.dart
//
// Team screen. Opened from the "Meet the team" button on AboutScreen
// and from the Profile screen's "Meet the team" tile.
//
// Layout:
//   - Wide screens (>= 800 px): project panel on the left, member
//     cards on the right. The lead card spans the full width of the
//     right column, and the rest form a 2- or 3-column grid.
//   - Phones (< 800 px): compact project banner on top, member cards
//     stacked full width.
//
// Replace the placeholder values in _members with the real details.
// Photos are optional. If photoAsset is null or missing, initials show.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

const double _wideBreakpoint = 800;

// ============================================================
// PROJECT INFO
// ============================================================

const _projectName = 'Smart School Bus';
const _projectTagline = 'Tracking and Student Safety System';
const _problemSource = 'Edify School Amravati';
const _schoolName = 'Edify School Amravati';
const _schoolWebsite = 'https://edifyschoolamravati.com/';
const _schoolWebsiteLabel = 'edifyschoolamravati.com';
const _schoolLogoUrl =
    'https://edifyschoolamravati.com/wp-content/uploads/2025/11/AMRAVATI.png';
const _guideName = 'Prof. Mangesh Nichat';
const _academicYear = '2026-27';

/// Single accent used across the screen for role pills, the lead border,
/// and link text. Keeping one accent avoids visual noise.
const Color _accent = AppColors.safetyBlue;

// ============================================================
// DATA
// ============================================================

class TeamMember {
  final String name;
  final String rollNo;
  final String email;
  final String role;
  final String? photoAsset;
  final bool isLead;

  const TeamMember({
    required this.name,
    required this.rollNo,
    required this.email,
    required this.role,
    this.photoAsset,
    this.isLead = false,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

const _members = <TeamMember>[
  TeamMember(
    name: 'Samiksha Chavan',
    rollNo: 'CSEU23081',
    email: 'samikshachavan81@gmail.com',
    role: 'Team lead and system architect',
    photoAsset: 'assets/developers/samiksha.png',
    isLead: true,
  ),
  TeamMember(
    name: 'Gorakh Tapdiya',
    rollNo: 'CSEU23108',
    email: 'gorakhtapdiya765@gmail.com',
    role: 'Backend and Firebase engineer',
    photoAsset: 'assets/developers/gorakh.png',
  ),
  TeamMember(
    name: 'Chaitanya Ladole',
    rollNo: 'CSEU23104',
    email: 'chaitanyaladole2000@gmail.com',
    role: 'UI/UX designer and Flutter developer',
    photoAsset: 'assets/developers/chaitanya.png',
  ),
  TeamMember(
    name: 'Krutika Warthi',
    rollNo: 'CSEU23095',
    email: 'krutika.warthi017@gmail.com',
    role: 'Location, maps and real-time engineer',
    photoAsset: 'assets/developers/krutika.png',
  ),
  TeamMember(
    name: 'Rajshro Dhumane',
    rollNo: 'CSEU23080',
    email: 'rajshridhumane17@gmail.com',
    role: 'QA, testing and documentation lead',
    photoAsset: 'assets/developers/rajshree.png',
  ),
];

Future<void> _openWebsite(BuildContext context) async {
  final uri = Uri.parse(_schoolWebsite);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't open the website")),
    );
  }
}

// ============================================================
// SCREEN
// ============================================================

class DevelopersScreen extends StatelessWidget {
  const DevelopersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text(
          'Meet the team',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isWide = width >= _wideBreakpoint;
          final maxContentWidth =
              width >= 1600 ? 1500.0 : double.infinity;

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
                      ? const _WideBody()
                      : const _NarrowBody(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// WIDE LAYOUT
// ============================================================

class _WideBody extends StatelessWidget {
  const _WideBody();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 300, child: _ProjectPanel()),
        const SizedBox(width: 28),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1200 ? 3 : 2;
              return _MemberGrid(columns: columns);
            },
          ),
        ),
      ],
    );
  }
}

class _MemberGrid extends StatelessWidget {
  final int columns;

  const _MemberGrid({required this.columns});

  @override
  Widget build(BuildContext context) {
    final lead = _members.firstWhere(
      (m) => m.isLead,
      orElse: () => _members.first,
    );
    final rest =
        _members.where((m) => m != lead).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final tileWidth =
            (constraints.maxWidth - (columns - 1) * gap) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MemberCard(member: lead, compact: false),
            const SizedBox(height: gap),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final m in rest)
                  SizedBox(
                    width: tileWidth,
                    child: _MemberCard(member: m, compact: false),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProjectPanel extends StatelessWidget {
  const _ProjectPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SchoolLogo(size: 56),
          const SizedBox(height: 16),
          Text(
            _projectName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _projectTagline,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          const _PanelLine(
            label: 'Problem statement',
            value: _problemSource,
          ),
          const _PanelLine(label: 'Guide', value: _guideName),
          const _PanelLine(
            label: 'Academic year',
            value: _academicYear,
          ),
          const SizedBox(height: 4),
          _WebsiteLink(
            label: _schoolWebsiteLabel,
            onTap: () => _openWebsite(context),
          ),
        ],
      ),
    );
  }
}

class _PanelLine extends StatelessWidget {
  final String label;
  final String value;

  const _PanelLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _WebsiteLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.open_in_new_rounded,
                size: 15,
                color: _accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NARROW (PHONE) LAYOUT
// ============================================================

class _NarrowBody extends StatelessWidget {
  const _NarrowBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ProjectBanner(),
        const SizedBox(height: 16),
        for (final m in _members) ...[
          _MemberCard(member: m, compact: true),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ProjectBanner extends StatelessWidget {
  const _ProjectBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SchoolLogo(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _projectName,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _projectTagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _InfoChip(
                icon: Icons.school_rounded,
                text: _problemSource,
              ),
              const _InfoChip(
                icon: Icons.person_rounded,
                text: _guideName,
              ),
              const _InfoChip(
                icon: Icons.calendar_month_rounded,
                text: _academicYear,
              ),
              _InfoChip(
                icon: Icons.language_rounded,
                text: _schoolWebsiteLabel,
                onTap: () => _openWebsite(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InfoChip({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: _accent),
              const SizedBox(width: 6),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onTap == null ? scheme.onSurface : _accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MEMBER CARD
// ============================================================

class _MemberCard extends StatelessWidget {
  final TeamMember member;
  final bool compact;

  const _MemberCard({
    required this.member,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return compact ? _compactCard(context) : _wideCard(context);
  }

  Widget _wideCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarSize = member.isLead ? 120.0 : 96.0;


    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: member.isLead
              ? _accent
              : scheme.outlineVariant.withValues(alpha: 0.4),
          width: member.isLead ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Avatar(member: member, size: avatarSize),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Roll no. ${member.rollNo}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (member.isLead)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LEAD',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _RolePill(text: member.role),
          const SizedBox(height: 12),
          _EmailRow(email: member.email),
        ],
      ),
    );
  }

  Widget _compactCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarSize = member.isLead ? 96.0 : 76.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: member.isLead
              ? _accent
              : scheme.outlineVariant.withValues(alpha: 0.4),
          width: member.isLead ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(member: member, size: avatarSize),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                _RolePill(text: member.role),
                const SizedBox(height: 4),
                Text(
                  'Roll no. ${member.rollNo}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                _EmailRow(email: member.email),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final TeamMember member;
  final double size;

  const _Avatar({required this.member, required this.size});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _accent.withValues(alpha: 0.14),
      ),
      child: Text(
        member.initials,
        style: TextStyle(
          color: _accent,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    final asset = member.photoAsset;
    return Semantics(
      label: 'Photo of ${member.name}',
      image: true,
      child: asset == null
          ? fallback
          : ClipOval(
              child: Image.asset(
                asset,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String text;

  const _RolePill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: _accent,
        ),
      ),
    );
  }
}

class _EmailRow extends StatelessWidget {
  final String email;

  const _EmailRow({required this.email});

  Future<void> _open(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: email);
    final canLaunch = await canLaunchUrl(uri);
    final ok = canLaunch && await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mail app found')),
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _open(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                ),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'Copy email',
          child: IconButton(
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded, size: 16),
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            padding: EdgeInsets.zero,
            tooltip: 'Copy email',
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SCHOOL LOGO
// ============================================================

class _SchoolLogo extends StatelessWidget {
  final double size;

  const _SchoolLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$_schoolName logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
        child: Image.network(
          _schoolLogoUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (_, _, _) => Icon(
            Icons.school_rounded,
            color: _accent,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}