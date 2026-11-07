import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/auth/role_permissions.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  void _log(String message) {
    if (kDebugMode) debugPrint('[AuthProvider] $message');
  }

  /// True as soon as any Firebase app has been initialized.
  static bool get _firebaseReady => Firebase.apps.isNotEmpty;

  AuthService? _service;
  bool _previewSignedOut = false;
  UserRole _role = UserRole.unknown;
  bool _roleLoading = false;
  bool _roleResolved = false;
  String? _roleLoadError;

  AuthService? get _safeService {
    if (!_firebaseReady) return null;
    return _service ??= AuthService();
  }

  User? get user => _safeService?.currentUser;
  bool get isLoggedIn => !_firebaseReady ? !_previewSignedOut : user != null;
  bool get isResolvingAccess =>
      _firebaseReady && user != null && !_roleResolved;
  bool get canAccessApp => !_firebaseReady
      ? isLoggedIn
      : user != null && _roleResolved && isRestaurantUser;

  UserRole get role => _role;
  bool get isAdmin => _role.isAdmin;
  bool get isStaff => _role.isStaff;
  bool get isRestaurantUser => _role.isRestaurantUser;
  bool get roleLoading => _roleLoading;

  RolePermissions get permissions => RolePermissions(_role);

  bool isLoading = false;
  String? errorMessage;

  AuthProvider() {
    final service = _safeService;
    if (service != null) {
      service.authStateChanges.listen((user) async {
        if (user == null) {
          _log('Firebase auth state changed: signed out.');
          _role = UserRole.unknown;
          _roleResolved = false;
          notifyListeners();
          return;
        }
        _log('Firebase auth state changed: signed in.');
        // signIn owns role verification while authenticating. Avoid a
        // duplicate claim fetch from the auth-state event.
        if (isLoading || _roleLoading || _roleResolved) return;
        await _loadRole();
      });
      // Initial load if already signed in.
      if (service.currentUser != null) {
        _loadRole();
      }
    }
  }

  Future<void> _loadRole() async {
    final service = _safeService;
    if (service == null) {
      _log('Using preview-mode role access (Firebase unavailable).');
      // Preview mode without Firebase → treat as admin so UI is fully visible.
      _role = UserRole.admin;
      _roleResolved = true;
      notifyListeners();
      return;
    }

    _roleLoading = true;
    _roleLoadError = null;
    _log('Starting account role verification.');
    notifyListeners();
    try {
      _role = await service.fetchRole(forceRefresh: true);
      _log('Account role verification completed (role: ${_role.name}).');
    } catch (error) {
      _log('Role verification failed (${error.runtimeType}).');
      _role = UserRole.unknown;
      _roleLoadError = error.toString();
    } finally {
      _roleResolved = true;
      _roleLoading = false;
      notifyListeners();
    }
  }

  /// Call after an admin changes your role claim so the app picks it up.
  Future<void> refreshRole() async {
    final service = _safeService;
    if (service == null) {
      _log('Role refresh skipped: Firebase is not initialized.');
      return;
    }
    _roleLoading = true;
    _log('Role refresh started.');
    notifyListeners();
    try {
      _role = await service.refreshRole();
      _log('Role refresh completed (role: ${_role.name}).');
    } catch (error) {
      _log('Role refresh failed (${error.runtimeType}).');
      rethrow;
    } finally {
      _roleResolved = true;
      _roleLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _log('Login flow started.');
    final service = _safeService;
    if (service == null) {
      _log('Login unavailable: Firebase is not initialized.');
      errorMessage = 'Firebase is not configured yet — running with mock data.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _log('Submitting credentials to Firebase Auth.');
      await service.signIn(email, password);
      _log('Firebase Auth accepted credentials; checking account role.');
      _previewSignedOut = false;
      await _loadRole();

      if (_role == UserRole.unknown && _roleLoadError == null) {
        _log('Role claim missing; attempting bootstrapAdmin.');
        try {
          _role = await service.bootstrapAdmin();
          _roleResolved = true;
          _log('bootstrapAdmin completed (role: ${_role.name}).');
        } on FirebaseFunctionsException catch (e) {
          if (e.code != 'permission-denied') rethrow;
          _log('bootstrapAdmin denied (code: ${e.code}).');
        }
      }

      // Only restaurant roles may use this app.
      if (!_role.isRestaurantUser) {
        final roleLoadError = _roleLoadError;
        if (roleLoadError != null) {
          _log('Login blocked: unable to verify account role.');
          errorMessage =
              'Signed in, but unable to verify your account role. Check your connection and try again. $roleLoadError';
          _log('Login stopped while role verification is unavailable.');
          isLoading = false;
          notifyListeners();
          return false;
        }

        _log('Login blocked: account role is not authorized.');
        _log('Signing out account without an authorized restaurant role.');
        await service.signOut();
        _role = UserRole.unknown;
        errorMessage =
            'This account is not authorized as an admin or staff member. Ask your restaurant admin to provision it.';
        _log('Login ended after unauthorized session was signed out.');
        isLoading = false;
        notifyListeners();
        return false;
      }

      _log('Login succeeded.');
      _log('Login processing finished.');
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _log('Login failed (Firebase Auth code: ${e.code}).');
      errorMessage = e.code == 'invalid-credential'
          ? 'Email or password is incorrect. Check your credentials or use Forgot password? If you still cannot sign in, ask your restaurant admin to verify that your staff account exists in Firebase Authentication.'
          : e.message ?? 'Login failed';
      _log('Login processing finished.');
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        _log('Login failed (Firebase Functions code: ${e.code}).');
      } else {
        _log('Login failed (${e.runtimeType}).');
      }
      errorMessage = e.toString();
      _log('Login processing finished.');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Self-registration is intentionally disabled.
  Future<bool> register(String email, String password) async {
    errorMessage =
        'Self-registration is disabled. Ask an admin to create your staff account.';
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    final service = _safeService;
    if (service == null) {
      _previewSignedOut = true;
    } else {
      await service.signOut();
    }
    _role = UserRole.unknown;
    _roleResolved = false;
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    _log('Password reset flow started.');
    final service = _safeService;

    if (service == null) {
      _log('Password reset unavailable: Firebase is not initialized.');
      errorMessage = 'Firebase is not configured yet — running with mock data.';
      notifyListeners();
      return false;
    }

    try {
      _log('Sending password reset request to Firebase Auth.');
      await service.sendPasswordReset(email);
      errorMessage = null;
      _log('Password reset request completed.');
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _log('Password reset failed (Firebase Auth code: ${e.code}).');
      errorMessage = e.message ?? 'Unable to send reset link.';
      notifyListeners();
      return false;
    } catch (e) {
      _log('Password reset failed (${e.runtimeType}).');
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

/// Riverpod provider wrapping [AuthProvider].
final authProvider = ChangeNotifierProvider<AuthProvider>(
  (ref) => AuthProvider(),
);
