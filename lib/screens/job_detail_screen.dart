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
import 'package:setulink_app/screens/job_tracking_screen.dart';

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
              _buildDetailRow('address', job.address),
              _buildDetailRow('amount', '₹${job.budget}'),
              _buildDetailRow('time', DateFormat('dd MMM, yyyy - hh:mm a').format(job.scheduledTime)),
              _buildDetailRow('description', job.description),
              const SizedBox(height: 16),
              if (job.assignedTo != null && isCitizen)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(job.assignedTo).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const BilingualText(textKey: 'assigned_craftizen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryColor)),
                              const SizedBox(height: 8),
                              _buildProfileDetail('name', userData['name'] ?? 'N/A'),
                              _buildProfileDetail('skills', (userData['skills'] as List<dynamic>?)?.join(', ') ?? 'N/A'),
                              if (userData['rating'] != null)
                                _buildProfileDetail('rating', userData['rating'].toString()),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              const SizedBox(height: 16),
              
              // Tracking Button for both Citizen and Craftizen
              if (job.jobStatus == 'confirmed' || job.jobStatus == 'on_the_way' || job.jobStatus == 'started')
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => JobTrackingScreen(job: job)),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: BilingualText(textKey: isCraftizen ? 'Navigate to House' : 'Track Craftizen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),

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

  Widget _buildProfileDetail(String labelKey, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          BilingualText(textKey: labelKey, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  List<Widget> _buildCitizenActions(BuildContext context, JobModel job) {
    final bool isRated = (job.preferences['rated'] ?? false) == true;

    return [
      if ((job.jobStatus == 'completed' || job.jobStatus == 'paid') && !isRated)
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
            child: const BilingualText(textKey: 'complete'),
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
        child: const BilingualText(textKey: 'raise_dispute'),
      ),
    ];
  }

  List<Widget> _buildCraftizenActions(BuildContext context, JobModel job) {
    return [
      if (job.jobStatus == 'confirmed')
        ElevatedButton(
          onPressed: () => _updateJobStatus(job.id, 'started'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const BilingualText(textKey: 'next'),
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
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _confirmJobAcceptance(context, job, craftizenId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const BilingualText(textKey: 'ACCEPT'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const BilingualText(textKey: 'DECLINE'),
            ),
          ),
        ],
      ),
    ];
  }

  void _confirmJobAcceptance(BuildContext context, JobModel job, String craftizenId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const BilingualText(textKey: 'Accept Job?'),
          content: const BilingualText(textKey: 'Are you sure you want to accept this job?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const BilingualText(textKey: 'No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _acceptJob(job, craftizenId);
              },
              child: const BilingualText(textKey: 'Yes'),
            ),
          ],
        );
      },
    );
  }

  void _acceptJob(JobModel job, String craftizenId) async {
    await FirebaseFirestore.instance.collection('jobs').doc(job.id).update({
      'assignedTo': craftizenId,
      'jobStatus': 'confirmed', 
    });

    // Notify the citizen
    await _notifyCitizen(job.userId, job.title);
  }

  Future<void> _notifyCitizen(String citizenId, String jobTitle) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': citizenId,
      'title': 'Job Accepted',
      'body': 'Your job "$jobTitle" has been accepted by a Craftizen.',
      'type': 'job_accepted',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  void _updateJobStatus(String jobId, String status) {
    FirebaseFirestore.instance.collection('jobs').doc(jobId).update({'jobStatus': status});
  }
}
