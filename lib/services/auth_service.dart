import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../models/user_role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _log(String message) {
    if (kDebugMode) debugPrint('[AuthService] $message');
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    _log('Firebase email/password sign-in started.');
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _log('Firebase sign-in succeeded; refreshing ID token claims.');
      await cred.user?.getIdTokenResult(true);
      _log('ID token claims refresh completed.');
      return cred;
    } on FirebaseAuthException catch (error) {
      _log('Firebase sign-in failed (code: ${error.code}).');
      rethrow;
    } catch (error) {
      _log('Sign-in failed unexpectedly (${error.runtimeType}).');
      rethrow;
    }
  }

  /// Public self-registration is disabled for the admin app.
  /// Staff accounts must be created by an admin (Console or setUserRole CF).
  @Deprecated('Use admin-provisioned accounts only')
  Future<UserCredential> register(String email, String password) async {
    throw FirebaseAuthException(
      code: 'operation-not-allowed',
      message:
          'Self-registration is disabled. Ask an admin to create your account.',
    );
  }

  Future<void> signOut() async {
    _log('Firebase sign-out started.');
    try {
      await _auth.signOut();
      _log('Firebase sign-out completed.');
    } on FirebaseAuthException catch (error) {
      _log('Firebase sign-out failed (code: ${error.code}).');
      rethrow;
    } catch (error) {
      _log('Firebase sign-out failed (${error.runtimeType}).');
      rethrow;
    }
  }

  Future<UserRole> bootstrapAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      _log('bootstrapAdmin skipped: no signed-in user.');
      return UserRole.unknown;
    }

    _log('Calling bootstrapAdmin in us-central1.');
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('bootstrapAdmin')
          .call<void>();
      _log('bootstrapAdmin callable succeeded; refreshing ID token.');
      await user.getIdToken(true);
      _log('ID token refresh after bootstrapAdmin completed.');
      return fetchRole(forceRefresh: true);
    } on FirebaseFunctionsException catch (error) {
      _log('bootstrapAdmin callable failed (code: ${error.code}).');
      rethrow;
    } on FirebaseAuthException catch (error) {
      _log('Post-bootstrap token refresh failed (code: ${error.code}).');
      rethrow;
    } catch (error) {
      _log('bootstrapAdmin flow failed unexpectedly (${error.runtimeType}).');
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _log('Firebase password reset email request started.');
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _log('Firebase password reset email request completed.');
    } on FirebaseAuthException catch (error) {
      _log('Firebase password reset failed (code: ${error.code}).');
      rethrow;
    } catch (error) {
      _log('Firebase password reset failed (${error.runtimeType}).');
      rethrow;
    }
  }

  /// Reads `role` custom claim. Pass [forceRefresh] after an admin changes role.
  Future<UserRole> fetchRole({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _log('Role claim lookup skipped: no signed-in user.');
      return UserRole.unknown;
    }

    _log('Role claim lookup started (forceRefresh: $forceRefresh).');
    try {
      final token = await user.getIdTokenResult(forceRefresh);
      final role = UserRole.fromClaim(token.claims?['role']);
      _log('Role claim lookup completed (role: ${role.name}).');
      return role;
    } on FirebaseAuthException catch (error) {
      _log('Role claim lookup failed (code: ${error.code}).');
      rethrow;
    } catch (error) {
      _log('Role claim lookup failed unexpectedly (${error.runtimeType}).');
      rethrow;
    }
  }

  /// Reloads user + forces a new ID token (picks up new claims).
  Future<UserRole> refreshRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      _log('Role refresh skipped: no signed-in user.');
      return UserRole.unknown;
    }

    _log('Refreshing Firebase user and role claims.');
    try {
      await user.reload();
      return await fetchRole(forceRefresh: true);
    } on FirebaseAuthException catch (error) {
      _log('User or role refresh failed (Auth code: ${error.code}).');
      rethrow;
    } catch (error) {
      _log('User or role refresh failed (${error.runtimeType}).');
      rethrow;
    }
  }
}
