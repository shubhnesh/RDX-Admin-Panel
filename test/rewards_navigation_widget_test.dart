import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/screens/main/main_side_nav.dart';

void main() {
  testWidgets('Rewards is available in the existing admin navigation',
      (tester) async {
    String? navigatedRoute;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              MainSideNav(
                items: const [
                  SidebarItem(
                    label: 'Rewards',
                    icon: Icons.card_giftcard,
                    route: '/rewards',
                  ),
                ],
                currentRoute: '/dashboard',
                onNavigate: (route) => navigatedRoute = route,
                expanded: true,
                onToggleExpand: () {},
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rewards'), findsOneWidget);
    await tester.tap(find.text('Rewards'));

    expect(navigatedRoute, '/rewards');
  });
}
