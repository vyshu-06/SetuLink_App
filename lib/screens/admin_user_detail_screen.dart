import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:intl/intl.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const AdminUserDetailScreen({Key? key, required this.userId, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${tr('user_details')}: $userName')),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              labelColor: Colors.blue,
              tabs: [
                Tab(text: tr('profile')),
                Tab(text: tr('jobs')),
                Tab(text: tr('disputes')),
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
            _infoRow(tr('email'), data['email']),
            _infoRow(tr('phone'), data['phone']),
            _infoRow(tr('role'), data['role']),
            _infoRow(tr('status'), data['accountStatus'] ?? tr('active')),
            _infoRow(tr('city'), data['city'] ?? 'N/A'),
            if (data['role'] == 'craftizen') ...[
              const Divider(),
              _infoRow(tr('kyc_verified'), data['kyc']?['verified'] == true ? tr('yes') : tr('no')),
              _infoRow(tr('skills'), (data['skills'] as List?)?.join(', ') ?? tr('none')),
              _infoRow(tr('rating'), data['rating']?.toStringAsFixed(1) ?? 'N/A'),
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
        
        if (jobs.isEmpty) return Center(child: Text(tr('no_jobs_found')));

        return ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = JobModel.fromMap(jobs[index].data() as Map<String, dynamic>, jobs[index].id);
            return ListTile(
              title: Text(job.title),
              subtitle: Text('${tr('status')}: ${job.jobStatus} | ${DateFormat('dd MMM').format(job.scheduledTime)}'),
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

        if (disputes.isEmpty) return Center(child: Text(tr('no_disputes_found')));

        return ListView.builder(
          itemCount: disputes.length,
          itemBuilder: (context, index) {
            final data = disputes[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text('${tr('dispute_on_job')} ${data['jobId'].substring(0,5)}...'),
              subtitle: Text('${tr('status')}: ${data['status']}'),
              trailing: Icon(Icons.circle, color: data['status'] == 'open' ? Colors.red : Colors.green, size: 12),
            );
          },
        );
      },
    );
  }
}
