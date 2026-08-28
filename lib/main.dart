import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SchoolBusApp());
}

class SchoolBusApp extends StatelessWidget {
  const SchoolBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchoolBus Safe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

/// Listens to real-time Firebase Auth state changes and routes between
/// the login screen and the authorized main navigation shell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AppSplashScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return _RoleResolutionShell(user: user);
      },
    );
  }
}

class _RoleResolutionShell extends StatefulWidget {
  final User user;

  const _RoleResolutionShell({required this.user});

  @override
  State<_RoleResolutionShell> createState() => _RoleResolutionShellState();
}

class _RoleResolutionShellState extends State<_RoleResolutionShell> {
  String? _role;
  String? _busId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  @override
  void didUpdateWidget(covariant _RoleResolutionShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _resolveRole();
    }
  }

  Future<void> _resolveRole() async {
    // 1. Try cached role/busId first for immediate UI responsiveness
    final cachedRole = await SessionService.instance.getCachedRole();
    final cachedBusId = await SessionService.instance.getCachedBusId();
    if (cachedRole != null && mounted) {
      setState(() {
        _role = cachedRole;
        _busId = cachedBusId;
        _isLoading = false;
      });
    }

    // 2. Fetch fresh role + assigned bus from Realtime Database.
    // Bug #4 fix: the app itself now only ever points a Driver at the bus
    // recorded on their own user profile (server-enforced by Firebase
    // Rules), instead of every role sharing a hardcoded 'bus_01'.
    final freshRole = await AuthService.instance.fetchRole(widget.user.uid);
    final freshBusId = await AuthService.instance.fetchBusId(widget.user.uid);
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _role == null) {
      return const _AppSplashScreen();
    }

    return MainNavigationShell(
      userRole: _role ?? 'Parent',
      busId: _busId ?? 'bus_01',
      onSignOut: _handleSignOut,
    );
  }
}

class _AppSplashScreen extends StatelessWidget {
  const _AppSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(22),
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
