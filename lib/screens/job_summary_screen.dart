import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class JobSummaryScreen extends StatefulWidget {
  final String jobId;

  const JobSummaryScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  State<JobSummaryScreen> createState() => _JobSummaryScreenState();
}

class _JobSummaryScreenState extends State<JobSummaryScreen> {
  double _rating = 0;
  bool _isSaving = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "$hours:$minutes hrs";
  }

  void _handleDone() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'citizenRating': _rating,
        'status': 'finalized',
      });
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/craftizen_home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'Job Summary'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final job = JobModel.fromMap(data, snapshot.data!.id);
          
          final startTime = data['startTime'] as Timestamp?;
          final endTime = data['endTime'] as Timestamp?;
          Duration? duration;
          if (startTime != null && endTime != null) {
            duration = endTime.toDate().difference(startTime.toDate());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: BilingualText(
                    textKey: 'Job Completed Successfully!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
                _buildSummaryRow('Job Title', job.title),
                _buildSummaryRow('Time Spent', duration != null ? _formatDuration(duration) : 'N/A'),
                _buildSummaryRow('Amount Received', '₹${job.budget}'),
                _buildSummaryRow('Payment Method', data['paymentMethod']?.toString().toUpperCase() ?? 'N/A'),
                
                const SizedBox(height: 48),
                const BilingualText(
                  textKey: 'Rate the Citizen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Center(
                  child: RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleDone,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const BilingualText(textKey: 'DONE'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
