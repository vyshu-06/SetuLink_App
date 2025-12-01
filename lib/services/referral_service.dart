import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class ReferralService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Share referral code
  Future<void> shareReferralCode(String referralCode) async {
    // In a real app, this link would be a Firebase Dynamic Link
    final String message = 
        'Join SetuLink using my referral code: $referralCode and earn rewards! '
        'Download the app: https://setulink.app/download';
    
    await Share.share(message, subject: 'Join SetuLink!');
  }

  // Get referral stats for a user
  Stream<DocumentSnapshot> getUserStatsStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // Get list of referred users (optional, if we store this relationship in a subcollection or query)
  // For MVP, we rely on the aggregate count in user doc.
}
