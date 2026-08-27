import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Centralized authentication service managing Firebase Auth sessions,
/// role fetching from Realtime Database, and secondary-app Admin user provisioning.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Exposes the underlying FirebaseAuth instance if needed.
  FirebaseAuth get auth => _auth;

  /// Stream of user authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated user (if any).
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Fetch user role from Firebase Realtime Database at `/users/$uid/role`.
  ///
  /// Falls back to [defaultRole] if no specific role is found or on network error.
  Future<String> fetchRole(String uid, {String defaultRole = 'Parent'}) async {
    try {
      final roleSnapshot = await _db.child('users/$uid/role').get();
      if (roleSnapshot.exists && roleSnapshot.value != null) {
        final roleVal = roleSnapshot.value.toString().trim();
        if (roleVal.isNotEmpty) return roleVal;
      }

      // Check full user record if role was stored inside an object
      final userSnapshot = await _db.child('users/$uid').get();
      if (userSnapshot.exists && userSnapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(userSnapshot.value as Map);
        if (data['role'] != null) {
          final roleVal = data['role'].toString().trim();
          if (roleVal.isNotEmpty) return roleVal;
        }
      }
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('Error fetching role for $uid from RTDB: $e');
        return true;
      }());
    }
    return defaultRole;
  }

  /// Sets or updates the user role in Realtime Database.
  Future<void> setUserRole(String uid, String role, {String? email, String? name}) async {
    try {
      final Map<String, dynamic> data = {'role': role};
      if (email != null) data['email'] = email;
      if (name != null) data['name'] = name;
      await _db.child('users/$uid').update(data);
    } catch (_) {}
  }

  /// Creates a new user in Firebase Auth and provisions their profile in Realtime Database.
  ///
  /// Uses a temporary secondary [FirebaseApp] instance to ensure the currently
  /// logged-in Admin is NOT signed out during creation.
  Future<UserCredential> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final secondaryAppName = 'AdminUserCreation_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp? secondaryApp;

    try {
      final defaultApp = Firebase.app();
      secondaryApp = await Firebase.initializeApp(
        name: secondaryAppName,
        options: defaultApp.options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final newUid = userCredential.user?.uid;
      if (newUid != null) {
        // Write the new user metadata & role into Realtime Database using the primary app
        await _db.child('users/$newUid').set({
          'name': name.trim(),
          'email': email.trim(),
          'role': role,
          'createdAt': ServerValue.timestamp,
        });
      }

      return userCredential;
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
