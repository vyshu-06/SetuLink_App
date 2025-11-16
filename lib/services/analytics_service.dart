import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getAnalyticsObserver() => FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logLogin(String role) async {
    await _analytics.logLogin(loginMethod: role);
  }

  Future<void> logSignUp(String role) async {
    await _analytics.logSignUp(signUpMethod: role);
  }

  Future<void> logJobRequested(String serviceCategory) async {
    await _analytics.logEvent(
      name: 'job_requested',
      parameters: {'service_category': serviceCategory},
    );
  }

  Future<void> logJobCompleted(String jobId, int rating) async {
    await _analytics.logEvent(
      name: 'job_completed',
      parameters: {'job_id': jobId, 'rating': rating},
    );
  }
}
