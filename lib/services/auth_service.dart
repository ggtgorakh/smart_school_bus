// lib/services/auth_service.dart

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

  /// Check if user is currently authenticated.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user's UID.
  String? get currentUid => _auth.currentUser?.uid;

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      print('AuthService: Sign in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      print('AuthService: Sign out error: $error');
      rethrow;
    }
  }

  /// Fetch user role from Firebase Realtime Database at `/users/$uid/role`.
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
    } catch (error) {
      print('AuthService: Error fetching role for $uid: $error');
    }
    return defaultRole;
  }

  /// Fetch the bus a Driver/Conductor is assigned to.
  Future<String> fetchBusId(String uid, {String defaultBusId = 'bus_01'}) async {
    try {
      final snap = await _db.child('users/$uid/busId').get();
      if (snap.exists && snap.value != null) {
        final val = snap.value.toString().trim();
        if (val.isNotEmpty) return val;
      }
    } catch (error) {
      print('AuthService: Error fetching busId for $uid: $error');
    }
    return defaultBusId;
  }

  /// Fetch user profile data.
  Future<Map<dynamic, dynamic>?> fetchUserProfile(String uid) async {
    try {
      final snapshot = await _db.child('users/$uid').get();
      if (snapshot.exists && snapshot.value is Map) {
        return Map<dynamic, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (error) {
      print('AuthService: Error fetching user profile: $error');
      return null;
    }
  }

  /// Re-persists a user's own already-known role/profile fields.
  Future<void> setUserRole(String uid, String role, {String? email, String? name}) async {
    try {
      final Map<String, dynamic> data = {'role': role};
      if (email != null) data['email'] = email;
      if (name != null) data['name'] = name;
      await _db.child('users/$uid').update(data);
    } catch (error) {
      print('AuthService: Error setting user role: $error');
    }
  }

  /// Creates a new user in Firebase Auth and provisions their profile in Realtime Database.
  Future<UserCredential> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
    String? busId,
    String? phone,
  }) async {
    final secondaryAppName =
        'AdminUserCreation_${DateTime.now().millisecondsSinceEpoch}';
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
        final Map<String, dynamic> profile = {
          'name': name.trim(),
          'email': email.trim(),
          'role': role,
          'createdAt': ServerValue.timestamp,
        };

        if ((role == 'Driver' || role == 'Conductor') &&
            busId != null &&
            busId.trim().isNotEmpty) {
          profile['busId'] = busId.trim();
        }

        if (phone != null && phone.trim().isNotEmpty) {
          profile['phone'] = phone.trim();
        }

        await _db.child('users/$newUid').set(profile);
      }

      return userCredential;
    } catch (error) {
      print('AuthService: Error creating user: $error');
      rethrow;
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  /// Lets the signed-in user update their own display name.
  Future<void> updateOwnName(String uid, String name) async {
    try {
      await _db.child('users/$uid').update({'name': name.trim()});
    } catch (error) {
      print('AuthService: Error updating name: $error');
      rethrow;
    }
  }

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (error) {
      print('AuthService: Error sending password reset: $error');
      rethrow;
    }
  }

  /// Delete a user account (Admin only).
  Future<void> deleteUser(String uid) async {
    try {
      // First delete the user profile from Realtime Database
      await _db.child('users/$uid').remove();
      // Note: Deleting Firebase Auth user requires admin SDK or re-authentication
      // This is a placeholder for future implementation
      print('AuthService: User profile deleted: $uid');
    } catch (error) {
      print('AuthService: Error deleting user: $error');
      rethrow;
    }
  }

  /// Check if email is already in use.
  Future<bool> isEmailInUse(String email) async {
    try {
      final snapshot = await _db
          .child('users')
          .orderByChild('email')
          .equalTo(email.trim())
          .get();
      return snapshot.exists && snapshot.value is Map;
    } catch (error) {
      print('AuthService: Error checking email: $error');
      return false;
    }
  }

  /// Get all users by role (Admin only).
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final List<Map<String, dynamic>> users = [];
      final snapshot = await _db.child('users').get();
      final data = snapshot.value;
      if (data is Map) {
        for (final entry in data.entries) {
          final userData = entry.value as Map?;
          if (userData != null && userData['role']?.toString() == role) {
            users.add({
              'uid': entry.key.toString(),
              ...Map<String, dynamic>.from(userData),
            });
          }
        }
      }
      return users;
    } catch (error) {
      print('AuthService: Error getting users by role: $error');
      return [];
    }
  }
}