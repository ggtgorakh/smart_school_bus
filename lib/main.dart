// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'config/school_config.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';
import 'services/notification_service.dart';
import 'services/offline_write_queue.dart';
import 'services/location_service.dart';
import 'services/emergency_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Restore persisted theme choice before the first frame so the app
  // doesn't flash light-then-dark on cold start.
  final themeIndex = await SessionService.instance.getThemeMode();
  if (themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
    ThemeController.instance.hydrate(ThemeMode.values[themeIndex]);
  }

  // Load the school configuration once, synchronously, so the first
  // frame already knows the school's name, contact, and location.
  try {
    final cfg = await FirebaseService.instance.fetchSchoolConfigOnce();
    SchoolConfigController.instance.hydrate(cfg);
  } catch (_) {
    // Defaults are already in place.
  }

  runApp(const SchoolBusApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    OfflineWriteQueue.instance.initialize();
    NotificationService.instance;
    LocationService.instance.initialize();

    // Live-update the config when the Admin changes it on any device.
    FirebaseService.instance.streamSchoolConfig().listen((cfg) {
      SchoolConfigController.instance.hydrate(cfg);
    });
  });
}

class SchoolBusApp extends StatelessWidget {
  const SchoolBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.instance,
        SchoolConfigController.instance,
      ]),
      builder: (context, _) {
        return MaterialApp(
          title: SchoolConfigController.instance.config.fullName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.mode,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppSplashScreen();
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        return RoleResolutionShell(user: user);
      },
    );
  }
}

class RoleResolutionShell extends StatefulWidget {
  final User user;
  const RoleResolutionShell({super.key, required this.user});

  @override
  State<RoleResolutionShell> createState() => _RoleResolutionShellState();
}

class _RoleResolutionShellState extends State<RoleResolutionShell> {
  String? _role;
  String? _busId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  @override
  void didUpdateWidget(covariant RoleResolutionShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _resolveRole();
    }
  }

  Future<void> _resolveRole() async {
    final cachedRole = await SessionService.instance.getCachedRole();
    if (cachedRole != null && mounted) {
      setState(() {
        _role = cachedRole;
        _isLoading = false;
      });
    }

    final freshValues = await Future.wait([
      AuthService.instance.fetchRole(widget.user.uid),
      AuthService.instance.fetchBusId(widget.user.uid),
    ]);
    final freshRole = freshValues[0];
    final freshBusId = freshValues[1];

    await SessionService.instance.saveRole(freshRole);
    await SessionService.instance.saveBusId(freshBusId);

    if (freshRole == 'Admin') {
      // Best-effort registration. If it fails, the Admin will not
      // receive SOS notifications until next launch, but sign-in
      // must not be blocked by an index write.
      try {
        await EmergencyService.instance.registerAdminIndex(widget.user.uid);
      } catch (e) {
        debugPrint(
          'RoleResolutionShell: admin index registration failed: $e',
        );
      }
    }

    if (mounted) {
      setState(() {
        _role = freshRole;
        _busId = freshBusId;
        _isLoading = false;
      });
    }
  }

  /// Signs out the current user.
  ///
  /// Before signing out, if this user is an Admin, the Admin is
  /// removed from /adminIndex. This is done BEFORE signOut so the
  /// rule that requires role === 'Admin' still matches (the rule
  /// checks the caller's role, which is only readable while signed in).
  ///
  /// If the unregister write fails (network, permissions), we log it
  /// and continue with sign-out. A blocked sign-out is worse than a
  /// stale adminIndex entry, which the SOS flow treats as best-effort.
  Future<void> _handleSignOut() async {
    final uid = widget.user.uid;

    await NotificationService.instance.clearAll();

    try {
      await EmergencyService.instance.unregisterAdminIndex(uid);
    } catch (e) {
      debugPrint(
        'RoleResolutionShell: admin index unregister failed on sign-out: $e',
      );
    }

    await AuthService.instance.signOut();
    await SessionService.instance.clearSession();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _role == null) {
      return const AppSplashScreen();
    }
    return MainNavigationShell(
      userRole: _role ?? 'Parent',
      busId: _busId ?? '',
      onSignOut: _handleSignOut,
    );
  }
}

class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.safetyBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.safetyBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}