import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:setulink_app/screens/payment_screen.dart';
import 'package:setulink_app/screens/raise_dispute_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;

  const JobDetailScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('Not logged in'));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').doc(jobId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final job = JobModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
        final bool isCitizen = job.userId == currentUser.uid;
        final bool isCraftizen = job.assignedTo == currentUser.uid;

        return Scaffold(
          appBar: AppBar(title: Text(job.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDetailRow('Status', job.jobStatus.toUpperCase()),
              _buildDetailRow('Budget', '₹${job.budget}'),
              _buildDetailRow('Time', DateFormat('dd MMM, yyyy - hh:mm a').format(job.scheduledTime)),
              _buildDetailRow('Description', job.description),
              const SizedBox(height: 20),
              if (isCitizen) ..._buildCitizenActions(context, job),
              if (isCraftizen) ..._buildCraftizenActions(context, job),
              if (!isCitizen && !isCraftizen && job.jobStatus == 'open') ..._buildApplicantActions(context, job, currentUser.uid),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  List<Widget> _buildCitizenActions(BuildContext context, JobModel job) {
    return [
      if (job.jobStatus == 'completed')
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  jobId: job.id,
                  amount: job.budget,
                  craftizenId: job.assignedTo,
                  category: 'job_payment',
                ),
              ),
            );
          },
          child: const Text('Pay for Service'),
        ),
      if (job.jobStatus == 'paid') // Assuming a paid status
        ElevatedButton(onPressed: () { /* TODO: Navigate to Rating Screen */ }, child: const Text('Rate Craftizen')),

      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RaiseDisputeScreen(
            jobId: job.id,
            respondentId: job.assignedTo ?? '',
          )));
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        child: const Text('Raise Dispute'),
      ),
    ];
  }

  List<Widget> _buildCraftizenActions(BuildContext context, JobModel job) {
    return [
      if (job.jobStatus == 'confirmed' || job.jobStatus == 'in_progress')
        ElevatedButton(onPressed: () => _updateJobStatus(job.id, 'on_the_way'), child: const Text('On the Way')),
      if (job.jobStatus == 'on_the_way')
        ElevatedButton(onPressed: () => _updateJobStatus(job.id, 'started'), child: const Text('Start Work')),
      if (job.jobStatus == 'started')
        ElevatedButton(onPressed: () => _updateJobStatus(job.id, 'completed'), child: const Text('Mark as Completed')),
    ];
  }

  List<Widget> _buildApplicantActions(BuildContext context, JobModel job, String craftizenId) {
    return [
      ElevatedButton(onPressed: () => _applyForJob(job.id, craftizenId), child: const Text('Apply for this Job')),
    ];
  }

  void _updateJobStatus(String jobId, String status) {
    FirebaseFirestore.instance.collection('jobs').doc(jobId).update({'jobStatus': status});
  }

  void _applyForJob(String jobId, String craftizenId) {
    // In a real app, this would add to an 'applicants' subcollection or send a notification.
    // For now, we'll just assign the job directly for simplicity to complete the flow.
    FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
      'assignedTo': craftizenId,
      'jobStatus': 'confirmed', // Auto-confirm for demo
    });
  }
}
