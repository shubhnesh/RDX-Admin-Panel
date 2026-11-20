import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/core/auth/role_permissions.dart';
import 'package:rdx_admin/models/notification_model.dart';
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

  test('admin activity read state is tracked per admin', () {
    final notification = NotificationModel.fromJson({
      'id': 'event-1',
      'title': 'Payment completed',
      'message': 'Payment received for order 123.',
      'audience': 'admin',
      'category': 'payment',
      'source_id': '123',
      'read_by': ['admin-1'],
      'created_at': DateTime.utc(2026, 11, 20),
    });

    expect(notification.audience, NotificationAudience.admin);
    expect(notification.category, 'payment');
    expect(notification.sourceId, '123');
    expect(notification.isReadBy('admin-1'), isTrue);
    expect(notification.isReadBy('admin-2'), isFalse);
    expect(notification.withReadBy('admin-2').isReadBy('admin-2'), isTrue);
  });

  test('admin history excludes customer-only automatic notifications', () {
    final customerStatus = NotificationModel.fromJson({
      'id': 'customer-status-1',
      'title': 'Order Preparing',
      'message': 'Order 123 is now preparing.',
      'audience': 'allApp',
      'source': 'automatic',
      'created_at': DateTime.utc(2026, 11, 20),
    });
    final adminOrder = NotificationModel.fromJson({
      'id': 'admin-order-1',
      'title': 'Order placed successfully',
      'message': 'A customer placed order 123.',
      'audience': 'admin',
      'source': 'automatic',
      'created_at': DateTime.utc(2026, 11, 20),
    });
    final adminBroadcast = NotificationModel.fromJson({
      'id': 'broadcast-1',
      'title': 'Announcement',
      'message': 'A restaurant update.',
      'audience': 'allApp',
      'source': 'admin',
      'created_at': DateTime.utc(2026, 11, 20),
    });

    expect(customerStatus.shouldShowInAdminHistory, isFalse);
    expect(adminOrder.shouldShowInAdminHistory, isTrue);
    expect(adminBroadcast.shouldShowInAdminHistory, isTrue);
  });
}
