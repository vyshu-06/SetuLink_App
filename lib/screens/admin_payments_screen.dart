import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Payouts')),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch jobs that are completed but maybe not yet 'paid_out'
        // For this schema, we assume completed jobs need payout.
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('jobStatus', isEqualTo: 'completed')
            .orderBy('scheduledTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final jobs = snapshot.data!.docs;
          if (jobs.isEmpty) return const Center(child: Text('No pending payouts'));

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final jobData = jobs[index].data() as Map<String, dynamic>;
              final jobId = jobs[index].id;
              final amount = jobData['budget'] ?? 0.0;
              final isPaidOut = jobData['payoutStatus'] == 'paid';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(jobData['title'] ?? 'Unknown Job'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Job ID: ${jobId.substring(0, 8)}...'),
                      Text('Completed: ${DateFormat('dd MMM yyyy').format((jobData['scheduledTime'] as Timestamp).toDate())}'),
                      Text('Craftizen: ${jobData['assignedTo'] ?? 'N/A'}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      isPaidOut
                          ? const Text('PAID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                          : ElevatedButton(
                              onPressed: () => _processPayout(context, jobId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Payout', style: TextStyle(fontSize: 12)),
                            ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _processPayout(BuildContext context, String jobId) async {
    try {
      // In real app: Trigger Stripe/Razorpay payout API via Cloud Function
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'payoutStatus': 'paid',
        'payoutTimestamp': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout processed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
