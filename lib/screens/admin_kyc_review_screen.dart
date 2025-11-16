import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/services/notification_service.dart';

class AdminKycReviewScreen extends StatefulWidget {
  final String userId;
  const AdminKycReviewScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<AdminKycReviewScreen> createState() => _AdminKycReviewScreenState();
}

class _AdminKycReviewScreenState extends State<AdminKycReviewScreen> {
  final NotificationService _notificationService = NotificationService();
  String? _rejectionReason;

  void _updateVerification(bool approved) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    await userRef.update({
      'kyc.verified': approved,
      'kyc.reviewedAt': FieldValue.serverTimestamp(),
      'kyc.rejectionReason': approved ? null : _rejectionReason,
    });

    await _notificationService.sendKycVerificationNotification(widget.userId, approved);
  }

  @override
  Widget build(BuildContext context) {
    final userDocStream = FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('KYC Review')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDocStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final kyc = data['kyc'] ?? {};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text('Questionnaire Answers:', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(kyc['questionnaire']?.toString() ?? 'N/A'),
                const SizedBox(height: 16),
                Text('Skill Demo Video:', style: Theme.of(context).textTheme.titleLarge),
                if (kyc['videoUrl'] != null)
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement video player
                    },
                    child: Text(kyc['videoUrl'], style: const TextStyle(color: Colors.blue)),
                  )
                else
                  const Text('No video uploaded'),
                const SizedBox(height: 16),
                Text('Aadhaar Document:', style: Theme.of(context).textTheme.titleLarge),
                if (kyc['aadharUrl'] != null)
                  GestureDetector(
                    onTap: () {
                      // TODO: Open document in browser or in-app PDF viewer
                    },
                    child: Text(kyc['aadharUrl'], style: const TextStyle(color: Colors.blue)),
                  )
                else
                  const Text('Not uploaded'),
                const SizedBox(height: 16),
                Text('Passport Document:', style: Theme.of(context).textTheme.titleLarge),
                if (kyc['passportUrl'] != null)
                  GestureDetector(
                    onTap: () {
                      // TODO: Open document
                    },
                    child: Text(kyc['passportUrl'], style: const TextStyle(color: Colors.blue)),
                  )
                else
                  const Text('Not uploaded'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (val) {
                    _rejectionReason = val;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Approve'),
                        onPressed: () {
                          _updateVerification(true);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Reject'),
                        onPressed: () {
                          _updateVerification(false);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
