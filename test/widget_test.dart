import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safecircle/screens/login_screen.dart';

void main() {
  testWidgets('login screen renders the expected welcome UI', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
