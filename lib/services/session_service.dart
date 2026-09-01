// lib/services/session_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Persists non-credential UI session state (such as the active tab index
/// and cached role) across browser reloads (web) and app restarts (mobile/desktop).
///
/// Authentication state and session tokens are managed directly by Firebase Auth.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const String _kUserRole = 'session_user_role';
  static const String _kTabIndex = 'session_tab_index';
  static const String _kBusId = 'session_bus_id';
  static const String _kThemeMode = 'session_theme_mode';
  static const String _kLastEmail = 'session_last_email';
  static const String _kRememberMe = 'session_remember_me';

  /// Retrieves the cached role for instant rendering while auth resolves.
  Future<String?> getCachedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kUserRole);
    } catch (error) {
      print('SessionService: Error getting cached role: $error');
      return null;
    }
  }

  /// Caches the current user's role.
  Future<void> saveRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserRole, role);
    } catch (error) {
      print('SessionService: Error saving role: $error');
    }
  }

  /// Retrieves the cached assigned bus ID for instant rendering.
  Future<String?> getCachedBusId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kBusId);
    } catch (error) {
      print('SessionService: Error getting cached busId: $error');
      return null;
    }
  }

  /// Caches the current user's assigned bus ID.
  Future<void> saveBusId(String busId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kBusId, busId);
    } catch (error) {
      print('SessionService: Error saving busId: $error');
    }
  }

  /// Retrieves the persisted navigation tab index.
  Future<int> getTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kTabIndex) ?? 0;
    } catch (error) {
      print('SessionService: Error getting tab index: $error');
      return 0;
    }
  }

  /// Persists the active navigation tab index.
  Future<void> saveTabIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kTabIndex, index);
    } catch (error) {
      print('SessionService: Error saving tab index: $error');
    }
  }

  /// Retrieves the persisted theme mode.
  Future<int> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kThemeMode) ?? 0; // 0 = system, 1 = light, 2 = dark
    } catch (error) {
      print('SessionService: Error getting theme mode: $error');
      return 0;
    }
  }

  /// Persists the theme mode.
  Future<void> saveThemeMode(int mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kThemeMode, mode);
    } catch (error) {
      print('SessionService: Error saving theme mode: $error');
    }
  }

  /// Retrieves the last used email for login.
  Future<String?> getLastEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kLastEmail);
    } catch (error) {
      print('SessionService: Error getting last email: $error');
      return null;
    }
  }

  /// Persists the last used email for login.
  Future<void> saveLastEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastEmail, email);
    } catch (error) {
      print('SessionService: Error saving last email: $error');
    }
  }

  /// Retrieves the remember me setting.
  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kRememberMe) ?? false;
    } catch (error) {
      print('SessionService: Error getting remember me: $error');
      return false;
    }
  }

  /// Persists the remember me setting.
  Future<void> saveRememberMe(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRememberMe, value);
    } catch (error) {
      print('SessionService: Error saving remember me: $error');
    }
  }

  /// Clears stored session preferences upon sign out.
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserRole);
      await prefs.remove(_kTabIndex);
      await prefs.remove(_kBusId);
      // Keep theme and email preferences for next login
    } catch (error) {
      print('SessionService: Error clearing session: $error');
    }
  }

  /// Clears all session data (including preferences).
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (error) {
      print('SessionService: Error clearing all: $error');
    }
  }
}