import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signing out in preview mode returns the app to logged-out state',
      () async {
    final auth = AuthProvider();

    expect(auth.isLoggedIn, isTrue);

    await auth.signOut();

    expect(auth.isLoggedIn, isFalse);
  });
}
