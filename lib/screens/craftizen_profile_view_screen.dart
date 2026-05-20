import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/models/craftizen_model.dart';
import 'package:setulink_app/screens/chat_screen.dart';
import 'package:setulink_app/screens/job_request_screen.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:intl/intl.dart';

class CraftizenProfileViewScreen extends StatefulWidget {
  final String craftizenId;

  const CraftizenProfileViewScreen({Key? key, required this.craftizenId}) : super(key: key);

  @override
  State<CraftizenProfileViewScreen> createState() => _CraftizenProfileViewScreenState();
}

class _CraftizenProfileViewScreenState extends State<CraftizenProfileViewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0 ? '${userId1}_$userId2' : '${userId2}_$userId1';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.craftizenId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const Scaffold(body: Center(child: BilingualText(textKey: 'No Jobs available')));

        final craftizen = CraftizenModel.fromMap(data, snapshot.data!.id);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(craftizen.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.accentColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 57,
                              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                              child: Text(craftizen.name[0], style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            craftizen.name,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: AppColors.accentColor, size: 20),
                                Text(' ${craftizen.rating.toStringAsFixed(1)} ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const BilingualText(textKey: 'Rating', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                                Text(' ${data['ratingCount'] ?? 0} ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const BilingualText(textKey: 'Jobs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionCard(
                          titleKey: 'my_skills',
                          content: Wrap(
                            spacing: 8,
                            children: craftizen.skills.map((s) => Chip(
                              label: BilingualText(textKey: s),
                              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          titleKey: 'about',
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(craftizen.bio ?? tr('No bio available'), style: const TextStyle(fontSize: 16, height: 1.5)),
                              const SizedBox(height: 16),
                              _buildProfileDetailRow(Icons.email, 'email', craftizen.email),
                              _buildProfileDetailRow(Icons.history, 'experience', '${craftizen.experienceLevel ?? "N/A"} years'),
                              _buildProfileDetailRow(Icons.map, 'service_radius', '${craftizen.travelRadius ?? "N/A"}'),
                              _buildProfileDetailRow(Icons.payments, 'min_charge', '₹${craftizen.minCharge.toStringAsFixed(0)}'),
                              _buildProfileDetailRow(Icons.verified, 'certified', craftizen.isCertified ? tr('yes') : tr('no')),
                              _buildProfileDetailRow(Icons.location_city, 'city', craftizen.city ?? 'N/A'),
                              if (craftizen.createdAt != null)
                                _buildProfileDetailRow(Icons.calendar_today, 'joined', DateFormat('MMM yyyy').format(craftizen.createdAt!)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (craftizen.commonAnswers.isNotEmpty || craftizen.isKycVerified)
                          _buildSectionCard(
                            titleKey: 'Verification',
                            content: Column(
                              children: [
                                if (craftizen.isKycVerified)
                                  _buildTrustItem(Icons.verified_user, 'KYC Verified', Colors.green),
                                if (craftizen.commonAnswers['question_1'] == 'yes')
                                  _buildTrustItem(Icons.security, 'Background Check Willing', Colors.blue),
                                if (craftizen.commonAnswers['question_2'] == 'yes')
                                  _buildTrustItem(Icons.handyman, 'Owns Professional Tools', Colors.orange),
                                if (craftizen.commonAnswers['question_3'] == 'yes')
                                  _buildTrustItem(Icons.event_available, 'Available Weekends', Colors.purple),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (craftizen.videoUrls.isNotEmpty)
                          _buildSectionCard(
                            titleKey: 'Demo Video',
                            content: Column(
                              children: craftizen.videoUrls.entries.map((entry) => ListTile(
                                leading: const Icon(Icons.play_circle_fill, color: AppColors.primaryColor, size: 30),
                                title: BilingualText(textKey: entry.key),
                                subtitle: const Text('Demo of skill expertise'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () {
                                  // In a real app, open a video player
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playing video...')));
                                },
                              )).toList(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildReviewsSection(),
                        const SizedBox(height: 100), 
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      if (currentUserId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to chat')));
                        return;
                      }
                      final chatId = _getChatId(currentUserId, widget.craftizenId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chatId,
                            otherUserName: craftizen.name,
                          )
                        )
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const BilingualText(textKey: 'Chats', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const JobRequestScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const BilingualText(textKey: 'Next', style: TextStyle(fontWeight: FontWeight.bold)), // Request Job
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({required String titleKey, required Widget content}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualText(textKey: titleKey, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
            const Divider(),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          const Spacer(),
          Icon(Icons.check_circle, color: color.withValues(alpha: 0.8), size: 16),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String labelKey, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                BilingualText(textKey: labelKey, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                const Text(': ', style: TextStyle(color: Colors.grey)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('craftizenId', isEqualTo: widget.craftizenId)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final reviews = snapshot.data!.docs;

        return _buildSectionCard(
          titleKey: 'notification', // Reviews
          content: reviews.isEmpty
              ? const Center(child: BilingualText(textKey: 'No notifications'))
              : Column(
                  children: reviews.map((doc) {
                    final review = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          ...List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < (review['rating'] ?? 0) ? Colors.amber : Colors.grey)),
                          const Spacer(),
                          Text(
                            review['timestamp'] != null ? DateFormat('MMM dd').format((review['timestamp'] as Timestamp).toDate()) : '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      subtitle: Text(review['comment'] ?? '', style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}
