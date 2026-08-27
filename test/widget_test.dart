import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbus_safe/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLoginSuccess: (role) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SchoolBus Safe'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
