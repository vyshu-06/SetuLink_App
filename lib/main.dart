// Filename: lib/main.dart
// ✅ Corrected and working version for SetuLink (Firebase + Localization + Auto-login)

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Corrected imports according to your folder structure
import 'screens/greeting_page.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/phone_auth_screen.dart';
import 'features/home/presentation/citizen_home.dart';
import 'features/home/presentation/craftizen_home.dart';

import 'services/auth_service.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM (optional)
  try {
    await FCMService.initialize();
  } catch (e) {
    debugPrint('⚠️ FCM initialization failed: $e');
  }

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

  static final Map<String, WidgetBuilder> appRoutes = {
    '/': (context) => const GreetingPage(),
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/citizen_home': (context) => const CitizenHome(),
    '/craftizen_home': (context) => const CraftizenHome(),
    '/phone_auth': (context) => const PhoneAuthScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SetuLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0.5),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const RootDecider(),
      routes: appRoutes,
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('setulink'.tr())),
          body: Center(child: Text('route_not_found'.tr(args: [settings.name ?? '']))),
        ),
      ),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaleFactor: media.textScaleFactor.clamp(1.0, 1.3)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class RootDecider extends StatefulWidget {
  const RootDecider({Key? key}) : super(key: key);

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider> {
  bool _loading = true;
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedRole = prefs.getString('role');
      final autoLogin = prefs.getBool('auto_login') ?? false;
      final user = FirebaseAuth.instance.currentUser;

      String route = '/';

      if (user != null && autoLogin && storedRole != null) {
        route = storedRole == 'citizen'
            ? '/citizen_home'
            : storedRole == 'craftizen'
            ? '/craftizen_home'
            : '/';
      } else if (user == null && autoLogin) {
        route = '/login';
      }

      setState(() {
        _initialRoute = route;
        _loading = false;
      });
    } catch (e) {
      debugPrint('RootDecider error: $e');
      setState(() {
        _initialRoute = '/';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text('loading'.tr()),
            ],
          ),
        ),
      );
    }

    switch (_initialRoute) {
      case '/citizen_home':
        return const izenHome();
      case '/craftizen_home':
        return const ftizenHome();
      case '/login':
        return const LoginScreen();
      default:
        return const GreetingPage();
    }
  }
}
