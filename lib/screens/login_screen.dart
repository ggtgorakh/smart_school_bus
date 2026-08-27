import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(String role)? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRole = 'Parent';
  final _emailController = TextEditingController(text: 'parent@schoolsafe.org');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();
  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slideIn = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential credential;
      try {
        credential = await AuthService.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (authEx) {
        if (authEx.code == 'user-not-found' ||
            authEx.code == 'invalid-credential') {
          // If demo user doesn't exist yet, automatically create it
          try {
            credential = await AuthService.instance.auth
                .createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      final uid = credential.user?.uid;
      String role = _selectedRole;
      if (uid != null) {
        role = await AuthService.instance.fetchRole(
          uid,
          defaultRole: _selectedRole,
        );
        // Persist role into Realtime Database
        await AuthService.instance.setUserRole(uid, role, email: email);
      }

      await SessionService.instance.saveRole(role);

      if (mounted) {
        widget.onLoginSuccess?.call(role);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user account found with this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message =
              'Incorrect email or password. Please verify your credentials.';
          break;
        case 'invalid-email':
          message = 'The email address format is invalid.';
          break;
        case 'user-disabled':
          message =
              'This account has been disabled. Contact your administrator.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please wait a moment and try again.';
          break;
        default:
          message = e.message ?? 'Authentication failed (${e.code}).';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_isLoading) return;

    // Quick biometric authentication prompt simulation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.fingerprint_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text('Biometric authentication verified for $_selectedRole'),
          ],
        ),
        backgroundColor: AppColors.safetyBlue,
        duration: const Duration(seconds: 1),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _handleLogin();
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email to receive a password reset link',
          ),
        ),
      );
      return;
    }

    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to $email'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Failed to send reset link'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  String _scopeCopyFor(String role) {
    switch (role) {
      case 'Driver':
        return 'You can access: Route, Profile';
      case 'Conductor':
        return 'You can access: Students, Map, Profile';
      case 'Admin':
        return 'You can access: Fleet, Routes, Map, Students, Profile';
      default:
        return 'You can access: Live Map, Profile';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      body: Stack(
        children: [
          // Ambient brand-gradient shapes instead of flat tinted circles.
          Positioned(
            top: -70,
            left: -80,
            child: _AmbientBlob(
              size: 260,
              gradient: LinearGradient(
                colors: [
                  AppColors.safetyBlue.withValues(alpha: 0.16),
                  AppColors.primaryDark.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -90,
            child: _AmbientBlob(
              size: 320,
              gradient: LinearGradient(
                colors: [
                  AppColors.alertOrange.withValues(alpha: 0.12),
                  AppColors.alertOrange.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideIn,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Branding mark
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: AppTheme.brandGradient,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.safetyBlue.withValues(
                                  alpha: 0.32,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_filled_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'SchoolBus Safe',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: AppColors.primaryDark,
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Know exactly where your child\'s bus is',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Login card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.glassDecoration(
                            borderRadius: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'SIGN IN AS',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontSize: 11,
                                      letterSpacing: 1.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RoleChip(
                                      role: 'Parent',
                                      icon: Icons.family_restroom_rounded,
                                      isSelected: _selectedRole == 'Parent',
                                      onTap: () => _selectRole('Parent'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _RoleChip(
                                      role: 'Driver',
                                      icon: Icons.local_shipping_rounded,
                                      isSelected: _selectedRole == 'Driver',
                                      onTap: () => _selectRole('Driver'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RoleChip(
                                      role: 'Conductor',
                                      icon: Icons.how_to_reg_rounded,
                                      isSelected: _selectedRole == 'Conductor',
                                      onTap: () => _selectRole('Conductor'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _RoleChip(
                                      role: 'Admin',
                                      icon: Icons.admin_panel_settings_rounded,
                                      isSelected: _selectedRole == 'Admin',
                                      onTap: () => _selectRole('Admin'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  key: ValueKey(_selectedRole),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.safetyBlue.withValues(
                                      alpha: 0.07,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.safetyBlue.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        size: 15,
                                        color: AppColors.safetyBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _scopeCopyFor(_selectedRole),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.safetyBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),

                              const _FieldLabel('Email or ID'),
                              const SizedBox(height: 6),
                              _ModernTextField(
                                controller: _emailController,
                                icon: Icons.person_outline_rounded,
                                hint: 'Enter your credentials',
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const _FieldLabel('Password'),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleForgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: AppColors.alertOrangeDark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _ModernTextField(
                                controller: _passwordController,
                                icon: Icons.lock_outline_rounded,
                                hint: 'Enter your password',
                                obscureText: _obscurePassword,
                                enabled: !_isLoading,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.outline,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 26),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.brandGradient,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.safetyBlue.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: _isLoading ? null : _handleLogin,
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Column(
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(
                                          color: AppColors.outlineVariant,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          'or continue with',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color:
                                                    AppColors.onSurfaceVariant,
                                                fontSize: 12.5,
                                              ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(
                                          color: AppColors.outlineVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  InkWell(
                                    onTap: _isLoading
                                        ? null
                                        : _handleBiometricLogin,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: Border.all(
                                          color: AppColors.outlineVariant,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.fingerprint_rounded,
                                        color: AppColors.safetyBlue,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Need an account? ',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Support Desk: support@schoolbussafe.org',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Contact Administrator',
                                style: TextStyle(
                                  color: AppColors.safetyBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'Parent') {
        _emailController.text = 'parent@schoolsafe.org';
      } else if (role == 'Driver') {
        _emailController.text = 'driver@schoolsafe.org';
      } else if (role == 'Conductor') {
        _emailController.text = 'conductor@schoolsafe.org';
      } else if (role == 'Admin') {
        _emailController.text = 'admin@schoolsafe.org';
      }
      _passwordController.text = 'password123';
    });
  }
}

class _AmbientBlob extends StatelessWidget {
  final double size;
  final Gradient gradient;
  const _AmbientBlob({required this.size, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.textMain,
        fontSize: 12.5,
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscureText;
  final bool enabled;
  final Widget? suffix;

  const _ModernTextField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.outline, size: 20),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.outline, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.safetyBlue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.role,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.safetyBlue.withValues(alpha: 0.08)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.safetyBlue : AppColors.outlineVariant,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.safetyBlue : AppColors.outline,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.safetyBlue : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
