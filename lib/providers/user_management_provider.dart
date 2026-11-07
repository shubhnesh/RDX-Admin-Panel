import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/managed_user_model.dart';
import '../services/user_management_service.dart';

class UserManagementProvider extends ChangeNotifier {
  UserManagementProvider({UserManagementService? service})
      : _service = service ?? UserManagementService();

  final UserManagementService _service;

  List<ManagedUserModel> users = [];
  bool isLoading = false;
  String? errorMessage;
  String _search = '';

  String get search => _search;

  List<ManagedUserModel> get filteredUsers {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users
        .where(
          (u) =>
              u.email.toLowerCase().contains(q) ||
              (u.displayName ?? '').toLowerCase().contains(q) ||
              u.roleLabel.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      users = await _service.listUsers();
      users.sort(
        (a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
      );
    } catch (e) {
      errorMessage = 'Failed to load users. $e';
      users = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String role,
    String? displayName,
  }) async {
    await _service.createUser(
      email: email,
      password: password,
      role: role,
      displayName: displayName,
    );
    await load();
  }

  Future<void> setRole({required String uid, required String role}) async {
    await _service.setRole(uid: uid, role: role);
    await load();
  }

  Future<void> updateUser({
    required String uid,
    required String email,
    required String displayName,
    required String role,
  }) async {
    await _service.updateUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
    );
    await load();
  }

  Future<void> disableUser({required String uid}) async {
    await _service.disableUser(uid: uid);
    await load();
  }
}

final userManagementProvider = ChangeNotifierProvider<UserManagementProvider>(
  (ref) => UserManagementProvider(),
);
