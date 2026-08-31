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

  /// Fetch the bus a Driver is assigned to from `/users/$uid/busId`.
  ///
  /// Bug #4 fix: Drivers are restricted (by Firebase Rules) to writing only
  /// their assigned bus, identified by this field. Falls back to
  /// [defaultBusId] if the user has no assignment yet or on error.
  Future<String> fetchBusId(String uid, {String defaultBusId = 'bus_01'}) async {
    try {
      final snap = await _db.child('users/$uid/busId').get();
      if (snap.exists && snap.value != null) {
        final val = snap.value.toString().trim();
        if (val.isNotEmpty) return val;
      }
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('Error fetching busId for $uid from RTDB: $e');
        return true;
      }());
    }
    return defaultBusId;
  }

  /// Re-persists a user's own already-known role/profile fields.
  ///
  /// Bug #5 fix: this intentionally does NOT let the caller promote a role
  /// out of thin air for an existing account — it's only ever called with a
  /// role that was just read back from `/users/$uid/role` (see
  /// LoginScreen). The actual authorization boundary lives in the Firebase
  /// Rules, which reject any write where a non-admin tries to change
  /// `role` to a value different from the value already stored.
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
  ///
  /// [busId] (Bug #4 fix, extended to Conductor): when provisioning a Driver
  /// or Conductor, the Admin assigns the bus that account is allowed to
  /// write within. This is stored on the user record and enforced
  /// server-side by the /buses/{busId} and /studentRosters/{busId} rules.
  ///
  /// [phone] is optional. Once set, it can only be changed by an Admin —
  /// see database.rules.json, which locks `phone` the same way `role` and
  /// `busId` are locked.
  Future<UserCredential> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
    String? busId,
    String? phone,
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
        final Map<String, dynamic> profile = {
          'name': name.trim(),
          'email': email.trim(),
          'role': role,
          'createdAt': ServerValue.timestamp,
        };
        // BUG FIX: previously this only checked `role == 'Driver'`, so a
        // Conductor's busId — even though the Admin form collected it —
        // was silently dropped and never written to the database.
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
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  /// Lets the signed-in user update their own display name.
  ///
  /// Deliberately narrow: only `name` is exposed here. `email` and `phone`
  /// are NOT editable by the user themselves — see database.rules.json,
  /// where those two fields are locked to "same value, or Admin only",
  /// mirroring the role/busId lock pattern. This method existing at all
  /// doesn't grant access by itself; the rules are the real boundary.
  Future<void> updateOwnName(String uid, String name) async {
    await _db.child('users/$uid').update({'name': name.trim()});
  }

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}