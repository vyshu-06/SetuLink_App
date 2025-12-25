import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/referral_service.dart';
import 'package:flutter/services.dart'; // For clipboard

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  _ReferralScreenState createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralService _referralService = ReferralService();
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return Center(child: Text(tr('please_login_first')));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('refer_and_earn')),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _referralService.getUserStatsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(tr('error_loading_data')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) return Center(child: Text(tr('user_data_not_found')));

          final referralCode = userData['referralCode'] ?? 'N/A';
          final referralCount = userData['referralCount'] ?? 0;
          final loyaltyPoints = userData['loyaltyPoints'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset('assets/logos/logo.png', height: 100, errorBuilder: (_,__,___) => const Icon(Icons.card_giftcard, size: 100, color: Colors.teal)),
                const SizedBox(height: 20),
                Text(
                  tr('invite_friends_earn_rewards'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  tr('share_your_unique_code_with_friends'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal),
                  ),
                  child: Column(
                    children: [
                      Text(
                        tr('your_referral_code'),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        referralCode,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: Text(tr('copy_code')),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('code_copied_to_clipboard'))),
                          );
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: Text(tr('share_link')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _referralService.shareReferralCode(referralCode),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(tr('referrals'), referralCount.toString(), Icons.people),
                    _buildStatCard(tr('points'), loyaltyPoints.toString(), Icons.stars),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.orange),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
