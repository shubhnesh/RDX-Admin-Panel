import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/core/auth/role_permissions.dart';
import 'package:rdx_admin/models/user_role.dart';

void main() {
  test('notifications are available only to admins', () {
    final adminPermissions = RolePermissions(UserRole.admin);
    final staffPermissions = RolePermissions(UserRole.staff);

    expect(adminPermissions.canViewNotifications, isTrue);
    expect(adminPermissions.allowedRoutes, contains('/notifications'));
    expect(staffPermissions.canViewNotifications, isFalse);
    expect(staffPermissions.allowedRoutes, isNot(contains('/notifications')));
  });
}
