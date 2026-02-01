import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/admin_kyc_review_screen.dart';
import 'package:setulink_app/screens/admin_user_detail_screen.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('User Management')),
          bottom: TabBar(
            tabs: [
              Tab(text: tr('Craftizens')),
              Tab(text: tr('Citizens')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UserList(role: 'craftizen'),
            _UserList(role: 'citizen'),
          ],
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final String role;
  const _UserList({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text(tr('Error loading Users')));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;

        if (users.isEmpty) return Center(child: Text(tr('No users found')));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final userName = user['name'] ?? tr('Unknown');
            final isKycVerified = user['kyc']?['verified'] ?? false;
            final accountStatus = user['accountStatus'] ?? 'active';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: role == 'craftizen' ? Colors.deepOrange : Colors.teal,
                child: Icon(role == 'craftizen' ? Icons.handyman : Icons.person, color: Colors.white),
              ),
              title: Text(userName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email'] ?? user['phone'] ?? tr('No contact info')),
                  if (role == 'craftizen')
                    Text(
                      isKycVerified ? tr('KYC Verified') : tr('KYC Pending'),
                      style: TextStyle(
                        color: isKycVerified ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (accountStatus == 'suspended')
                    Text(tr('Suspended').toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminUserDetailScreen(userId: userId, userName: userName),
                  ),
                );
              },
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'verify_kyc') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminKycReviewScreen(userId: userId)));
                  } else if (value == 'suspend') {
                    _updateStatus(userId, 'suspended');
                  } else if (value == 'activate') {
                    _updateStatus(userId, 'active');
                  }
                },
                itemBuilder: (context) => [
                  if (role == 'craftizen' && !isKycVerified)
                    PopupMenuItem(value: 'verify_kyc', child: Text(tr('Review KYC'))),
                  if (accountStatus == 'active')
                    PopupMenuItem(value: 'suspend', child: Text(tr('Suspend Account'))),
                  if (accountStatus == 'suspended')
                    PopupMenuItem(value: 'activate', child: Text(tr('Activate Account'))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateStatus(String userId, String status) {
    FirebaseFirestore.instance.collection('users').doc(userId).update({'accountStatus': status});
  }
}
