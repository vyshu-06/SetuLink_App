import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/screens/citizen_home.dart';
import 'package:setulink_app/screens/craftizen_home.dart';
import 'package:setulink_app/screens/login_screen.dart';
import 'package:setulink_app/screens/register_screen.dart';
import 'package:setulink_app/screens/phone_auth_screen.dart';
import 'package:setulink_app/screens/greeting_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => AuthService()),
        ],
        child: const SetuLinkApp(),
      ),
    ),
  );
}

class SetuLinkApp extends StatelessWidget {
  const SetuLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SetuLink',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(primarySwatch: Colors.teal),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
              textScaler: TextScaler.linear(media.textScaler.scale(1).clamp(1.0, 1.3))),
          child: child!,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const GreetingPage(),
        '/login': (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String? ?? 'citizen';
          return LoginScreen(role: role);
        },
        '/register': (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String? ?? 'citizen';
          return RegisterScreen(role: role);
        },
        '/citizen_home': (context) => const CitizenHome(),
        '/craftizen_home': (context) => const CraftizenHome(),
        '/phone_auth': (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String? ?? 'citizen';
          return PhoneAuthScreen(role: role);
        },
      },
    );
  }
}
