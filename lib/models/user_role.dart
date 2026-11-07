/// App roles for RDX Admin.
///
/// Stored as Firebase Auth custom claim: `role` = `"admin"` | `"staff"`.
/// Claims are set only by Admin SDK / Cloud Functions — never by the client.
enum UserRole {
  admin,
  staff,
  unknown;

  static UserRole fromClaim(Object? value) {
    final s = (value ?? '').toString().trim().toLowerCase();
    switch (s) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.unknown;
    }
  }

  String get claimValue {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.staff:
        return 'staff';
      case UserRole.unknown:
        return '';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Staff';
      case UserRole.unknown:
        return 'Unknown';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isStaff => this == UserRole.staff;

  /// Any restaurant worker (admin or staff) allowed into the admin app.
  bool get isRestaurantUser => isAdmin || isStaff;
}
