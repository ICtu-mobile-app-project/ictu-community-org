import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ictu_community_org/features/auth/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen is scroll-safe on small screens (no clipping)', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 568); // iPhone SE-ish
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // On small screens the content may need scrolling, but must not overflow.
    expect(find.byType(Scrollable), findsOneWidget);

    await tester.ensureVisible(find.text('GET STARTED'));
    await tester.pumpAndSettle();
    expect(find.text('GET STARTED'), findsOneWidget);

    await tester.ensureVisible(find.text('New here? Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('New here? Create Account'), findsOneWidget);

    // Switch to Staff tab and ensure the alternate crossfade content shows.
    await tester.ensureVisible(find.text('STAFF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('STAFF'));
    await tester.pumpAndSettle();

    expect(find.text('Direct communication'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}

