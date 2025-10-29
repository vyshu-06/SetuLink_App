// Filename: lib/main.dart
// Full professional main.dart for SetuLink (Option B + Auto-Login enabled)
//
// Features included:
// - Firebase initialization
// - EasyLocalization initialization
// - Provider-based AuthService injection

// - Named routes for all screens
// - Clean theme and small accessibility tweaks
// - RootDecider widget to decide where to send the user on startup

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/greeting_page.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/citizen_home.dart';
import 'screens/craftizen_home.dart';
import 'screens/phone_auth_screen.dart';

import 'services/auth_service.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Initialize EasyLocalization (loads translations)
  await EasyLocalization.ensureInitialized();

  // 2) Initialize Firebase
  await Firebase.initializeApp();

  // 3) Initialize FCM (notifications). This is safe if FCMService handles platform checks.
  // If you don't have fcm_service.dart yet, remove the call below.
  try {
    await FCMService.initialize();
  } catch (e) {
    // If FCM fails to init (e.g., missing setup), don't crash the app here.
    // In production you might log this to a monitoring service.
    debugPrint('FCM initialization failed: $e');
  }

  // 4) Provide AuthService globally using Provider
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

  // Named routes - central place to manage navigation across the app.
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
      // Localization integration
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Instead of using home: we use a RootDecider to determine where to go (auto-login logic)
      home: const RootDecider(),

      routes: appRoutes,

      // Fallback route: friendly 404 page
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('setulink'.tr())),
          body: Center(child: Text('route_not_found'.tr(args: [settings.name ?? '']))),
        ),
      ),

      // Accessibility: clamp text scaling so layout doesn't break on extreme device settings
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

/// RootDecider:
/// - Checks SharedPreferences for stored role and auto-login flag
/// - Checks FirebaseAuth.currentUser for authenticated session
/// - Decides whether to show GreetingPage, CitizenHome, CraftizenHome or Login
class RootDecider extends StatefulWidget {
  const RootDecider({Key? key}) : super(key: key);

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider> {
  bool _loading = true;
  String? _initialRoute; // one of '/', '/citizen_home', '/craftizen_home', '/login'

  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    try {
      // 1) Check shared preferences for stored role & auto-login flag
      final prefs = await SharedPreferences.getInstance();
      final storedRole = prefs.getString('role'); // 'citizen' or 'craftizen'
      final autoLogin = prefs.getBool('auto_login') ?? false;

      // 2) Check FirebaseAuth current user
      final user = FirebaseAuth.instance.currentUser;

      // Decide:
      // - If user is signed-in (Firebase) AND autoLogin true => go to role home if role present
      // - If user is signed-in but no role in prefs => fetch role from Firestore later; for now go to greeting
      // - If no Firebase user but role present and autoLogin true => still show login for that role
      String route = '/'; // default: greeting page

      if (user != null && autoLogin && storedRole != null) {
        if (storedRole == 'citizen') {
          route = '/citizen_home';
        } else if (storedRole == 'craftizen') {
          route = '/craftizen_home';
        } else {
          route = '/';
        }
      } else if (user != null && autoLogin && storedRole == null) {
        // Firebase user but no stored role: try to read role from Firestore via AuthService (optional)
        // For now, fallback to greeting so user can re-select (or we can extend here to fetch role).
        route = '/';
      } else if (user == null && storedRole != null && autoLogin) {
        // User chose auto-login but is not authenticated anymore; route to login screen with role argument
        route = '/login';
      } else {
        // Default: show greeting page
        route = '/';
      }

      // Save decision to state and render
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
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('loading'.tr()),
          ],
        )),
      );
    }

    // If initialRoute is '/', return GreetingPage directly
    if (_initialRoute == '/' || _initialRoute == null) {
      return const GreetingPage();
    }

    // If initialRoute is '/login' we want to pass stored role (so login screen shows correct hint)
    if (_initialRoute == '/login') {
      return Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (context) {
            // Grab role from prefs to forward as argument
            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snap) {
                if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                final role = snap.data!.getString('role');
                return LoginScreen(role: role);
              },
            );
          },
        ),
      );
    }

    // For home routes we simply return the corresponding home widget
    if (_initialRoute == '/citizen_home') {
      return const CitizenHome();
    } else if (_initialRoute == '/craftizen_home') {
      return const CraftizenHome();
    }

    // Fallback
    return const GreetingPage();
  }
}
