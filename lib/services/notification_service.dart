import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendKycVerificationNotification(String userId, bool approved) async {
    // Fetch FCM token for the user
    final userDoc = await _db.collection('users').doc(userId).get();
    final fcmToken = userDoc.data()?['fcmToken']; // Assuming the token is stored as fcmToken

    final message = approved
        ? 'Your KYC verification is approved. You can now accept jobs.'
        : 'Your KYC verification was rejected. Please contact support for details.';

    // Save notification in Firestore for in-app display
    await _db.collection('users').doc(userId).collection('notifications').add({
      'title': 'KYC Verification Status',
      'body': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // To send a push notification, you would typically call a backend function from here
    // that uses the fcmToken to send a message via Firebase Cloud Messaging.
    if (fcmToken != null) {
      print('FCM Token found. A backend function would be needed to send a push notification.');
    }
  }
}
