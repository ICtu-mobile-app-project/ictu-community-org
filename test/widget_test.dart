import 'package:flutter_test/flutter_test.dart';

import 'package:ictu_community_org/main.dart';

void main() {
  testWidgets('Home screen shows ICTU Community branding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ICTU Community'), findsOneWidget);
    expect(
      find.text('Flutter + Dart project initialized successfully.'),
      findsOneWidget,
    );
  });
}
