import 'package:rdx_admin/models/user_role.dart';

/// UI + client route guards derived from the Auth custom claim `role`.
///
/// This is NOT a security boundary. Every privileged write is enforced again
/// inside Cloud Functions via `requireAdmin` / `requireRestaurantUser`.
/// Tampering with this file or local state cannot grant real admin rights.
class RolePermissions {
  final UserRole role;

  const RolePermissions(this.role);

  bool get isAdmin => role.isAdmin;
  bool get isStaffRole => role.isStaff; // worker role only — not "all users"
  bool get isRestaurantUser => role.isRestaurantUser;

  // ── Navigation / screens ──────────────────────────────────────────────
  bool get canViewDashboard => isRestaurantUser;
  bool get canViewOrders => isRestaurantUser;
  bool get canViewMenu => isAdmin;
  bool get canViewCoupons => isAdmin;
  bool get canViewInventory => isRestaurantUser;
  bool get canViewSettings => isRestaurantUser;
  bool get canViewRewards => isAdmin;

  /// User management (list / create / change role / disable) — admin only.
  bool get canManageUsers => isAdmin;

  // ── Mutations (UI only; server re-checks) ─────────────────────────────
  bool get canCreateOrders => isRestaurantUser;
  bool get canEditSettings => isAdmin;
  bool get canEditMenu => isAdmin;
  bool get canEditCoupons => isAdmin;
  bool get canEditInventory => isAdmin;

  String get homeRoute {
    if (canViewDashboard) return '/dashboard';
    if (canViewOrders) return '/live-orders';
    if (canViewInventory) return '/inventory';
    if (canViewSettings) return '/settings';
    return '/dashboard';
  }

  Set<String> get allowedRoutes {
    final routes = <String>{};
    if (canViewDashboard) routes.add('/dashboard');
    if (canViewOrders) routes.add('/live-orders');
    if (canViewMenu) routes.add('/menu');
    if (canViewCoupons) routes.add('/coupons');
    if (canViewInventory) routes.add('/inventory');
    if (canViewSettings) routes.add('/settings');
    if (canViewRewards) routes.add('/rewards');
    if (canManageUsers) routes.add('/user-management');
    routes.add('/support');
    return routes;
  }
}
