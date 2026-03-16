import 'package:flutter_test/flutter_test.dart';

import 'package:ictu_community_org/main.dart';

void main() {
  testWidgets('Splash transitions to welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Welcome to ICTU Community'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
