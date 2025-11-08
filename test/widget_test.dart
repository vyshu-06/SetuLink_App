import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setulink_app/main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/screens/greeting_page.dart';

void main() {
  // Set up the environment for EasyLocalization
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('App smoke test - GreetingPage', (WidgetTester tester) async {
    // Provide the app with the necessary context from EasyLocalization and Provider
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        child: MultiProvider(
          providers: [
            Provider<AuthService>(create: (_) => AuthService()),
          ],
          child: const SetuLinkApp(),
        ),
      ),
    );

    // Let the widget tree build
    await tester.pumpAndSettle();

    // Verify that the GreetingPage is the initial route and is displayed
    expect(find.byType(GreetingPage), findsOneWidget);
  });
}
