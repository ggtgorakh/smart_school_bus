import 'package:shared_preferences/shared_preferences.dart';

/// Persists non-credential UI session state (such as the active tab index
/// and cached role) across browser reloads (web) and app restarts (mobile/desktop).
///
/// Authentication state and session tokens are managed directly by Firebase Auth.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _kUserRole = 'session_user_role';
  static const _kTabIndex = 'session_tab_index';
  static const _kBusId = 'session_bus_id';

  /// Retrieves the cached role for instant rendering while auth resolves.
  Future<String?> getCachedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserRole);
  }

  /// Caches the current user's role.
  Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserRole, role);
  }

  /// Retrieves the cached assigned bus ID (Bug #4) for instant rendering
  /// while the fresh value is fetched from Realtime Database.
  Future<String?> getCachedBusId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBusId);
  }

  /// Caches the current user's assigned bus ID.
  Future<void> saveBusId(String busId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBusId, busId);
  }

  /// Retrieves the persisted navigation tab index.
  Future<int> getTabIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTabIndex) ?? 0;
  }

  /// Persists the active navigation tab index.
  Future<void> saveTabIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTabIndex, index);
  }

  /// Clears stored session preferences upon sign out.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserRole);
    await prefs.remove(_kTabIndex);
    await prefs.remove(_kBusId);
  }
}
