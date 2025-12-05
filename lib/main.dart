import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/analytics_service.dart';
import 'package:setulink_app/screens/citizen_home.dart';
import 'package:setulink_app/screens/craftizen_home.dart';
import 'package:setulink_app/screens/login_screen.dart';
import 'package:setulink_app/screens/register_screen.dart';
import 'package:setulink_app/screens/phone_auth_screen.dart';
import 'package:setulink_app/screens/greeting_page.dart';
import 'package:setulink_app/screens/splash_screen.dart';
import 'package:setulink_app/screens/kyc_screen.dart';
import 'package:setulink_app/screens/admin_kyc_review_screen.dart';
import 'package:setulink_app/screens/notifications_screen.dart';
import 'package:setulink_app/screens/payment_screen.dart';
import 'package:setulink_app/screens/subscription_plans_screen.dart';
import 'package:setulink_app/screens/subscription_screen.dart';
import 'package:setulink_app/screens/referral_screen.dart';
import 'package:setulink_app/screens/earnings_screen.dart'; 
import 'package:setulink_app/screens/admin_dashboard_screen.dart';
import 'package:setulink_app/screens/citizen_profile_setup_screen.dart';
import 'package:setulink_app/widgets/offline_banner.dart';
import 'firebase_options.dart';

final AnalyticsService analyticsService = AnalyticsService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {
    // FORCE use of these options for Web to bypass any potential weird file caching issues
    // The values are taken directly from your successful screenshot confirmation
    FirebaseOptions? platformOptions;
    if (kIsWeb) {
      platformOptions = const FirebaseOptions(
        apiKey: 'AIzaSyDywqDmqmNhotb3ikQW3KgzKd4rxrA3aCQ',
        appId: '1:60751051995:web:f43d66486004ff780060fe',
        messagingSenderId: '60751051995',
        projectId: 'setulink-app-fb',
        authDomain: 'setulink-app-fb.firebaseapp.com',
        storageBucket: 'setulink-app-fb.firebasestorage.app',
      );
    } else {
      platformOptions = DefaultFirebaseOptions.currentPlatform;
    }

    debugPrint('------------------------------------------------');
    debugPrint('FIREBASE INIT STARTING (HARDCODED CHECK)');
    debugPrint('Platform: ${kIsWeb ? "Web" : "Native"}');
    debugPrint('App ID: ${platformOptions.appId}');
    debugPrint('------------------------------------------------');
    
    await Firebase.initializeApp(
      options: platformOptions,
    );

    if (kIsWeb) {
      // Ensure we are using the standard Auth instance
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
    
    debugPrint('FIREBASE INIT SUCCESS');
  } catch (e) {
    debugPrint('FIREBASE INIT FAILED: $e');
  }
  
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('te')],
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
  const SetuLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SetuLink',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(primarySwatch: Colors.teal),
      navigatorObservers: [analyticsService.getAnalyticsObserver()],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return OfflineBanner(
          child: MediaQuery(
            data: media.copyWith(
                textScaler: TextScaler.linear(media.textScaler.scale(1).clamp(1.0, 1.3))),
            child: child!,
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/greeting': (context) => const GreetingPage(),
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
        '/admin': (context) => const AdminDashboardScreen(),
        '/kyc': (context) => const KYCScreen(),
        '/admin_kyc_review': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return AdminKycReviewScreen(userId: userId);
        },
        '/notifications': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return NotificationsScreen(userId: userId);
        },
        '/payment': (context) {
          final category = ModalRoute.of(context)!.settings.arguments as String;
          return PaymentScreen(category: category);
        },
        '/subscription_plans': (context) => SubscriptionPlansScreen(),
        '/subscription': (context) {
          final planId = ModalRoute.of(context)!.settings.arguments as String;
          return SubscriptionScreen(planId: planId);
        },
        '/referral': (context) => const ReferralScreen(),
        '/earnings': (context) => const EarningsScreen(),
        '/citizen_profile_setup': (context) => const CitizenProfileSetupScreen(),
      },
    );
  }
}
