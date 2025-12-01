import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/models/dispute_model.dart';
import 'package:intl/intl.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const AdminUserDetailScreen({Key? key, required this.userId, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Details: $userName')),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.blue,
              tabs: [
                Tab(text: 'Profile'),
                Tab(text: 'Jobs'),
                Tab(text: 'Disputes'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ProfileTab(userId: userId),
                  _JobsTab(userId: userId),
                  _DisputesTab(userId: userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final String userId;
  const _ProfileTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data() as Map<String, dynamic>;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _infoRow('Email', data['email']),
            _infoRow('Phone', data['phone']),
            _infoRow('Role', data['role']),
            _infoRow('Status', data['accountStatus'] ?? 'Active'),
            _infoRow('City', data['city'] ?? 'N/A'),
            if (data['role'] == 'craftizen') ...[
              const Divider(),
              _infoRow('KYC Verified', data['kyc']?['verified'] == true ? 'Yes' : 'No'),
              _infoRow('Skills', (data['skills'] as List?)?.join(', ') ?? 'None'),
              _infoRow('Rating', data['rating']?.toStringAsFixed(1) ?? 'N/A'),
            ]
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
}

class _JobsTab extends StatelessWidget {
  final String userId;
  const _JobsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    // Query jobs where user is creator OR assignee
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs')
          .where('userId', isEqualTo: userId) // OR assignedTo, but firestore simple query limitations apply
          .snapshots(),
          // Note: Ideally perform two queries or one composite if possible. For simplicity, showing Created jobs.
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final jobs = snapshot.data!.docs;
        
        if (jobs.isEmpty) return const Center(child: Text('No jobs found'));

        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = JobModel.fromMap(jobs[index].data() as Map<String, dynamic>, jobs[index].id);
            return ListTile(
              title: Text(job.title),
              subtitle: Text('Status: ${job.jobStatus} | ${DateFormat('dd MMM').format(job.scheduledTime)}'),
              trailing: Text('₹${job.budget}'),
            );
          },
        );
      },
    );
  }
}

class _DisputesTab extends StatelessWidget {
  final String userId;
  const _DisputesTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('disputes')
          .where('raisedBy', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final disputes = snapshot.data!.docs;

        if (disputes.isEmpty) return const Center(child: Text('No disputes found'));

        return ListView.builder(
          itemCount: disputes.length,
          itemBuilder: (context, index) {
            final data = disputes[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text('Dispute on Job ${data['jobId'].substring(0,5)}...'),
              subtitle: Text('Status: ${data['status']}'),
              trailing: Icon(Icons.circle, color: data['status'] == 'open' ? Colors.red : Colors.green, size: 12),
            );
          },
        );
      },
    );
  }
}
