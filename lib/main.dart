import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';
import 'services/notification_service.dart';
import 'services/offline_write_queue.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SchoolBusApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    OfflineWriteQueue.instance.initialize();
    NotificationService.instance;
  });
}

class SchoolBusApp extends StatelessWidget {
  const SchoolBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Smart School Bus',
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
    final cachedValues = await Future.wait([
      SessionService.instance.getCachedRole(),
      SessionService.instance.getCachedBusId(),
    ]);
    final cachedRole = cachedValues[0] as String?;
    final cachedBusId = cachedValues[1] as String?;
    if (cachedRole != null && mounted) {
      setState(() {
        _role = cachedRole;
        _busId = cachedBusId;
        _isLoading = false;
      });
    }

    final freshValues = await Future.wait([
      AuthService.instance.fetchRole(widget.user.uid),
      AuthService.instance.fetchBusId(widget.user.uid),
    ]);
    final freshRole = freshValues[0] as String;
    final freshBusId = freshValues[1] as String;

    await SessionService.instance.saveRole(freshRole);
    await SessionService.instance.saveBusId(freshBusId);

    if (mounted) {
      setState(() {
        _role = freshRole;
        _busId = freshBusId;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    await AuthService.instance.signOut();
    await SessionService.instance.clearSession();
    // Clear notifications on sign out
    NotificationService.instance.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _role == null) {
      return const AppSplashScreen();
    }
    return MainNavigationShell(
      userRole: _role ?? 'Parent',
      busId: _busId ?? 'bus_01',
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
