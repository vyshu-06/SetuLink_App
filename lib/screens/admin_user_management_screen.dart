import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          title: const Text('User Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Craftizens'),
              Tab(text: 'Citizens'),
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
        if (snapshot.hasError) return const Center(child: Text('Error loading users'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;

        if (users.isEmpty) return const Center(child: Text('No users found'));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            final userName = user['name'] ?? 'Unknown';
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
                  Text(user['email'] ?? user['phone'] ?? 'No contact info'),
                  if (role == 'craftizen')
                    Text(
                      isKycVerified ? 'KYC Verified' : 'KYC Pending',
                      style: TextStyle(
                        color: isKycVerified ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (accountStatus == 'suspended')
                    const Text('SUSPENDED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                    const PopupMenuItem(value: 'verify_kyc', child: Text('Review KYC')),
                  if (accountStatus == 'active')
                    const PopupMenuItem(value: 'suspend', child: Text('Suspend Account')),
                  if (accountStatus == 'suspended')
                    const PopupMenuItem(value: 'activate', child: Text('Activate Account')),
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
