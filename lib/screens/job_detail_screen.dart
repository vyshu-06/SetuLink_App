import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:setulink_app/screens/payment_screen.dart';
import 'package:setulink_app/screens/raise_dispute_screen.dart';
import 'package:setulink_app/features/ratings_rewards/presentation/rating_screen.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;

  const JobDetailScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: BilingualText(textKey: 'log_in_to_see_bookings'));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').doc(jobId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) return const Center(child: CircularProgressIndicator());

        final job = JobModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
        final bool isCitizen = job.userId == currentUser.uid;
        final bool isCraftizen = job.assignedTo == currentUser.uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(job.title),
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDetailRow('status', job.jobStatus.toUpperCase()),
              _buildDetailRow('amount', '₹${job.budget}'),
              _buildDetailRow('time', DateFormat('dd MMM, yyyy - hh:mm a').format(job.scheduledTime)),
              _buildDetailRow('description', job.description),
              const SizedBox(height: 32),
              if (isCitizen) ..._buildCitizenActions(context, job),
              if (isCraftizen) ..._buildCraftizenActions(context, job),
              if (!isCitizen && !isCraftizen && job.jobStatus == 'open') ..._buildApplicantActions(context, job, currentUser.uid),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String labelKey, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BilingualText(textKey: labelKey, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const Divider(),
        ],
      ),
    );
  }

  List<Widget> _buildCitizenActions(BuildContext context, JobModel job) {
    final bool isRated = (job.preferences['rated'] ?? false) == true;

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
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const BilingualText(textKey: 'pay_now'),
        ),
      
      if (job.jobStatus == 'paid' && !isRated)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(jobId: job.id, craftizenId: job.assignedTo!),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50)
            ),
            child: const BilingualText(textKey: 'complete'), // Placeholder for Rate Experience
          ),
        ),

      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RaiseDisputeScreen(
            jobId: job.id,
            respondentId: job.assignedTo ?? '',
          )));
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          minimumSize: const Size(double.infinity, 50)
        ),
        child: const BilingualText(textKey: 'yes'), // Placeholder for Dispute
      ),
    ];
  }

  List<Widget> _buildCraftizenActions(BuildContext context, JobModel job) {
    return [
      if (job.jobStatus == 'confirmed')
        ElevatedButton(
          onPressed: () => _updateJobStatus(job.id, 'started'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const BilingualText(textKey: 'next'), // Placeholder for Start
        ),
      if (job.jobStatus == 'started')
        ElevatedButton(
          onPressed: () => _updateJobStatus(job.id, 'completed'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const BilingualText(textKey: 'complete'),
        ),
    ];
  }

  List<Widget> _buildApplicantActions(BuildContext context, JobModel job, String craftizenId) {
    return [
      ElevatedButton(
        onPressed: () => _applyForJob(job.id, craftizenId),
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        child: const BilingualText(textKey: 'next'), // Placeholder for Apply
      ),
    ];
  }

  void _updateJobStatus(String jobId, String status) {
    FirebaseFirestore.instance.collection('jobs').doc(jobId).update({'jobStatus': status});
  }

  void _applyForJob(String jobId, String craftizenId) {
    FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
      'assignedTo': craftizenId,
      'jobStatus': 'confirmed', 
    });
  }
}
