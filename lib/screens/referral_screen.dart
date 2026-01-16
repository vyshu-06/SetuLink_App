import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/referral_service.dart';
import 'package:flutter/services.dart'; // For clipboard
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';

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
    if (userId.isEmpty) return const Center(child: BilingualText(textKey: 'please_login_first'));

    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'referral_code_optional'), // Using existing key or similar
        backgroundColor: AppColors.primaryColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _referralService.getUserStatsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: BilingualText(textKey: 'unexpected_error'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) return const Center(child: BilingualText(textKey: 'unexpected_error'));

          final referralCode = userData['referralCode'] ?? 'N/A';
          final referralCount = userData['referralCount'] ?? 0;
          final loyaltyPoints = userData['loyaltyPoints'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.card_giftcard, size: 100, color: AppColors.primaryColor),
                const SizedBox(height: 20),
                const BilingualText(
                  textKey: 'tagline', // Or another appropriate key
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: Column(
                    children: [
                      const BilingualText(
                        textKey: 'referral_code_optional',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        referralCode,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const BilingualText(textKey: 'complete'), // Placeholder for copy
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard')),
                          );
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const BilingualText(textKey: 'next'), // Placeholder for share
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    backgroundColor: AppColors.primaryColor,
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
                    _buildStatCard('Referrals', referralCount.toString(), Icons.people),
                    _buildStatCard('Points', loyaltyPoints.toString(), Icons.stars),
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
