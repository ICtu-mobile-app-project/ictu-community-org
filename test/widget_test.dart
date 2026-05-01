import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ictu_community_org/app.dart';
import 'package:ictu_community_org/features/auth/controllers/auth_controller.dart';
import 'package:ictu_community_org/features/auth/screens/splash_screen.dart';
import 'package:ictu_community_org/features/auth/screens/welcome_screen.dart';

void main() {
  testWidgets('Splash transitions to welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>(
        create: (_) => AuthController(),
        child: const IctuCommunityApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Welcome to ICTU'), findsOneWidget);
    expect(find.text('GET STARTED'), findsOneWidget);
  });
}
