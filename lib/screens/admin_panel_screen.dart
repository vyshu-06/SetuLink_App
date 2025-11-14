import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

// CONVERTED to a StatefulWidget for better state management and context handling.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ADDED: Method to show a confirmation dialog before destructive actions.
  Future<void> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(content),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(tr('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(tr('confirm'), style: const TextStyle(color: Colors.red)),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ENHANCED: Methods now handle errors and show feedback.
  void _toggleVerification(String userId, bool currentStatus) async {
    try {
      await _db.collection('users').doc(userId).update({'verified': !currentStatus});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
    }
  }

  void _deleteUser(BuildContext context, String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete user: $e")));
    }
  }

  void _deleteJob(BuildContext context, String jobId) async {
    try {
      await _db.collection('jobs').doc(jobId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job deleted successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete job: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin_panel')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(tr('manage_users')),
            _buildUserList(),
            const Divider(height: 32),
            _buildSectionHeader(tr('manage_jobs')),
            _buildJobList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').snapshots(),
      builder: (context, snapshot) {
        // ENHANCED: Handle loading, error, and empty states.
        if (snapshot.hasError) {
          return Center(child: Text(tr('error_loading_data')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data!.docs;
        if (users.isEmpty) {
          return Center(child: Text(tr('no_users_found')));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            return Card(
              child: ListTile(
                title: Text(user['name'] ?? 'No Name'),
                subtitle: Text('${user['role']} - ${user['email']}'),
                trailing: Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      icon: Icon(
                        user['verified'] == true ? Icons.verified : Icons.verified_outlined,
                        color: user['verified'] == true ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => _toggleVerification(userId, user['verified'] == true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showConfirmationDialog(
                        context: context,
                        title: tr('delete_user'),
                        content: tr('confirm_delete_user_message', args: [user['name'] ?? '']),
                        onConfirm: () => _deleteUser(context, userId),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildJobList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('jobs').snapshots(),
      builder: (context, snapshot) {
        // ENHANCED: Handle loading, error, and empty states.
        if (snapshot.hasError) {
          return Center(child: Text(tr('error_loading_data')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = snapshot.data!.docs;
        if (jobs.isEmpty) {
          return Center(child: Text(tr('no_jobs_found')));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index].data() as Map<String, dynamic>;
            final jobId = jobs[index].id;
            return Card(
              child: ListTile(
                title: Text('${job['serviceCategory']} - ${job['status']}'),
                subtitle: Text('${job['citizenId'] ?? ''} -> ${job['craftizenId'] ?? 'N/A'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showConfirmationDialog(
                    context: context,
                    title: tr('delete_job'),
                    content: tr('confirm_delete_job_message'),
                    onConfirm: () => _deleteJob(context, jobId),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
