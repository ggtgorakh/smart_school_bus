// lib/services/session_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists non-credential UI session state (active tab, cached role, theme)
/// across browser reloads (web) and app restarts (mobile/desktop).
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

  Future<String?> getCachedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kUserRole);
    } catch (error) {
      debugPrint('SessionService: Error getting cached role: $error');
      return null;
    }
  }

  Future<void> saveRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserRole, role);
    } catch (error) {
      debugPrint('SessionService: Error saving role: $error');
    }
  }

  Future<String?> getCachedBusId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kBusId);
    } catch (error) {
      debugPrint('SessionService: Error getting cached busId: $error');
      return null;
    }
  }

  Future<void> saveBusId(String busId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kBusId, busId);
    } catch (error) {
      debugPrint('SessionService: Error saving busId: $error');
    }
  }

  Future<int> getTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kTabIndex) ?? 0;
    } catch (error) {
      debugPrint('SessionService: Error getting tab index: $error');
      return 0;
    }
  }

  Future<void> saveTabIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kTabIndex, index);
    } catch (error) {
      debugPrint('SessionService: Error saving tab index: $error');
    }
  }

  Future<int> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kThemeMode) ?? 0; // 0 = system, 1 = light, 2 = dark
    } catch (error) {
      debugPrint('SessionService: Error getting theme mode: $error');
      return 0;
    }
  }

  Future<void> saveThemeMode(int mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kThemeMode, mode);
    } catch (error) {
      debugPrint('SessionService: Error saving theme mode: $error');
    }
  }

  Future<String?> getLastEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kLastEmail);
    } catch (error) {
      debugPrint('SessionService: Error getting last email: $error');
      return null;
    }
  }

  Future<void> saveLastEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastEmail, email);
    } catch (error) {
      debugPrint('SessionService: Error saving last email: $error');
    }
  }

  Future<void> clearSavedLoginEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastEmail);
    } catch (error) {
      debugPrint('SessionService: Error clearing saved email: $error');
    }
  }

  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kRememberMe) ?? false;
    } catch (error) {
      debugPrint('SessionService: Error getting remember me: $error');
      return false;
    }
  }

  Future<void> saveRememberMe(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRememberMe, value);
    } catch (error) {
      debugPrint('SessionService: Error saving remember me: $error');
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserRole);
      await prefs.remove(_kTabIndex);
      await prefs.remove(_kBusId);
      // Keep theme and email preferences for next login
    } catch (error) {
      debugPrint('SessionService: Error clearing session: $error');
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (error) {
      debugPrint('SessionService: Error clearing all: $error');
    }
  }
}