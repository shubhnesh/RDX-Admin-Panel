/// One restaurant app account as returned by the admin list callable.
///
/// Roles are Auth custom claims only: `role` = `"admin"` | `"staff"`.
/// - admin  → full management
/// - staff  → day-to-day worker (lower section) — NOT a bucket for all users
///
/// The Flutter client never writes claims; only Cloud Functions (Admin SDK) do.
class ManagedUserModel {
  final String uid;
  final String email;
  final String? displayName;

  /// Auth claim value: `"admin"` or `"staff"`.
  final String role;
  final bool disabled;
  final DateTime? createdAt;

  const ManagedUserModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    this.disabled = false,
    this.createdAt,
  });

  bool get isAdminRole => role.toLowerCase() == 'admin';
  bool get isStaffRole => role.toLowerCase() == 'staff';

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Staff';
      default:
        return role;
    }
  }

  factory ManagedUserModel.fromMap(Map<String, dynamic> map) {
    DateTime? created;
    final raw = map['created_at'] ?? map['createdAt'];
    if (raw is String) {
      created = DateTime.tryParse(raw);
    } else if (raw is int) {
      created = DateTime.fromMillisecondsSinceEpoch(raw);
    }

    return ManagedUserModel(
      uid: (map['uid'] ?? map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      displayName: map['display_name']?.toString() ??
          map['displayName']?.toString(),
      role: (map['role'] ?? 'staff').toString().toLowerCase(),
      disabled: map['disabled'] == true,
      createdAt: created,
    );
  }

  ManagedUserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    bool? disabled,
    DateTime? createdAt,
  }) {
    return ManagedUserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      disabled: disabled ?? this.disabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
