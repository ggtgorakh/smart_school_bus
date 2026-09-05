// lib/screens/profile_screen.dart

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'admin/create_user_screen.dart';
import 'admin/admin_operations_screen.dart';

class _ProfileData {
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? busId;
  final String? profileImage;
  final String? licenseNumber;
  final String? schoolId;
  final String? emergencyContact;
  final String? schoolName;
  final String? schoolAddress;
  final String? schoolContact;

  _ProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.busId,
    required this.profileImage,
    required this.licenseNumber,
    required this.schoolId,
    required this.emergencyContact,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolContact,
  });

  factory _ProfileData.fromMap(
    Map<dynamic, dynamic> map, {
    required String fallbackEmail,
  }) {
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
      profileImage: map['profileImage']?.toString(),
      licenseNumber: map['licenseNumber']?.toString(),
      schoolId: map['schoolId']?.toString(),
      emergencyContact: map['emergencyContact']?.toString(),
      schoolName: map['schoolName']?.toString(),
      schoolAddress: map['schoolAddress']?.toString(),
      schoolContact: map['schoolContact']?.toString(),
    );
  }
}

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

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _root = FirebaseDatabase.instance.ref();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isProfileImageSaving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openEditNameSheet(
    String currentName,
    String? currentPhone,
    String uid,
    String role,
    String? busId,
    String? licenseNumber,
    String? schoolId,
    String? emergencyContact,
  ) {
    final controller = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone ?? '');
    final roleFieldController = TextEditingController(
      text: role == 'Driver'
          ? licenseNumber
          : role == 'Admin'
          ? schoolId
          : emergencyContact,
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool isSaving = false;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
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

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.safetyBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: AppColors.safetyBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep your name and contact number up to date for safe dispatch communication.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: controller,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.outline,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.safetyBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: phoneController,
                        enabled: !isSaving,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: AppColors.outline,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (role != 'Conductor') ...[
                        Text(
                          role == 'Driver'
                              ? 'License Number'
                              : role == 'Admin'
                              ? 'School ID'
                              : 'Emergency Contact',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: roleFieldController,
                          enabled: !isSaving,
                          keyboardType: role == 'Parent'
                              ? TextInputType.phone
                              : TextInputType.text,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              role == 'Driver'
                                  ? Icons.badge_outlined
                                  : role == 'Admin'
                                  ? Icons.school_outlined
                                  : Icons.contact_phone_outlined,
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                try {
                                  await AuthService.instance
                                      .sendPasswordResetEmail(
                                        FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.email ??
                                            '',
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Password reset instructions sent to your email.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not send password reset email: $error',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.lock_reset_outlined),
                        label: const Text('Send password reset email'),
                      ),
                      const SizedBox(height: 8),

                      // Save Button
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
                                    await AuthService.instance.updateOwnName(
                                      uid,
                                      controller.text.trim(),
                                    );
                                    await AuthService.instance.updateOwnPhone(
                                      uid,
                                      phoneController.text,
                                    );
                                    await AuthService.instance
                                        .updateOwnProfileFields(
                                          uid,
                                          licenseNumber: role == 'Driver'
                                              ? roleFieldController.text
                                              : null,
                                          schoolId: role == 'Admin'
                                              ? roleFieldController.text
                                              : null,
                                          emergencyContact: role == 'Parent'
                                              ? roleFieldController.text
                                              : null,
                                        );
                                    if (role == 'Driver' &&
                                        busId != null &&
                                        busId.trim().isNotEmpty) {
                                      await FirebaseService.instance
                                          .syncDriverContactToFleet(
                                            uid: uid,
                                            busId: busId,
                                            name: controller.text,
                                            phone: phoneController.text,
                                          );
                                    }
                                    if (context.mounted)
                                      Navigator.of(context).pop();
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Could not save: $e'),
                                          backgroundColor: AppColors.errorRed,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.safetyBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
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
        return ['🚌 Bus Route Navigation', '👤 Driver Profile'];
      case 'Conductor':
        return [
          '📋 Student Check-in/Check-out',
          '🗺️ Bus Route Map',
          '👤 Conductor Profile',
        ];
      case 'Admin':
        return [
          '🚌 Fleet Overview & Telemetry',
          '🗺️ Master GPS Map',
          '📋 Student and user management',
          '⚙️ Dispatch messaging',
        ];
      default:
        return ['📍 Live Child Bus Tracking', '🔔 Parent Profile & Alerts'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isMobile = context.isMobile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Please sign in to view your profile.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: StreamBuilder<DatabaseEvent>(
              stream: _root.child('users/${user.uid}').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppColors.errorRed,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Can't load your profile",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Firebase error: ${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.safetyBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.safetyBlue,
                    ),
                  );
                }

                final raw = snapshot.data!.snapshot.value;
                final profile = (raw is Map)
                    ? _ProfileData.fromMap(
                        raw,
                        fallbackEmail: user.email ?? '---',
                      )
                    : _ProfileData(
                        name: 'Unnamed user',
                        email: user.email ?? '---',
                        phone: null,
                        role: widget.activeRole,
                        busId: null,
                        profileImage: null,
                        licenseNumber: null,
                        schoolId: null,
                        emergencyContact: null,
                        schoolName: null,
                        schoolAddress: null,
                        schoolContact: null,
                      );

                final authorizedScope = _authorizedScope(profile.role);
                final isDesktop = context.isDesktop;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 28),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 1180,
                      ),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _buildProfileHeader(
                                        context,
                                        profile,
                                        user.uid,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStatsRow(context, profile),
                                      const SizedBox(height: 16),
                                      _buildPermissionsCard(
                                        context,
                                        authorizedScope,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildRoleDetails(context, profile),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      if (profile.role == 'Admin') ...[
                                        _buildAdminCard(context),
                                        const SizedBox(height: 16),
                                      ],
                                      _buildEmergencyContacts(context),
                                      const SizedBox(height: 20),
                                      _buildSignOutButton(context),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildProfileHeader(context, profile, user.uid),
                                const SizedBox(height: 16),
                                _buildStatsRow(context, profile),
                                const SizedBox(height: 16),
                                _buildPermissionsCard(context, authorizedScope),
                                const SizedBox(height: 16),
                                _buildRoleDetails(context, profile),
                                if (profile.role == 'Admin') ...[
                                  const SizedBox(height: 16),
                                  _buildAdminCard(context),
                                ],
                                const SizedBox(height: 16),
                                _buildEmergencyContacts(context),
                                const SizedBox(height: 20),
                                _buildSignOutButton(context),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(
    BuildContext context,
    _ProfileData profile,
    String uid,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with Edit Button
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.brandGradient,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.safetyBlue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _buildProfileAvatar(context, profile.profileImage),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: InkWell(
                    onTap: _isProfileImageSaving
                        ? null
                        : () => _showProfileImageActions(
                            context,
                            uid,
                            hasImage:
                                profile.profileImage != null &&
                                profile.profileImage!.isNotEmpty,
                          ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: _isProfileImageSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              profile.profileImage?.isNotEmpty == true
                                  ? Icons.photo_camera_rounded
                                  : Icons.add_a_photo_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            profile.name,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            profile.email,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (profile.phone != null && profile.phone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              profile.phone!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.safetyBlue.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Signed in as ${profile.role}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _isProfileImageSaving
                ? null
                : () => _openEditNameSheet(
                    profile.name,
                    profile.phone,
                    uid,
                    profile.role,
                    profile.busId,
                    profile.licenseNumber,
                    profile.schoolId,
                    profile.emergencyContact,
                  ),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit profile details'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, String? imageData) {
    if (imageData != null && imageData.isNotEmpty) {
      try {
        return ClipOval(
          child: Image.memory(
            base64Decode(imageData),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultProfileAvatar(),
          ),
        );
      } on FormatException {
        return _defaultProfileAvatar();
      }
    }
    return _defaultProfileAvatar();
  }

  Widget _defaultProfileAvatar() {
    return const Center(
      child: Icon(Icons.person_rounded, size: 52, color: Colors.white),
    );
  }

  Future<void> _showProfileImageActions(
    BuildContext context,
    String uid, {
    required bool hasImage,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                hasImage ? 'Change profile image' : 'Add profile image',
              ),
              onTap: () => Navigator.pop(sheetContext, 'pick'),
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.errorRed,
                ),
                title: const Text('Delete profile image'),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'pick') {
      await _pickProfileImage(uid);
    } else if (action == 'delete') {
      await _deleteProfileImage(uid);
    }
  }

  Future<void> _pickProfileImage(String uid) async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (!mounted || file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 1500000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose an image smaller than 1.5 MB.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProfileImageSaving = true);
    try {
      await AuthService.instance.updateOwnProfileImage(
        uid,
        base64Encode(bytes),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update profile image: $error'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProfileImageSaving = false);
    }
  }

  Future<void> _deleteProfileImage(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete profile image?'),
        content: const Text('Your profile will return to the default avatar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _isProfileImageSaving = true);
    try {
      await AuthService.instance.updateOwnProfileImage(uid, null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete profile image: $error'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProfileImageSaving = false);
    }
  }

  // ============================================================
  // STATS ROW
  // ============================================================

  Widget _buildStatsRow(BuildContext context, _ProfileData profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            label: 'Role',
            value: profile.role,
            icon: Icons.badge_rounded,
          ),
          if (profile.role != 'Admin')
            _buildStatItem(
              context,
              label: 'Bus ID',
              value: profile.busId ?? 'Not Assigned',
              icon: Icons.directions_bus_rounded,
              valueColor: profile.busId == null ? AppColors.alertOrange : null,
            ),
          _buildStatItem(
            context,
            label: 'Status',
            value: 'Active',
            icon: Icons.check_circle_rounded,
            valueColor: AppColors.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERMISSIONS CARD
  // ============================================================

  Widget _buildPermissionsCard(BuildContext context, List<String> scopes) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppColors.safetyBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Access',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...scopes.map(
            (scope) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.mintSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.successGreen,
                      size: 14,
                    ),
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
    );
  }

  // ============================================================
  // ADMIN CARD
  // ============================================================

  Widget _buildAdminCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purpleSoft,
            AppColors.purpleSoft.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.1),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Admin Management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade800,
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
                child: const Icon(
                  Icons.person_add_rounded,
                  color: AppColors.safetyBlue,
                  size: 18,
                ),
              ),
              title: const Text(
                'Provision New User',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              subtitle: Text(
                'Create Driver, Conductor, Parent, or Admin credentials',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.outline,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminCreateUserScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.manage_accounts_rounded,
                  color: AppColors.successGreen,
                  size: 18,
                ),
              ),
              title: const Text(
                'People & Assignments',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              subtitle: Text(
                'Edit drivers, conductors, and assigned buses',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.outline,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminOperationsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMERGENCY CONTACTS
  // ============================================================

  Widget _buildEmergencyContacts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: AppColors.errorRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Emergency & Support',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.sos_rounded,
            iconBg: AppColors.errorRed.withValues(alpha: 0.1),
            iconColor: AppColors.errorRed,
            title: 'Emergency services',
            subtitle: 'Call 112',
            onTap: () => _callNumber('112'),
          ),
          _ContactTile(
            icon: Icons.local_hospital_outlined,
            iconBg: AppColors.alertOrange.withValues(alpha: 0.1),
            iconColor: AppColors.alertOrange,
            title: 'Medical emergency',
            subtitle: 'Call 108',
            onTap: () => _callNumber('108'),
          ),
          _ContactTile(
            icon: Icons.support_agent_rounded,
            iconBg: AppColors.safetyBlue.withValues(alpha: 0.1),
            iconColor: AppColors.safetyBlue,
            title: 'School transport desk',
            subtitle: 'Contact the school office for route support',
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
                  title: Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: AppColors.safetyBlue,
                      ),
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
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone app.')),
      );
    }
  }

  Widget _buildRoleDetails(BuildContext context, _ProfileData profile) {
    final details = switch (profile.role) {
      'Admin' => const [
        (
          'School operations',
          'Fleet, users, routes, and safety oversight',
          Icons.admin_panel_settings_outlined,
        ),
        (
          'Maintenance',
          'Review assignments and keep route data current',
          Icons.build_circle_outlined,
        ),
        (
          'Support',
          'Coordinate transport desk and emergency escalation',
          Icons.support_agent_outlined,
        ),
      ],
      'Driver' => const [
        (
          'Dispatch',
          'Follow the assigned route and report trip status',
          Icons.route_outlined,
        ),
        (
          'Vehicle safety',
          'Complete pre-trip checks before departure',
          Icons.fact_check_outlined,
        ),
        (
          'Communication',
          'Keep dispatch contact details current',
          Icons.phone_outlined,
        ),
      ],
      'Conductor' => const [
        (
          'Attendance',
          'Update student boarding status at each stop',
          Icons.how_to_reg_outlined,
        ),
        (
          'Safety',
          'Keep the roster and emergency details available',
          Icons.health_and_safety_outlined,
        ),
        (
          'Communication',
          'Escalate attendance or route issues to dispatch',
          Icons.phone_outlined,
        ),
      ],
      _ => const [
        (
          'Child safety',
          'View live status and attendance updates',
          Icons.child_care_outlined,
        ),
        (
          'School transport',
          'Review assigned bus and staff information',
          Icons.directions_bus_outlined,
        ),
        (
          'Support',
          'Contact the school office for account or route help',
          Icons.support_agent_outlined,
        ),
      ],
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.school_outlined,
                color: AppColors.safetyBlue,
              ),
              title: Text(
                profile.schoolName?.trim().isNotEmpty == true
                    ? profile.schoolName!
                    : 'School transport service',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [profile.schoolAddress, profile.schoolContact]
                        .where((value) => value?.trim().isNotEmpty == true)
                        .join(' • ')
                        .isEmpty
                    ? 'Route, attendance, and safety operations'
                    : [profile.schoolAddress, profile.schoolContact]
                          .where((value) => value?.trim().isNotEmpty == true)
                          .join(' • '),
              ),
            ),
            for (final detail in details)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(detail.$3, color: AppColors.safetyBlue),
                title: Text(
                  detail.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(detail.$2),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SIGN OUT BUTTON
  // ============================================================

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: widget.onSignOut,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.errorRed,
          side: const BorderSide(color: AppColors.errorRed, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Sign Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ============================================================
// CONTACT TILE
// ============================================================

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
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.outline,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
