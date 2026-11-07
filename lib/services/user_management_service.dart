import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../models/managed_user_model.dart';

/// Client facade for admin user management.
///
/// Security model:
/// - This class only invokes HTTPS callables.
/// - It does NOT use the Firebase Admin SDK (impossible in the app binary).
/// - It does NOT write Auth custom claims or forge tokens.
/// - Privilege is decided solely by the server reading the caller's ID token
///   claim `role === "admin"` inside Cloud Functions (`requireAdmin`).
///
/// A modified APK that calls these endpoints without a real admin token still
/// receives `permission-denied`. UI flags like [RolePermissions.canManageUsers]
/// are cosmetic only.
class UserManagementService {
  UserManagementService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  void _log(String message) {
    if (kDebugMode) debugPrint('[UserManagementService] $message');
  }

  HttpsCallable _callable(String name) => _functions.httpsCallable(name);

  Future<List<ManagedUserModel>> listUsers({String? pageToken}) async {
    _log('listManagedUsers');
    final result = await _callable('listManagedUsers').call(<String, dynamic>{
      if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
      'limit': 100,
    });
    final data = Map<String, dynamic>.from(result.data as Map? ?? {});
    final raw = (data['users'] as List?) ?? const [];
    return raw
        .map(
          (e) => ManagedUserModel.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<ManagedUserModel> createUser({
    required String email,
    required String password,
    required String role,
    String? displayName,
  }) async {
    _log('createManagedUser');
    final result = await _callable('createManagedUser').call(<String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
      'role': role.trim().toLowerCase(),
      if (displayName != null && displayName.trim().isNotEmpty)
        'displayName': displayName.trim(),
    });
    final data = Map<String, dynamic>.from(result.data as Map? ?? {});
    return ManagedUserModel(
      uid: (data['uid'] ?? '').toString(),
      email: (data['email'] ?? email).toString(),
      displayName: displayName,
      role: (data['role'] ?? role).toString().toLowerCase(),
    );
  }

  Future<void> setRole({required String uid, required String role}) async {
    _log('setUserRole');
    await _callable('setUserRole').call(<String, dynamic>{
      'uid': uid,
      'role': role.trim().toLowerCase(),
    });
  }

  Future<void> updateUser({
    required String uid,
    required String email,
    required String displayName,
    required String role,
  }) async {
    _log('updateManagedUser');
    await _callable('updateManagedUser').call(<String, dynamic>{
      'uid': uid,
      'email': email.trim().toLowerCase(),
      'displayName': displayName.trim(),
      'role': role.trim().toLowerCase(),
    });
  }

  Future<void> disableUser({required String uid}) async {
    _log('disableManagedUser');
    await _callable('disableManagedUser').call(<String, dynamic>{
      'uid': uid,
    });
  }
}
