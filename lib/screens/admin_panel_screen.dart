import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/screens/admin_kyc_review_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('KYC Pending Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'craftizen')
                .where('kyc.verified', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final pendingUsers = snapshot.data!.docs;

              if (pendingUsers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No pending KYC verifications'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingUsers.length,
                itemBuilder: (context, index) {
                  final user = pendingUsers[index];
                  final userData = user.data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text(userData['name'] ?? ''),
                    subtitle: Text(userData['email'] ?? ''),
                    trailing: ElevatedButton(
                      child: const Text('Review'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminKycReviewScreen(userId: user.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
