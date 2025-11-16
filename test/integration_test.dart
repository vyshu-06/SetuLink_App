import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:setulink_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full user registration and login flow', (WidgetTester tester) async {
    // Start the app
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5)); // Wait for splash screen

    // Greeting page: Tap the 'User' button
    final userButtonFinder = find.byWidgetPredicate(
      (widget) => widget is ElevatedButton && widget.child is Text && (widget.child as Text).data == 'User (వినియోగదారు)',
    );
    expect(userButtonFinder, findsOneWidget);
    await tester.tap(userButtonFinder);
    await tester.pumpAndSettle();

    // Login Screen: Tap 'Register Now'
    final registerLinkFinder = find.byWidgetPredicate(
      (widget) => widget is TextButton && widget.child is Text && (widget.child as Text).data == 'Register Now (ఇప్పుడే నమోదు చేసుకోండి)',
    );
    expect(registerLinkFinder, findsOneWidget);
    await tester.tap(registerLinkFinder);
    await tester.pumpAndSettle();

    // Register Screen: Fill the form
    await tester.enterText(find.byKey(const ValueKey('register_name')), 'Test User');
    await tester.enterText(find.byKey(const ValueKey('register_email')), 'testuser@example.com');
    await tester.enterText(find.byKey(const ValueKey('register_phone')), '9999999999');
    await tester.enterText(find.byKey(const ValueKey('register_password')), 'password123');
    await tester.enterText(find.byKey(const ValueKey('register_confirm')), 'password123');

    // Select the 'Citizen' role radio button
    final citizenRadioFinder = find.byWidgetPredicate(
      (widget) => widget is RadioMenuButton<String> && widget.child is Text && (widget.child as Text).data == 'User (వినియోగదారు)',
    );
    expect(citizenRadioFinder, findsOneWidget);
    await tester.tap(citizenRadioFinder);
    await tester.pumpAndSettle();

    // Tap the final register button
    final registerButtonFinder = find.byWidgetPredicate(
      (widget) => widget is ElevatedButton && widget.child is Text && (widget.child as Text).data == 'Register (నమోదు చేసుకోండి)',
    );
    expect(registerButtonFinder, findsOneWidget);
    await tester.tap(registerButtonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 2)); // Wait for navigation

    // Verify that we are on the Citizen Home screen
    expect(find.textContaining('Welcome'), findsOneWidget);
    expect(find.textContaining('What service'), findsOneWidget);
  });
}
