import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/models/notification_model.dart';
import 'package:rdx_admin/widgets/notification_details_dialog.dart';

void main() {
  final notification = NotificationModel(
    id: 'order-1',
    title: 'Order placed successfully',
    message:
        'Shubhnesh placed order ORD-20261120-1234567890. Total: Rs. 134.00.',
    audience: NotificationAudience.admin,
    createdAt: DateTime.utc(2026, 11, 20, 18, 30),
    category: 'order',
    sourceId: 'ORD-20261120-1234567890',
  );

  testWidgets('notification details fit a phone-sized viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationDetailsDialog(notification: notification),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(notification.title), findsOneWidget);
    expect(find.text(notification.sourceId!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification details fit a desktop-sized viewport',
      (tester) async {
    tester.view.physicalSize = const Size(1366, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationDetailsDialog(notification: notification),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(notification.title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
