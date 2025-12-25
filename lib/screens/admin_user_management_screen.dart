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
          title: Text(tr('user_management')),
          bottom: TabBar(
            tabs: [
              Tab(text: tr('craftizens')),
              Tab(text: tr('citizens')),
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
        if (snapshot.hasError) return Center(child: Text(tr('error_loading_users')));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;

        if (users.isEmpty) return Center(child: Text(tr('no_users_found')));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final userName = user['name'] ?? tr('unknown');
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
                  Text(user['email'] ?? user['phone'] ?? tr('no_contact_info')),
                  if (role == 'craftizen')
                    Text(
                      isKycVerified ? tr('kyc_verified') : tr('kyc_pending'),
                      style: TextStyle(
                        color: isKycVerified ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (accountStatus == 'suspended')
                    Text(tr('suspended').toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                    PopupMenuItem(value: 'verify_kyc', child: Text(tr('review_kyc'))),
                  if (accountStatus == 'active')
                    PopupMenuItem(value: 'suspend', child: Text(tr('suspend_account'))),
                  if (accountStatus == 'suspended')
                    PopupMenuItem(value: 'activate', child: Text(tr('activate_account'))),
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
