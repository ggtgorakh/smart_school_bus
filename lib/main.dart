import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_shell.dart';

void main() {
  runApp(const SchoolBusApp());
}

class SchoolBusApp extends StatefulWidget {
  const SchoolBusApp({super.key});

  @override
  State<SchoolBusApp> createState() => _SchoolBusAppState();
}

class _SchoolBusAppState extends State<SchoolBusApp> {
  bool _isLoggedIn = false;
  String _userRole = 'Parent';

  void _handleLogin(String role) {
    setState(() {
      _userRole = role;
      _isLoggedIn = true;
    });
  }

  void _handleSignOut() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchoolBus Safe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLoggedIn
          ? MainNavigationShell(
              userRole: _userRole,
              onSignOut: _handleSignOut,
            )
          : LoginScreen(
              onLoginSuccess: _handleLogin,
            ),
    );
  }
}
