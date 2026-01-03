import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/analytics_service.dart';
import 'package:setulink_app/screens/citizen_home.dart';
import 'package:setulink_app/screens/craftizen_home.dart';
import 'package:setulink_app/screens/login_screen.dart';
import 'package:setulink_app/screens/register_screen.dart';
import 'package:setulink_app/screens/citizen_register_screen.dart';
import 'package:setulink_app/screens/craftizen_register_screen.dart';
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
import 'package:setulink_app/screens/craftizen_experience_screen.dart';
import 'package:setulink_app/screens/pending_verification_screen.dart'; // Import the new screen
import 'package:setulink_app/theme/app_theme.dart';
import 'firebase_options.dart';

final AnalyticsService analyticsService = AnalyticsService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } else {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    }

    debugPrint('FIREBASE INIT SUCCESS');
  } catch (e) {
    debugPrint('FIREBASE INIT FAILED: $e');
  }

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
      theme: AppTheme.lightTheme,
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
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/citizen_register': (context) => const CitizenRegisterScreen(),
        '/craftizen_register': (context) => const CraftizenRegisterScreen(),
        '/citizen_home': (context) => const CitizenHome(),
        '/craftizen_home': (context) => const CraftizenHome(),
        '/phone_auth': (context) => const PhoneAuthScreen(role: 'citizen'),
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
        '/craftizen_experience': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return CraftizenExperienceScreen(userId: args['userId']!, selectedSkills: args['selectedSkills']! as List<String>);
        },
        // ADDED: Route for the Pending Verification Screen
        '/pending_verification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
          return PendingVerificationScreen(
            userId: args['userId'] as String? ?? '',
            commonAnswers: (args['commonAnswers'] as Map<dynamic, dynamic>?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
            passedSkills: (args['passedSkills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
            videoUrls: (args['videoUrls'] as Map<dynamic, dynamic>?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
          );
        },
      },
    );
  }
}
