import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbus_safe/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onLoginSuccess: (role) {})),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart School Bus'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Enter moves from email to password', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.tap(fields.first);
    await tester.enterText(fields.first, 'parent@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(tester.widget<TextField>(fields.at(1)).focusNode?.hasFocus, isTrue);
  });
}
